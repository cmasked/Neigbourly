"""
Trust score engine — weighted computation from multiple factors.
"""

from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.trust_score import TrustScore
from app.config import get_settings

settings = get_settings()

# Scoring weights
WEIGHTS = {
    "rental_completed": 5,
    "on_time_return": 3,
    "late_return": -10,
    "damage_report": -15,
    "dispute_lost": -20,
    "positive_review": 2,
    "negative_review": -5,
}


class TrustScoreService:
    def __init__(self, db: AsyncSession, community_id: str):
        self.db = db
        self.community_id = community_id

    async def get_score(self, user_id: str) -> TrustScore | None:
        """Get user's trust score in this community."""
        result = await self.db.execute(
            select(TrustScore).where(
                TrustScore.user_id == user_id,
                TrustScore.community_id == self.community_id,
            )
        )
        return result.scalar_one_or_none()

    async def recalculate(self, user_id: str) -> TrustScore:
        """Recalculate trust score from all factors."""
        ts = await self.get_score(user_id)
        if not ts:
            return None

        raw = (
            settings.TRUST_SCORE_INITIAL
            + (ts.total_rentals_completed * WEIGHTS["rental_completed"])
            + (ts.on_time_returns * WEIGHTS["on_time_return"])
            + (ts.late_returns * WEIGHTS["late_return"])
            + (ts.damage_reports_filed * WEIGHTS["damage_report"])
            + (ts.disputes_lost * WEIGHTS["dispute_lost"])
            + (ts.positive_reviews * WEIGHTS["positive_review"])
            + (ts.negative_reviews * WEIGHTS["negative_review"])
        )
        ts.score = max(settings.TRUST_SCORE_MIN, min(settings.TRUST_SCORE_MAX, raw))
        ts.factors = {
            "base": settings.TRUST_SCORE_INITIAL,
            "rentals": ts.total_rentals_completed,
            "on_time": ts.on_time_returns,
            "late": ts.late_returns,
            "damages": ts.damage_reports_filed,
            "disputes_lost": ts.disputes_lost,
            "positive_reviews": ts.positive_reviews,
            "negative_reviews": ts.negative_reviews,
        }
        ts.last_calculated_at = datetime.utcnow()
        await self.db.flush()
        await self.db.refresh(ts)
        return ts

    async def record_event(self, user_id: str, event: str) -> TrustScore:
        """Record a trust-affecting event and recalculate."""
        ts = await self.get_score(user_id)
        if not ts:
            return None

        field_map = {
            "rental_completed": "total_rentals_completed",
            "on_time_return": "on_time_returns",
            "late_return": "late_returns",
            "damage_report": "damage_reports_filed",
            "dispute_lost": "disputes_lost",
            "positive_review": "positive_reviews",
            "negative_review": "negative_reviews",
        }
        field = field_map.get(event)
        if field:
            setattr(ts, field, getattr(ts, field) + 1)
            await self.db.flush()

        return await self.recalculate(user_id)
