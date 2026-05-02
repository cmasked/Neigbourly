"""SecurityDeposit and DepositAuditLog models."""

import uuid
from datetime import datetime
from sqlalchemy import String, Text, DateTime, Enum, ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class DepositStatus(str, enum.Enum):
    HELD = "held"
    PARTIALLY_DEDUCTED = "partially_deducted"
    FULLY_DEDUCTED = "fully_deducted"
    RELEASED = "released"
    REFUNDED = "refunded"


class DepositAction(str, enum.Enum):
    HELD = "held"
    PARTIAL_DEDUCTION = "partial_deduction"
    FULL_DEDUCTION = "full_deduction"
    RELEASED = "released"
    REFUNDED = "refunded"


class SecurityDeposit(Base):
    __tablename__ = "security_deposits"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    transaction_id: Mapped[str] = mapped_column(String(36), ForeignKey("transactions.id"), unique=True, nullable=False)
    community_id: Mapped[str] = mapped_column(String(36), ForeignKey("communities.id"), nullable=False, index=True)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    status: Mapped[DepositStatus] = mapped_column(Enum(DepositStatus, values_callable=lambda obj: [e.value for e in obj]), default=DepositStatus.HELD, nullable=False, index=True)
    deduction_amount: Mapped[float] = mapped_column(Numeric(10, 2), default=0.00, nullable=False)
    deduction_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    released_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    transaction = relationship("Transaction", back_populates="security_deposit", lazy="selectin")
    audit_logs = relationship("DepositAuditLog", back_populates="deposit", lazy="selectin")


class DepositAuditLog(Base):
    __tablename__ = "deposit_audit_logs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    deposit_id: Mapped[str] = mapped_column(String(36), ForeignKey("security_deposits.id"), nullable=False, index=True)
    action: Mapped[DepositAction] = mapped_column(Enum(DepositAction, values_callable=lambda obj: [e.value for e in obj]), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    performed_by: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    deposit = relationship("SecurityDeposit", back_populates="audit_logs", lazy="selectin")
