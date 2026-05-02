"""
Payment settlement background job.
Releases escrow payments for completed transactions.
"""

from app.jobs.celery_app import celery_app
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session
from datetime import datetime
from app.config import get_settings
from app.models.payment import Payment
from app.models.transaction import Transaction
from app.models.community import Community

settings = get_settings()


def _get_sync_session():
    engine = create_engine(settings.DATABASE_URL_SYNC, pool_pre_ping=True)
    return Session(engine)


@celery_app.task(name="app.jobs.payment_settlement_job.settle_completed_payments")
def settle_completed_payments():
    """Release escrowed payments for completed transactions."""
    session = _get_sync_session()
    try:
        # Find payments in escrow where transaction is completed
        payments = session.execute(
            select(Payment)
            .join(Transaction, Payment.transaction_id == Transaction.id)
            .where(
                Payment.escrow_status == "held_in_escrow",
                Transaction.status == "completed",
            )
        ).scalars().all()

        released = 0
        for payment in payments:
            payment.escrow_status = "released"
            payment.released_at = datetime.utcnow()
            released += 1

        session.commit()
        return {"released": released}
    finally:
        session.close()
