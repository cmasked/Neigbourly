"""Payment schemas."""

from pydantic import BaseModel
from datetime import datetime


class CreatePaymentRequest(BaseModel):
    transaction_id: str
    payment_type: str  # rental_fee | security_deposit | commission
    amount: float
    idempotency_key: str
    gateway_provider: str | None = None


class PaymentResponse(BaseModel):
    id: str
    transaction_id: str
    payment_type: str
    amount: float
    escrow_status: str
    gateway_reference: str | None = None
    gateway_provider: str | None = None
    paid_at: datetime | None = None
    released_at: datetime | None = None
    created_at: datetime

    class Config:
        from_attributes = True
