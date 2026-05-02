"""Dispute model with admin verdict system."""

import uuid
from datetime import datetime
from sqlalchemy import String, Text, DateTime, Enum, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class DisputeStatus(str, enum.Enum):
    OPEN = "open"
    UNDER_REVIEW = "under_review"
    RESOLVED = "resolved"
    ESCALATED = "escalated"
    CLOSED = "closed"


class Dispute(Base):
    __tablename__ = "disputes"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    transaction_id: Mapped[str] = mapped_column(String(36), ForeignKey("transactions.id"), nullable=False, index=True)
    damage_report_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("damage_reports.id"), nullable=True)
    community_id: Mapped[str] = mapped_column(String(36), ForeignKey("communities.id"), nullable=False, index=True)
    filed_by: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    status: Mapped[DisputeStatus] = mapped_column(
        Enum(DisputeStatus, values_callable=lambda obj: [e.value for e in obj]), default=DisputeStatus.OPEN, nullable=False, index=True
    )
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    evidence_urls: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    verdict: Mapped[str | None] = mapped_column(Text, nullable=True)
    verdict_by: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"), nullable=True)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    transaction = relationship("Transaction", back_populates="disputes", lazy="selectin")
    damage_report = relationship("DamageReport", back_populates="disputes", lazy="selectin")
    filer = relationship("User", foreign_keys=[filed_by], lazy="selectin")
    verdict_admin = relationship("User", foreign_keys=[verdict_by], lazy="selectin")
