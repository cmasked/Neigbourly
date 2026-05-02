"""
Base repository — enforces neighborhood isolation on every query.
All repositories inherit from this to guarantee WHERE community_id = ? on all operations.
"""

from typing import TypeVar, Generic, Type, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, update, delete
from app.database import Base

T = TypeVar("T", bound=Base)


class BaseRepository(Generic[T]):
    """
    Generic repository with mandatory community_id scoping.
    Every read/write operation is scoped to a single neighborhood community.
    """

    def __init__(self, model: Type[T], db: AsyncSession, community_id: str):
        self.model = model
        self.db = db
        self.community_id = community_id

    def _scoped_query(self):
        """Base query always filtered by community_id."""
        return select(self.model).where(self.model.community_id == self.community_id)

    async def get_by_id(self, entity_id: str) -> T | None:
        """Get entity by ID, scoped to community."""
        result = await self.db.execute(
            self._scoped_query().where(self.model.id == entity_id)
        )
        return result.scalar_one_or_none()

    async def get_all(self, limit: int = 20, offset: int = 0) -> list[T]:
        """Get all entities, scoped to community."""
        result = await self.db.execute(
            self._scoped_query().limit(limit).offset(offset)
        )
        return list(result.scalars().all())

    async def get_by_cursor(self, cursor_id: str | None, limit: int = 20) -> list[T]:
        """Cursor-based pagination scoped to community."""
        query = self._scoped_query().order_by(self.model.created_at.desc())
        if cursor_id:
            # Fetch the cursor entity to get its created_at
            cursor_entity = await self.get_by_id(cursor_id)
            if cursor_entity:
                query = query.where(self.model.created_at < cursor_entity.created_at)
        result = await self.db.execute(query.limit(limit + 1))
        return list(result.scalars().all())

    async def count(self) -> int:
        """Count entities scoped to community."""
        result = await self.db.execute(
            select(func.count(self.model.id)).where(
                self.model.community_id == self.community_id
            )
        )
        return result.scalar() or 0

    async def create(self, entity: T) -> T:
        """Create entity with community_id enforcement."""
        entity.community_id = self.community_id
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def update_fields(self, entity_id: str, **kwargs) -> T | None:
        """Update specific fields on an entity, scoped to community."""
        entity = await self.get_by_id(entity_id)
        if not entity:
            return None
        for key, value in kwargs.items():
            if hasattr(entity, key):
                setattr(entity, key, value)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def soft_delete(self, entity_id: str) -> bool:
        """Soft delete (set is_active = False) scoped to community."""
        entity = await self.get_by_id(entity_id)
        if not entity or not hasattr(entity, "is_active"):
            return False
        entity.is_active = False
        await self.db.flush()
        return True
