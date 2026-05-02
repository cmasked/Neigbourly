"""Auth request/response schemas."""

from pydantic import BaseModel, EmailStr, Field
from datetime import datetime


class RegisterRequest(BaseModel):
    community_id: str
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    first_name: str = Field(min_length=1, max_length=100)
    last_name: str = Field(min_length=1, max_length=100)
    phone: str | None = Field(None, max_length=20)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    community_id: str


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class UserResponse(BaseModel):
    id: str
    community_id: str
    email: str
    first_name: str
    last_name: str
    phone: str | None = None
    avatar_url: str | None = None
    role: str
    verification_status: str
    created_at: datetime

    class Config:
        from_attributes = True
