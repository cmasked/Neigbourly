"""
Auth controller — thin route layer, delegates to AuthService.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.auth import (
    RegisterRequest, LoginRequest, RefreshRequest,
    TokenResponse, UserResponse,
)
from app.schemas.common import MessageResponse
from app.services.auth_service import AuthService
from app.middleware.auth import get_current_user, CurrentUser

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse, status_code=201)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """Register a new user account."""
    service = AuthService(db)
    user = await service.register(
        community_id=body.community_id,
        email=body.email,
        password=body.password,
        first_name=body.first_name,
        last_name=body.last_name,
        phone=body.phone,
    )
    return UserResponse.model_validate(user)


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    """Login and receive JWT tokens."""
    service = AuthService(db)
    tokens = await service.login(body.email, body.password, body.community_id)
    return TokenResponse(**tokens)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    """Refresh access token using refresh token."""
    service = AuthService(db)
    tokens = await service.refresh_tokens(body.refresh_token)
    return TokenResponse(**tokens)


@router.post("/logout", response_model=MessageResponse)
async def logout(
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Logout and invalidate refresh token."""
    service = AuthService(db)
    await service.logout(current_user.user_id)
    return MessageResponse(message="Logged out successfully")


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current authenticated user."""
    service = AuthService(db)
    user = await service.get_user(current_user.user_id, current_user.community_id)
    return UserResponse.model_validate(user)
