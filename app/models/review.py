"""Review model — one review per transaction per reviewer."""

import uuid
from datetime import datetime
from sqlalchemy import String, Text, DateTime, ForeignKey, SmallInteger
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class Review(Base):
    __tablename__ = "reviews"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    transaction_id: Mapped[str] = mapped_column(String(36), ForeignKey("transactions.id"), nullable=False)
    community_id: Mapped[str] = mapped_column(String(36), ForeignKey("communities.id"), nullable=False, index=True)
    reviewer_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    reviewee_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    rating: Mapped[int] = mapped_column(SmallInteger, nullable=False)  # 1-5
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    transaction = relationship("Transaction", back_populates="reviews", lazy="selectin")
    reviewer = relationship("User", foreign_keys=[reviewer_id], lazy="selectin")
    reviewee = relationship("User", foreign_keys=[reviewee_id], lazy="selectin")
