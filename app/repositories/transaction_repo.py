"""Transaction repository."""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.transaction import Transaction
from app.repositories.base import BaseRepository


class TransactionRepository(BaseRepository[Transaction]):
    def __init__(self, db: AsyncSession, community_id: str):
        super().__init__(Transaction, db, community_id)

    async def get_by_idempotency_key(self, key: str) -> Transaction | None:
        """Find transaction by idempotency key (community-scoped)."""
        result = await self.db.execute(
            self._scoped_query().where(Transaction.idempotency_key == key)
        )
        return result.scalar_one_or_none()

    async def get_by_rental_request_id(self, rental_request_id: str) -> Transaction | None:
        """Find transaction by rental request id (community-scoped)."""
        result = await self.db.execute(
            self._scoped_query().where(Transaction.rental_request_id == rental_request_id)
        )
        return result.scalar_one_or_none()

    async def get_by_user(self, user_id: str, as_role: str = "both") -> list[Transaction]:
        """Get transactions where user is owner or borrower."""
        query = self._scoped_query()
        if as_role == "owner":
            query = query.where(Transaction.owner_id == user_id)
        elif as_role == "borrower":
            query = query.where(Transaction.borrower_id == user_id)
        else:
            from sqlalchemy import or_
            query = query.where(
                or_(Transaction.owner_id == user_id, Transaction.borrower_id == user_id)
            )
        result = await self.db.execute(query.order_by(Transaction.created_at.desc()))
        return list(result.scalars().all())

    async def get_active_for_item(self, item_id: str) -> list[Transaction]:
        """Get active transactions for an item."""
        result = await self.db.execute(
            self._scoped_query().where(
                Transaction.item_id == item_id,
                Transaction.status.in_(["booking_confirmed", "payment_collected", "item_picked_up", "active"]),
            )
        )
        return list(result.scalars().all())

    async def get_overdue(self) -> list[Transaction]:
        """Get transactions past their end_date that aren't completed."""
        from datetime import date
        result = await self.db.execute(
            self._scoped_query().where(
                Transaction.status.in_(["active", "item_picked_up"]),
                Transaction.end_date < date.today(),
            )
        )
        return list(result.scalars().all())
