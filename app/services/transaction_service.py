"""
Transaction service — lifecycle management with idempotency.
"""

import uuid
from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transaction import Transaction, TransactionStatus
from app.models.rental_request import RentalRequestStatus
from app.models.return_log import ReturnLog, ItemCondition
from app.repositories.transaction_repo import TransactionRepository
from app.repositories.rental_request_repo import RentalRequestRepository
from app.utils.exceptions import (
    NotFoundError, BadRequestError, InvalidStateTransitionError, ForbiddenError
)
from app.config import get_settings

settings = get_settings()

VALID_TRANSITIONS = {
    TransactionStatus.BOOKING_CONFIRMED: [TransactionStatus.PAYMENT_COLLECTED, TransactionStatus.CANCELLED],
    TransactionStatus.PAYMENT_COLLECTED: [TransactionStatus.ITEM_PICKED_UP, TransactionStatus.CANCELLED],
    TransactionStatus.ITEM_PICKED_UP: [TransactionStatus.ACTIVE],
    TransactionStatus.ACTIVE: [TransactionStatus.RETURN_INITIATED],
    TransactionStatus.RETURN_INITIATED: [TransactionStatus.COMPLETED],
}


class TransactionService:
    def __init__(self, db: AsyncSession, community_id: str):
        self.db = db
        self.community_id = community_id
        self.repo = TransactionRepository(db, community_id)
        self.rr_repo = RentalRequestRepository(db, community_id)

    async def confirm_booking(self, rental_request_id: str, idempotency_key: str) -> Transaction:
        """Create transaction from accepted rental request (idempotent)."""
        # If transaction already exists for this request, return it.
        existing_for_request = await self.repo.get_by_rental_request_id(rental_request_id)
        if existing_for_request:
            return existing_for_request

        # Idempotency check
        existing = await self.repo.get_by_idempotency_key(idempotency_key)
        if existing:
            return existing

        # Validate rental request
        rr = await self.rr_repo.get_by_id(rental_request_id)
        if not rr:
            raise NotFoundError("RentalRequest", rental_request_id)
        if rr.status != RentalRequestStatus.ACCEPTED:
            raise BadRequestError("Rental request must be accepted before confirming booking")

        # Calculate fees
        from app.models.item import Item
        from sqlalchemy import select
        result = await self.db.execute(select(Item).where(Item.id == rr.item_id))
        item = result.scalar_one_or_none()
        if not item:
            raise NotFoundError("Item", rr.item_id)

        # Use counter-proposed terms if available
        start = rr.counter_start_date or rr.start_date
        end = rr.counter_end_date or rr.end_date
        rate = float(rr.counter_daily_rate or rr.proposed_daily_rate)
        days = (end - start).days + 1
        total_fee = round(rate * days, 2)
        commission = round(total_fee * (settings.PLATFORM_COMMISSION_RATE / 100), 2)

        txn = Transaction(
            id=str(uuid.uuid4()),
            rental_request_id=rental_request_id,
            community_id=self.community_id,
            owner_id=item.owner_id,
            borrower_id=rr.borrower_id,
            item_id=rr.item_id,
            status=TransactionStatus.BOOKING_CONFIRMED,
            start_date=start,
            end_date=end,
            daily_rate=rate,
            total_rental_fee=total_fee,
            commission_amount=commission,
            idempotency_key=idempotency_key,
        )
        self.db.add(txn)
        await self.db.flush()
        await self.db.refresh(txn)
        return txn

    async def update_status(self, txn_id: str, new_status: str, user_id: str) -> Transaction:
        """Advance transaction to next status."""
        txn = await self.repo.get_by_id(txn_id)
        if not txn:
            raise NotFoundError("Transaction", txn_id)

        # Verify user is part of this transaction
        if user_id not in (txn.owner_id, txn.borrower_id):
            raise ForbiddenError("You are not part of this transaction")

        target = TransactionStatus(new_status)
        allowed = VALID_TRANSITIONS.get(txn.status, [])
        if target not in allowed:
            raise InvalidStateTransitionError(txn.status.value, new_status)

        txn.status = target
        now = datetime.utcnow()

        if target == TransactionStatus.ITEM_PICKED_UP:
            txn.pickup_at = now
        elif target == TransactionStatus.RETURN_INITIATED:
            txn.return_at = now
        elif target == TransactionStatus.COMPLETED:
            txn.completed_at = now

        await self.db.flush()
        await self.db.refresh(txn)
        return txn

    async def log_return(
        self, txn_id: str, user_id: str,
        condition: str, condition_notes: str | None = None,
        photo_urls: list[str] | None = None,
    ) -> ReturnLog:
        """Log item return with condition assessment."""
        txn = await self.repo.get_by_id(txn_id)
        if not txn:
            raise NotFoundError("Transaction", txn_id)
        if txn.owner_id != user_id:
            raise ForbiddenError("Only the item owner can log returns")

        from datetime import date
        is_late = date.today() > txn.end_date
        days_late = max(0, (date.today() - txn.end_date).days) if is_late else 0

        return_log = ReturnLog(
            id=str(uuid.uuid4()),
            transaction_id=txn_id,
            community_id=self.community_id,
            item_condition=ItemCondition(condition),
            condition_notes=condition_notes,
            photo_urls=photo_urls,
            is_late=is_late,
            days_late=days_late,
        )
        self.db.add(return_log)
        await self.db.flush()
        await self.db.refresh(return_log)
        return return_log

    async def get_transaction(self, txn_id: str) -> Transaction:
        txn = await self.repo.get_by_id(txn_id)
        if not txn:
            raise NotFoundError("Transaction", txn_id)
        return txn

    async def get_my_transactions(self, user_id: str) -> list[Transaction]:
        txns = await self.repo.get_by_user(user_id)

        # Backfill legacy accepted requests that never got a transaction row.
        accepted_as_borrower = await self.rr_repo.get_accepted_by_borrower(user_id)
        accepted_as_owner = await self.rr_repo.get_accepted_for_owner(user_id)

        seen_rr_ids = set()
        for rr in accepted_as_borrower + accepted_as_owner:
            if rr.id in seen_rr_ids:
                continue
            seen_rr_ids.add(rr.id)
            await self.confirm_booking(rr.id, f"backfill:{rr.id}")

        return await self.repo.get_by_user(user_id)
