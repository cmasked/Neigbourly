"""
Overdue detection background job.
Flags overdue rentals and updates trust scores.
"""

from app.jobs.celery_app import celery_app
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session
from datetime import date, datetime
from app.config import get_settings
from app.models.transaction import Transaction
from app.models.trust_score import TrustScore
from app.models.notification import Notification
import uuid

settings = get_settings()


def _get_sync_session():
    engine = create_engine(settings.DATABASE_URL_SYNC, pool_pre_ping=True)
    return Session(engine)


@celery_app.task(name="app.jobs.overdue_detection_job.detect_overdue_rentals")
def detect_overdue_rentals():
    """Detect overdue rentals, notify users, and penalize trust scores."""
    session = _get_sync_session()
    try:
        overdue = session.execute(
            select(Transaction).where(
                Transaction.status.in_(["active", "item_picked_up"]),
                Transaction.end_date < date.today(),
            )
        ).scalars().all()

        flagged = 0
        for txn in overdue:
            days_late = (date.today() - txn.end_date).days

            # Update borrower's trust score
            ts = session.execute(
                select(TrustScore).where(
                    TrustScore.user_id == txn.borrower_id,
                    TrustScore.community_id == txn.community_id,
                )
            ).scalar_one_or_none()

            if ts and days_late == 1:  # Only penalize once on first day overdue
                ts.late_returns += 1
                ts.last_calculated_at = datetime.utcnow()

            # Create notification for both parties
            for user_id in [txn.owner_id, txn.borrower_id]:
                notif = Notification(
                    id=str(uuid.uuid4()),
                    user_id=user_id,
                    community_id=txn.community_id,
                    type="overdue",
                    title="Overdue Rental",
                    message=f"Rental is {days_late} day(s) overdue. Please initiate return.",
                    data={"transaction_id": txn.id, "days_late": days_late},
                )
                session.add(notif)

            flagged += 1

        session.commit()
        return {"flagged": flagged}
    finally:
        session.close()
