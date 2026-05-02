"""Payment repository."""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.payment import Payment
from app.repositories.base import BaseRepository


class PaymentRepository(BaseRepository[Payment]):
    def __init__(self, db: AsyncSession, community_id: str):
        super().__init__(Payment, db, community_id)

    async def get_by_idempotency_key(self, key: str) -> Payment | None:
        """Find payment by idempotency key."""
        result = await self.db.execute(
            self._scoped_query().where(Payment.idempotency_key == key)
        )
        return result.scalar_one_or_none()

    async def get_by_transaction(self, transaction_id: str) -> list[Payment]:
        """Get all payments for a transaction."""
        result = await self.db.execute(
            self._scoped_query().where(Payment.transaction_id == transaction_id)
        )
        return list(result.scalars().all())

    async def get_escrowed_for_release(self) -> list[Payment]:
        """Get payments in escrow that are ready for release (linked to completed transactions)."""
        from app.models.transaction import Transaction
        result = await self.db.execute(
            self._scoped_query()
            .join(Transaction, Payment.transaction_id == Transaction.id)
            .where(
                Payment.escrow_status == "held_in_escrow",
                Transaction.status == "completed",
            )
        )
        return list(result.scalars().all())
