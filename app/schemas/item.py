"""Item request/response schemas."""

from pydantic import BaseModel, Field
from datetime import date, datetime


class CreateItemRequest(BaseModel):
    title: str = Field(min_length=3, max_length=255)
    description: str | None = None
    category: str = Field(min_length=1, max_length=100)
    daily_rate: float = Field(gt=0)
    weekly_rate: float | None = Field(None, gt=0)
    deposit_required: float = Field(default=0.0, ge=0)
    condition_description: str | None = None
    image_urls: list[str] | None = None


class UpdateItemRequest(BaseModel):
    title: str | None = Field(None, min_length=3, max_length=255)
    description: str | None = None
    category: str | None = Field(None, min_length=1, max_length=100)
    daily_rate: float | None = Field(None, gt=0)
    weekly_rate: float | None = Field(None, gt=0)
    deposit_required: float | None = Field(None, ge=0)
    condition_description: str | None = None
    image_urls: list[str] | None = None
    status: str | None = None


class SetAvailabilityRequest(BaseModel):
    start_date: date
    end_date: date
    is_blocked: bool = False
    reason: str | None = None


class ItemResponse(BaseModel):
    id: str
    owner_id: str
    community_id: str
    title: str
    description: str | None = None
    category: str
    daily_rate: float
    weekly_rate: float | None = None
    deposit_required: float
    condition_description: str | None = None
    image_urls: list[str] | None = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class ItemSearchRequest(BaseModel):
    query: str | None = None
    category: str | None = None
    min_price: float | None = None
    max_price: float | None = None
    available_from: date | None = None
    available_to: date | None = None
    min_trust_score: float | None = None
    cursor: str | None = None
    limit: int = Field(default=20, ge=1, le=100)
