"""
Trust score recalculation background job.
"""

from app.jobs.celery_app import celery_app
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session
from app.config import get_settings
from app.models.trust_score import TrustScore
from app.models.community import Community

settings = get_settings()


def _get_sync_session():
    engine = create_engine(settings.DATABASE_URL_SYNC, pool_pre_ping=True)
    return Session(engine)


@celery_app.task(name="app.jobs.trust_score_job.recalculate_all_scores")
def recalculate_all_scores():
    """Recalculate all trust scores across all communities."""
    session = _get_sync_session()
    try:
        communities = session.execute(select(Community.id)).scalars().all()
        updated = 0

        for community_id in communities:
            scores = session.execute(
                select(TrustScore).where(TrustScore.community_id == community_id)
            ).scalars().all()

            for ts in scores:
                from datetime import datetime
                raw = (
                    settings.TRUST_SCORE_INITIAL
                    + (ts.total_rentals_completed * 5)
                    + (ts.on_time_returns * 3)
                    + (ts.late_returns * -10)
                    + (ts.damage_reports_filed * -15)
                    + (ts.disputes_lost * -20)
                    + (ts.positive_reviews * 2)
                    + (ts.negative_reviews * -5)
                )
                ts.score = max(0, min(100, raw))
                ts.last_calculated_at = datetime.utcnow()
                updated += 1

        session.commit()
        return {"updated": updated}
    finally:
        session.close()


@celery_app.task(name="app.jobs.trust_score_job.recalculate_user_score")
def recalculate_user_score(user_id: str, community_id: str):
    """Recalculate a single user's trust score."""
    session = _get_sync_session()
    try:
        ts = session.execute(
            select(TrustScore).where(
                TrustScore.user_id == user_id,
                TrustScore.community_id == community_id,
            )
        ).scalar_one_or_none()

        if ts:
            from datetime import datetime
            raw = (
                settings.TRUST_SCORE_INITIAL
                + (ts.total_rentals_completed * 5)
                + (ts.on_time_returns * 3)
                + (ts.late_returns * -10)
                + (ts.damage_reports_filed * -15)
                + (ts.disputes_lost * -20)
                + (ts.positive_reviews * 2)
                + (ts.negative_reviews * -5)
            )
            ts.score = max(0, min(100, raw))
            ts.last_calculated_at = datetime.utcnow()
            session.commit()
            return {"user_id": user_id, "score": float(ts.score)}
        return {"error": "score not found"}
    finally:
        session.close()
