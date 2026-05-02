"""Transaction model with full lifecycle."""

import uuid
from datetime import datetime, date
from sqlalchemy import String, DateTime, Date, Enum, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class TransactionStatus(str, enum.Enum):
    BOOKING_CONFIRMED = "booking_confirmed"
    PAYMENT_COLLECTED = "payment_collected"
    ITEM_PICKED_UP = "item_picked_up"
    ACTIVE = "active"
    RETURN_INITIATED = "return_initiated"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    rental_request_id: Mapped[str] = mapped_column(String(36), ForeignKey("rental_requests.id"), nullable=False)
    community_id: Mapped[str] = mapped_column(String(36), ForeignKey("communities.id"), nullable=False, index=True)
    owner_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    borrower_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    item_id: Mapped[str] = mapped_column(String(36), ForeignKey("items.id"), nullable=False)
    status: Mapped[TransactionStatus] = mapped_column(
        Enum(TransactionStatus, values_callable=lambda obj: [e.value for e in obj]), default=TransactionStatus.BOOKING_CONFIRMED, nullable=False, index=True
    )
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    daily_rate: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    total_rental_fee: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    commission_amount: Mapped[float] = mapped_column(Numeric(10, 2), default=0.00, nullable=False)
    idempotency_key: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    pickup_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    return_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    rental_request = relationship("RentalRequest", back_populates="transaction", lazy="selectin")
    owner = relationship("User", foreign_keys=[owner_id], lazy="selectin")
    borrower = relationship("User", foreign_keys=[borrower_id], lazy="selectin")
    item = relationship("Item", lazy="selectin")
    payments = relationship("Payment", back_populates="transaction", lazy="selectin")
    security_deposit = relationship("SecurityDeposit", back_populates="transaction", uselist=False, lazy="selectin")
    return_log = relationship("ReturnLog", back_populates="transaction", uselist=False, lazy="noload")
    disputes = relationship("Dispute", back_populates="transaction", lazy="noload")
    reviews = relationship("Review", back_populates="transaction", lazy="noload")
