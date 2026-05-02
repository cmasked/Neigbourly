"""Item and ItemAvailability models."""

import uuid
from datetime import datetime, date
from sqlalchemy import String, Text, Boolean, DateTime, Date, Enum, ForeignKey, Numeric, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class ItemStatus(str, enum.Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    RENTED = "rented"
    REMOVED = "removed"


class Item(Base):
    __tablename__ = "items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    community_id: Mapped[str] = mapped_column(String(36), ForeignKey("communities.id"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    category: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    daily_rate: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    weekly_rate: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    deposit_required: Mapped[float] = mapped_column(Numeric(10, 2), default=0.00, nullable=False)
    condition_description: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_urls: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    status: Mapped[ItemStatus] = mapped_column(Enum(ItemStatus, values_callable=lambda obj: [e.value for e in obj]), default=ItemStatus.ACTIVE, nullable=False, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    owner = relationship("User", back_populates="items", lazy="selectin")
    community = relationship("Community", back_populates="items", lazy="selectin")
    availability = relationship("ItemAvailability", back_populates="item", lazy="selectin")
    rental_requests = relationship("RentalRequest", back_populates="item", lazy="noload")


class ItemAvailability(Base):
    __tablename__ = "item_availability"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    item_id: Mapped[str] = mapped_column(String(36), ForeignKey("items.id", ondelete="CASCADE"), nullable=False, index=True)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    is_blocked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    reason: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    item = relationship("Item", back_populates="availability", lazy="selectin")
