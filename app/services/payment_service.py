"""
Payment service — escrow, idempotent creation, financial separation.
"""

import uuid
from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.payment import Payment, PaymentType, EscrowStatus
from app.models.security_deposit import SecurityDeposit, DepositAuditLog, DepositStatus, DepositAction
from app.repositories.payment_repo import PaymentRepository
from app.repositories.transaction_repo import TransactionRepository
from app.utils.exceptions import NotFoundError, BadRequestError, PaymentError


class PaymentService:
    def __init__(self, db: AsyncSession, community_id: str):
        self.db = db
        self.community_id = community_id
        self.repo = PaymentRepository(db, community_id)
        self.txn_repo = TransactionRepository(db, community_id)

    async def create_payment(
        self, transaction_id: str, payment_type: str,
        amount: float, idempotency_key: str, payer_id: str,
        gateway_provider: str | None = None,
    ) -> Payment:
        """Create a payment record (idempotent)."""
        # Idempotency check
        existing = await self.repo.get_by_idempotency_key(idempotency_key)
        if existing:
            return existing

        # Verify transaction exists
        txn = await self.txn_repo.get_by_id(transaction_id)
        if not txn:
            raise NotFoundError("Transaction", transaction_id)

        payment = Payment(
            id=str(uuid.uuid4()),
            transaction_id=transaction_id,
            community_id=self.community_id,
            payer_id=payer_id,
            payment_type=PaymentType(payment_type),
            amount=amount,
            escrow_status=EscrowStatus.PENDING,
            idempotency_key=idempotency_key,
            gateway_provider=gateway_provider,
        )
        self.db.add(payment)
        await self.db.flush()
        await self.db.refresh(payment)
        return payment

    async def collect_to_escrow(self, payment_id: str, gateway_reference: str) -> Payment:
        """Mark payment as collected and held in escrow."""
        payment = await self.repo.get_by_id(payment_id)
        if not payment:
            raise NotFoundError("Payment", payment_id)
        if payment.escrow_status != EscrowStatus.PENDING:
            raise BadRequestError(f"Payment is already {payment.escrow_status.value}")

        payment.escrow_status = EscrowStatus.HELD_IN_ESCROW
        payment.gateway_reference = gateway_reference
        payment.paid_at = datetime.utcnow()
        await self.db.flush()
        await self.db.refresh(payment)
        return payment

    async def release_escrow(self, payment_id: str) -> Payment:
        """Release payment from escrow to the owner."""
        payment = await self.repo.get_by_id(payment_id)
        if not payment:
            raise NotFoundError("Payment", payment_id)
        if payment.escrow_status != EscrowStatus.HELD_IN_ESCROW:
            raise BadRequestError("Payment not in escrow")

        payment.escrow_status = EscrowStatus.RELEASED
        payment.released_at = datetime.utcnow()
        await self.db.flush()
        await self.db.refresh(payment)
        return payment

    async def refund_payment(self, payment_id: str) -> Payment:
        """Refund a payment."""
        payment = await self.repo.get_by_id(payment_id)
        if not payment:
            raise NotFoundError("Payment", payment_id)
        if payment.escrow_status not in (EscrowStatus.PENDING, EscrowStatus.HELD_IN_ESCROW):
            raise BadRequestError("Cannot refund a released payment")

        payment.escrow_status = EscrowStatus.REFUNDED
        payment.refunded_at = datetime.utcnow()
        await self.db.flush()
        await self.db.refresh(payment)
        return payment

    async def get_transaction_payments(self, transaction_id: str) -> list[Payment]:
        return await self.repo.get_by_transaction(transaction_id)


class DepositService:
    """Handles security deposit hold, release, and deduction with audit trail."""

    def __init__(self, db: AsyncSession, community_id: str):
        self.db = db
        self.community_id = community_id

    async def hold_deposit(self, transaction_id: str, amount: float, performed_by: str) -> SecurityDeposit:
        """Hold a security deposit for a transaction."""
        deposit = SecurityDeposit(
            id=str(uuid.uuid4()),
            transaction_id=transaction_id,
            community_id=self.community_id,
            amount=amount,
            status=DepositStatus.HELD,
        )
        self.db.add(deposit)
        await self.db.flush()

        # Audit log
        log = DepositAuditLog(
            id=str(uuid.uuid4()),
            deposit_id=deposit.id,
            action=DepositAction.HELD,
            amount=amount,
            reason="Deposit held on booking",
            performed_by=performed_by,
        )
        self.db.add(log)
        await self.db.flush()
        await self.db.refresh(deposit)
        return deposit

    async def release_deposit(self, deposit_id: str, performed_by: str) -> SecurityDeposit:
        """Release full deposit back to borrower."""
        from sqlalchemy import select
        result = await self.db.execute(
            select(SecurityDeposit).where(
                SecurityDeposit.id == deposit_id,
                SecurityDeposit.community_id == self.community_id,
            )
        )
        deposit = result.scalar_one_or_none()
        if not deposit:
            raise NotFoundError("SecurityDeposit", deposit_id)

        deposit.status = DepositStatus.RELEASED
        deposit.released_at = datetime.utcnow()

        log = DepositAuditLog(
            id=str(uuid.uuid4()),
            deposit_id=deposit.id,
            action=DepositAction.RELEASED,
            amount=float(deposit.amount),
            reason="Deposit released — item returned in good condition",
            performed_by=performed_by,
        )
        self.db.add(log)
        await self.db.flush()
        await self.db.refresh(deposit)
        return deposit

    async def deduct_from_deposit(
        self, deposit_id: str, deduction_amount: float,
        reason: str, performed_by: str,
    ) -> SecurityDeposit:
        """Partially or fully deduct from deposit."""
        from sqlalchemy import select
        result = await self.db.execute(
            select(SecurityDeposit).where(
                SecurityDeposit.id == deposit_id,
                SecurityDeposit.community_id == self.community_id,
            )
        )
        deposit = result.scalar_one_or_none()
        if not deposit:
            raise NotFoundError("SecurityDeposit", deposit_id)

        if deduction_amount > float(deposit.amount):
            raise BadRequestError("Deduction exceeds deposit amount")

        deposit.deduction_amount = deduction_amount
        deposit.deduction_reason = reason
        is_full = deduction_amount >= float(deposit.amount)
        deposit.status = DepositStatus.FULLY_DEDUCTED if is_full else DepositStatus.PARTIALLY_DEDUCTED
        action = DepositAction.FULL_DEDUCTION if is_full else DepositAction.PARTIAL_DEDUCTION

        log = DepositAuditLog(
            id=str(uuid.uuid4()),
            deposit_id=deposit.id,
            action=action,
            amount=deduction_amount,
            reason=reason,
            performed_by=performed_by,
        )
        self.db.add(log)
        await self.db.flush()
        await self.db.refresh(deposit)
        return deposit
