"""DamageReport model."""

import uuid
from datetime import datetime
from sqlalchemy import String, Text, DateTime, Enum, ForeignKey, Numeric, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class DamageReportStatus(str, enum.Enum):
    REPORTED = "reported"
    UNDER_REVIEW = "under_review"
    CONFIRMED = "confirmed"
    DISMISSED = "dismissed"


class DamageReport(Base):
    __tablename__ = "damage_reports"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    return_log_id: Mapped[str] = mapped_column(String(36), ForeignKey("return_logs.id"), nullable=False, index=True)
    community_id: Mapped[str] = mapped_column(String(36), ForeignKey("communities.id"), nullable=False, index=True)
    reporter_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    evidence_urls: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    estimated_cost: Mapped[float] = mapped_column(Numeric(10, 2), default=0.00, nullable=False)
    status: Mapped[DamageReportStatus] = mapped_column(
        Enum(DamageReportStatus, values_callable=lambda obj: [e.value for e in obj]), default=DamageReportStatus.REPORTED, nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    return_log = relationship("ReturnLog", back_populates="damage_reports", lazy="selectin")
    reporter = relationship("User", lazy="selectin")
    disputes = relationship("Dispute", back_populates="damage_report", lazy="noload")
