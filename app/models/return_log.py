"""ReturnLog model."""

import uuid
from datetime import datetime
from sqlalchemy import String, Text, Boolean, DateTime, Enum, ForeignKey, Integer, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class ItemCondition(str, enum.Enum):
    EXCELLENT = "excellent"
    GOOD = "good"
    FAIR = "fair"
    DAMAGED = "damaged"
    MISSING = "missing"


class ReturnLog(Base):
    __tablename__ = "return_logs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    transaction_id: Mapped[str] = mapped_column(String(36), ForeignKey("transactions.id"), unique=True, nullable=False)
    community_id: Mapped[str] = mapped_column(String(36), ForeignKey("communities.id"), nullable=False, index=True)
    returned_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    item_condition: Mapped[ItemCondition] = mapped_column(Enum(ItemCondition, values_callable=lambda obj: [e.value for e in obj]), default=ItemCondition.GOOD, nullable=False)
    condition_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    photo_urls: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    is_late: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    days_late: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    transaction = relationship("Transaction", back_populates="return_log", lazy="selectin")
    damage_reports = relationship("DamageReport", back_populates="return_log", lazy="selectin")
