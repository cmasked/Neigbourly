"""TrustScore model — computed and cached per user per community."""

import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, ForeignKey, Numeric, Integer, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class TrustScore(Base):
    __tablename__ = "trust_scores"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    community_id: Mapped[str] = mapped_column(String(36), ForeignKey("communities.id", ondelete="CASCADE"), nullable=False, index=True)
    score: Mapped[float] = mapped_column(Numeric(5, 2), default=50.00, nullable=False)
    total_rentals_completed: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    on_time_returns: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    late_returns: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    damage_reports_filed: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    disputes_lost: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    positive_reviews: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    negative_reviews: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    factors: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    last_calculated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="trust_score", lazy="selectin")
