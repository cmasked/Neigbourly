"""Review schemas."""

from pydantic import BaseModel, Field
from datetime import datetime


class CreateReviewRequest(BaseModel):
    transaction_id: str
    reviewee_id: str
    rating: int = Field(ge=1, le=5)
    comment: str | None = None


class ReviewResponse(BaseModel):
    id: str
    transaction_id: str
    reviewer_id: str
    reviewee_id: str
    rating: int
    comment: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True
