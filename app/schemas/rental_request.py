"""Rental request schemas."""

from pydantic import BaseModel, Field
from datetime import date, datetime


class CreateRentalRequestSchema(BaseModel):
    item_id: str
    start_date: date
    end_date: date
    proposed_daily_rate: float = Field(gt=0)
    message: str | None = None


class CounterProposalSchema(BaseModel):
    counter_start_date: date
    counter_end_date: date
    counter_daily_rate: float = Field(gt=0)
    counter_message: str | None = None


class RentalRequestResponse(BaseModel):
    id: str
    item_id: str
    borrower_id: str
    community_id: str
    status: str
    start_date: date
    end_date: date
    proposed_daily_rate: float
    message: str | None = None
    counter_start_date: date | None = None
    counter_end_date: date | None = None
    counter_daily_rate: float | None = None
    counter_message: str | None = None
    expires_at: datetime | None = None
    created_at: datetime

    class Config:
        from_attributes = True
