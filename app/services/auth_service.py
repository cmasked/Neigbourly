"""
Auth service — registration, login, token management.
All business logic lives here, NOT in controllers.
"""

import uuid
from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.user import User, UserRole, VerificationStatus
from app.models.trust_score import TrustScore
from app.models.community import Community
from app.repositories.user_repo import UserRepository
from app.utils.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.utils.exceptions import (
    DuplicateError, UnauthorizedError, NotFoundError, BadRequestError
)
from app.config import get_settings

settings = get_settings()


class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def register(
        self,
        community_id: str,
        email: str,
        password: str,
        first_name: str,
        last_name: str,
        phone: str | None = None,
    ) -> User:
        """Register a new user in a community."""
        # Verify community exists
        result = await self.db.execute(
            select(Community).where(Community.id == community_id, Community.is_active == True)
        )
        community = result.scalar_one_or_none()
        if not community:
            raise NotFoundError("Community", community_id)

        # Check for duplicate email within community
        repo = UserRepository(self.db, community_id)
        existing = await repo.get_by_email(email)
        if existing:
            raise DuplicateError("An account with this email already exists in this community")

        # Create user
        user = User(
            id=str(uuid.uuid4()),
            community_id=community_id,
            email=email,
            password_hash=hash_password(password),
            first_name=first_name,
            last_name=last_name,
            phone=phone,
            role=UserRole.USER,
            verification_status=VerificationStatus.UNVERIFIED,
        )
        self.db.add(user)
        await self.db.flush()

        # Initialize trust score
        trust_score = TrustScore(
            id=str(uuid.uuid4()),
            user_id=user.id,
            community_id=community_id,
            score=settings.TRUST_SCORE_INITIAL,
            last_calculated_at=datetime.utcnow(),
        )
        self.db.add(trust_score)
        await self.db.flush()
        await self.db.refresh(user)

        return user

    async def login(self, email: str, password: str, community_id: str) -> dict:
        """Authenticate user and return tokens."""
        repo = UserRepository(self.db, community_id)
        user = await repo.get_by_email(email)

        if not user or not verify_password(password, user.password_hash):
            raise UnauthorizedError("Invalid email or password")

        if not user.is_active:
            raise UnauthorizedError("Account is deactivated")

        if user.verification_status == VerificationStatus.BANNED:
            raise UnauthorizedError("Account has been banned")

        if user.verification_status == VerificationStatus.SUSPENDED:
            raise UnauthorizedError("Account is suspended")

        # Generate tokens
        access_token = create_access_token(user.id, user.community_id, user.role.value)
        refresh_token = create_refresh_token(user.id)

        # Store refresh token hash
        user.refresh_token_hash = hash_password(refresh_token)
        user.last_login_at = datetime.utcnow()
        await self.db.flush()

        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        }

    async def refresh_tokens(self, refresh_token: str) -> dict:
        """Rotate refresh token and issue new access token."""
        try:
            payload = decode_token(refresh_token)
            if payload.get("type") != "refresh":
                raise UnauthorizedError("Invalid token type")
        except Exception:
            raise UnauthorizedError("Invalid refresh token")

        user_id = payload["sub"]
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()

        if not user or not user.is_active:
            raise UnauthorizedError("User not found")

        if not user.refresh_token_hash or not verify_password(refresh_token, user.refresh_token_hash):
            raise UnauthorizedError("Refresh token revoked")

        # Rotate tokens
        new_access = create_access_token(user.id, user.community_id, user.role.value)
        new_refresh = create_refresh_token(user.id)
        user.refresh_token_hash = hash_password(new_refresh)
        await self.db.flush()

        return {
            "access_token": new_access,
            "refresh_token": new_refresh,
            "token_type": "bearer",
            "expires_in": settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        }

    async def logout(self, user_id: str) -> None:
        """Invalidate refresh token."""
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if user:
            user.refresh_token_hash = None
            await self.db.flush()

    async def get_user(self, user_id: str, community_id: str) -> User:
        """Get user by ID, community-scoped."""
        repo = UserRepository(self.db, community_id)
        user = await repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("User", user_id)
        return user
