"""Payment model with escrow states and idempotency."""

import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, Enum, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class PaymentType(str, enum.Enum):
    RENTAL_FEE = "rental_fee"
    SECURITY_DEPOSIT = "security_deposit"
    COMMISSION = "commission"
    REFUND = "refund"


class EscrowStatus(str, enum.Enum):
    PENDING = "pending"
    HELD_IN_ESCROW = "held_in_escrow"
    RELEASED = "released"
    REFUNDED = "refunded"


class Payment(Base):
    __tablename__ = "payments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    transaction_id: Mapped[str] = mapped_column(String(36), ForeignKey("transactions.id"), nullable=False, index=True)
    community_id: Mapped[str] = mapped_column(String(36), ForeignKey("communities.id"), nullable=False, index=True)
    payer_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    payment_type: Mapped[PaymentType] = mapped_column(Enum(PaymentType, values_callable=lambda obj: [e.value for e in obj]), nullable=False, index=True)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    escrow_status: Mapped[EscrowStatus] = mapped_column(
        Enum(EscrowStatus, values_callable=lambda obj: [e.value for e in obj]), default=EscrowStatus.PENDING, nullable=False, index=True
    )
    gateway_reference: Mapped[str | None] = mapped_column(String(255), nullable=True)
    gateway_provider: Mapped[str | None] = mapped_column(String(50), nullable=True)
    idempotency_key: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    released_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    refunded_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    transaction = relationship("Transaction", back_populates="payments", lazy="selectin")
