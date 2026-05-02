"""Transaction schemas."""

from pydantic import BaseModel
from datetime import date, datetime


class ConfirmTransactionRequest(BaseModel):
    rental_request_id: str
    idempotency_key: str


class UpdateTransactionStatusRequest(BaseModel):
    status: str


class TransactionResponse(BaseModel):
    id: str
    rental_request_id: str
    community_id: str
    owner_id: str
    borrower_id: str
    item_id: str
    status: str
    start_date: date
    end_date: date
    daily_rate: float
    total_rental_fee: float
    commission_amount: float
    pickup_at: datetime | None = None
    return_at: datetime | None = None
    completed_at: datetime | None = None
    created_at: datetime

    class Config:
        from_attributes = True
