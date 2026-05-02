"""User repository."""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User
from app.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    def __init__(self, db: AsyncSession, community_id: str):
        super().__init__(User, db, community_id)

    async def get_by_email(self, email: str) -> User | None:
        """Find user by email within this community."""
        result = await self.db.execute(
            self._scoped_query().where(User.email == email)
        )
        return result.scalar_one_or_none()

    async def get_by_id_any_community(self, user_id: str) -> User | None:
        """Get user by ID without community scoping (for auth only)."""
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def update_refresh_token(self, user_id: str, token_hash: str | None) -> None:
        """Update the stored refresh token hash."""
        await self.update_fields(user_id, refresh_token_hash=token_hash)

    async def update_verification_status(self, user_id: str, status: str) -> User | None:
        """Update user verification status."""
        return await self.update_fields(user_id, verification_status=status)
