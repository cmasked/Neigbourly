"""Rental request repository."""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.rental_request import RentalRequest
from app.models.item import Item
from app.repositories.base import BaseRepository


class RentalRequestRepository(BaseRepository[RentalRequest]):
    def __init__(self, db: AsyncSession, community_id: str):
        super().__init__(RentalRequest, db, community_id)

    async def get_by_borrower(self, borrower_id: str) -> list[RentalRequest]:
        """Get all requests made by a borrower."""
        result = await self.db.execute(
            self._scoped_query().where(RentalRequest.borrower_id == borrower_id)
            .order_by(RentalRequest.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_by_item(self, item_id: str) -> list[RentalRequest]:
        """Get all requests for a specific item."""
        result = await self.db.execute(
            self._scoped_query().where(RentalRequest.item_id == item_id)
            .order_by(RentalRequest.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_for_owner(self, owner_id: str) -> list[RentalRequest]:
        """Get all requests received on items owned by a user in this community."""
        result = await self.db.execute(
            self._scoped_query()
            .join(Item, Item.id == RentalRequest.item_id)
            .where(Item.owner_id == owner_id)
            .order_by(RentalRequest.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_pending_for_item(self, item_id: str) -> list[RentalRequest]:
        """Get pending requests for an item."""
        result = await self.db.execute(
            self._scoped_query().where(
                RentalRequest.item_id == item_id,
                RentalRequest.status == "pending",
            )
        )
        return list(result.scalars().all())

    async def get_expired_requests(self) -> list[RentalRequest]:
        """Get requests that have passed their expiry."""
        from datetime import datetime
        result = await self.db.execute(
            self._scoped_query().where(
                RentalRequest.status == "pending",
                RentalRequest.expires_at < datetime.utcnow(),
            )
        )
        return list(result.scalars().all())

    async def get_accepted_by_borrower(self, borrower_id: str) -> list[RentalRequest]:
        """Get accepted requests made by borrower."""
        result = await self.db.execute(
            self._scoped_query().where(
                RentalRequest.borrower_id == borrower_id,
                RentalRequest.status == "accepted",
            )
            .order_by(RentalRequest.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_accepted_for_owner(self, owner_id: str) -> list[RentalRequest]:
        """Get accepted requests received on items owned by a user."""
        result = await self.db.execute(
            self._scoped_query()
            .join(Item, Item.id == RentalRequest.item_id)
            .where(
                Item.owner_id == owner_id,
                RentalRequest.status == "accepted",
            )
            .order_by(RentalRequest.created_at.desc())
        )
        return list(result.scalars().all())
