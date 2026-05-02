"""
Item service — CRUD, availability, search.
"""

import uuid
from datetime import date

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.item import Item, ItemAvailability, ItemStatus
from app.repositories.item_repo import ItemRepository
from app.utils.exceptions import NotFoundError, ForbiddenError, BadRequestError


class ItemService:
    def __init__(self, db: AsyncSession, community_id: str):
        self.db = db
        self.community_id = community_id
        self.repo = ItemRepository(db, community_id)

    async def create_item(
        self, owner_id: str, title: str, description: str | None,
        category: str, daily_rate: float, weekly_rate: float | None,
        deposit_required: float, condition_description: str | None,
        image_urls: list[str] | None,
    ) -> Item:
        """Create a new item listing."""
        item = Item(
            id=str(uuid.uuid4()),
            owner_id=owner_id,
            community_id=self.community_id,
            title=title,
            description=description,
            category=category,
            daily_rate=daily_rate,
            weekly_rate=weekly_rate,
            deposit_required=deposit_required,
            condition_description=condition_description,
            image_urls=image_urls,
            status=ItemStatus.ACTIVE,
        )
        return await self.repo.create(item)

    async def get_item(self, item_id: str) -> Item:
        """Get item by ID."""
        item = await self.repo.get_by_id(item_id)
        if not item:
            raise NotFoundError("Item", item_id)
        return item

    async def list_items(self, cursor: str | None = None, limit: int = 20) -> list[Item]:
        """List items in the community."""
        return await self.repo.get_by_cursor(cursor, limit)

    async def update_item(self, item_id: str, user_id: str, **kwargs) -> Item:
        """Update item (only owner can update)."""
        item = await self.get_item(item_id)
        if item.owner_id != user_id:
            raise ForbiddenError("You can only update your own items")
        updated = await self.repo.update_fields(item_id, **kwargs)
        return updated

    async def delete_item(self, item_id: str, user_id: str) -> bool:
        """Soft-delete item (only owner can delete)."""
        item = await self.get_item(item_id)
        if item.owner_id != user_id:
            raise ForbiddenError("You can only delete your own items")
        return await self.repo.soft_delete(item_id)

    async def search_items(
        self, query: str | None = None, category: str | None = None,
        min_price: float | None = None, max_price: float | None = None,
        cursor: str | None = None, limit: int = 20,
    ) -> dict:
        """Search items with FULLTEXT and filters."""
        items = await self.repo.search_fulltext(
            query=query, category=category,
            min_price=min_price, max_price=max_price,
            limit=limit, cursor_id=cursor,
        )
        has_more = len(items) > limit
        if has_more:
            items = items[:limit]
        next_cursor = items[-1].id if items and has_more else None
        return {"data": items, "has_more": has_more, "next_cursor": next_cursor}

    async def set_availability(
        self, item_id: str, user_id: str,
        start_date: date, end_date: date,
        is_blocked: bool = False, reason: str | None = None,
    ) -> ItemAvailability:
        """Set availability window for an item."""
        item = await self.get_item(item_id)
        if item.owner_id != user_id:
            raise ForbiddenError("You can only manage availability for your own items")
        if end_date < start_date:
            raise BadRequestError("end_date must be >= start_date")

        avail = ItemAvailability(
            id=str(uuid.uuid4()),
            item_id=item_id,
            start_date=start_date,
            end_date=end_date,
            is_blocked=is_blocked,
            reason=reason,
        )
        return await self.repo.add_availability(avail)

    async def check_availability(self, item_id: str, start: date, end: date) -> bool:
        """Check if item is available for dates."""
        return await self.repo.check_availability(item_id, start, end)
