"""Item repository with availability checking and full-text search."""

from datetime import date
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text, and_, or_, not_
from app.models.item import Item, ItemAvailability
from app.repositories.base import BaseRepository


class ItemRepository(BaseRepository[Item]):
    def __init__(self, db: AsyncSession, community_id: str):
        super().__init__(Item, db, community_id)

    async def get_by_owner(self, owner_id: str) -> list[Item]:
        """Get all items owned by a user in this community."""
        result = await self.db.execute(
            self._scoped_query().where(Item.owner_id == owner_id, Item.is_active == True)
        )
        return list(result.scalars().all())

    async def search_fulltext(
        self,
        query: str | None = None,
        category: str | None = None,
        min_price: float | None = None,
        max_price: float | None = None,
        limit: int = 20,
        cursor_id: str | None = None,
    ) -> list[Item]:
        """Full-text search with filters, community-scoped."""
        stmt = self._scoped_query().where(Item.is_active == True, Item.status == "active")

        if query:
            # MySQL FULLTEXT search using MATCH AGAINST
            stmt = stmt.where(
                text("MATCH(title, description) AGAINST(:query IN BOOLEAN MODE)")
            ).params(query=query)

        if category:
            stmt = stmt.where(Item.category == category)
        if min_price is not None:
            stmt = stmt.where(Item.daily_rate >= min_price)
        if max_price is not None:
            stmt = stmt.where(Item.daily_rate <= max_price)

        stmt = stmt.order_by(Item.created_at.desc()).limit(limit + 1)

        if cursor_id:
            cursor_item = await self.get_by_id(cursor_id)
            if cursor_item:
                stmt = stmt.where(Item.created_at < cursor_item.created_at)

        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def check_availability(self, item_id: str, start: date, end: date) -> bool:
        """
        Check if item is available for the given date range.
        Uses SELECT FOR UPDATE to prevent double booking.
        Returns True if available, False if blocked/booked.
        """
        # Check for overlapping blocked periods
        result = await self.db.execute(
            select(ItemAvailability)
            .where(
                ItemAvailability.item_id == item_id,
                ItemAvailability.is_blocked == True,
                ItemAvailability.start_date <= end,
                ItemAvailability.end_date >= start,
            )
            .with_for_update()
        )
        blocked = result.scalars().first()
        return blocked is None

    async def add_availability(self, availability: ItemAvailability) -> ItemAvailability:
        """Add an availability/blocked period."""
        self.db.add(availability)
        await self.db.flush()
        await self.db.refresh(availability)
        return availability

    async def block_dates(self, item_id: str, start: date, end: date, reason: str = "booked") -> ItemAvailability:
        """Block dates for an item (e.g., when rented)."""
        import uuid
        block = ItemAvailability(
            id=str(uuid.uuid4()),
            item_id=item_id,
            start_date=start,
            end_date=end,
            is_blocked=True,
            reason=reason,
        )
        self.db.add(block)
        await self.db.flush()
        return block
