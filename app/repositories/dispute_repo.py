"""Dispute repository."""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.dispute import Dispute
from app.repositories.base import BaseRepository


class DisputeRepository(BaseRepository[Dispute]):
    def __init__(self, db: AsyncSession, community_id: str):
        super().__init__(Dispute, db, community_id)

    async def get_by_transaction(self, transaction_id: str) -> list[Dispute]:
        result = await self.db.execute(
            self._scoped_query().where(Dispute.transaction_id == transaction_id)
        )
        return list(result.scalars().all())

    async def get_open_disputes(self) -> list[Dispute]:
        result = await self.db.execute(
            self._scoped_query().where(Dispute.status.in_(["open", "under_review", "escalated"]))
            .order_by(Dispute.created_at.asc())
        )
        return list(result.scalars().all())
