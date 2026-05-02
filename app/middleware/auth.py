"""
JWT Authentication middleware and dependencies.
Extracts and validates JWT from Authorization header.
"""

from fastapi import Depends, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.utils.security import decode_token
from app.utils.exceptions import UnauthorizedError, ForbiddenError
from app.models.user import User, UserRole
import jwt


security = HTTPBearer()


class CurrentUser:
    """Represents the authenticated user context."""
    def __init__(self, user_id: str, community_id: str, role: str):
        self.user_id = user_id
        self.community_id = community_id
        self.role = role


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> CurrentUser:
    """Extract and validate JWT, return CurrentUser context."""
    try:
        payload = decode_token(credentials.credentials)
        if payload.get("type") != "access":
            raise UnauthorizedError("Invalid token type")
        return CurrentUser(
            user_id=payload["sub"],
            community_id=payload["community_id"],
            role=payload["role"],
        )
    except jwt.ExpiredSignatureError:
        raise UnauthorizedError("Token has expired")
    except jwt.PyJWTError:
        raise UnauthorizedError("Invalid token")


async def get_verified_user(
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CurrentUser:
    """Ensure user exists and is verified."""
    result = await db.execute(
        select(User).where(User.id == current_user.user_id, User.is_active == True)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise UnauthorizedError("User not found or deactivated")
    if user.verification_status.value not in ("verified",):
        raise ForbiddenError(f"Account is {user.verification_status.value}. Verification required.")
    return current_user


def require_role(*roles: str):
    """Dependency factory: restrict access to specific roles."""
    async def _check(current_user: CurrentUser = Depends(get_current_user)):
        if current_user.role not in roles:
            raise ForbiddenError(f"Role '{current_user.role}' not authorized. Required: {roles}")
        return current_user
    return _check


# Convenience dependencies
require_admin = require_role("admin", "super_admin")
require_super_admin = require_role("super_admin")
