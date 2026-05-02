"""RentalRequest model with state machine."""

import uuid
from datetime import datetime, date
from sqlalchemy import String, Text, DateTime, Date, Enum, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class RentalRequestStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    COUNTER_PROPOSED = "counter_proposed"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class RentalRequest(Base):
    __tablename__ = "rental_requests"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    item_id: Mapped[str] = mapped_column(String(36), ForeignKey("items.id"), nullable=False, index=True)
    borrower_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    community_id: Mapped[str] = mapped_column(String(36), ForeignKey("communities.id"), nullable=False, index=True)
    status: Mapped[RentalRequestStatus] = mapped_column(
        Enum(RentalRequestStatus, values_callable=lambda obj: [e.value for e in obj]), default=RentalRequestStatus.PENDING, nullable=False, index=True
    )
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    proposed_daily_rate: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    message: Mapped[str | None] = mapped_column(Text, nullable=True)
    counter_start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    counter_end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    counter_daily_rate: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    counter_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    responded_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    item = relationship("Item", back_populates="rental_requests", lazy="selectin")
    borrower = relationship("User", foreign_keys=[borrower_id], lazy="selectin")
    transaction = relationship("Transaction", back_populates="rental_request", uselist=False, lazy="noload")
