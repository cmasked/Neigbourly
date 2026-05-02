"""
Celery app configuration.
"""

from celery import Celery
from celery.schedules import crontab
from app.config import get_settings

settings = get_settings()

celery_app = Celery(
    "neighborly",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=[
        "app.jobs.trust_score_job",
        "app.jobs.payment_settlement_job",
        "app.jobs.overdue_detection_job",
    ],
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
)

# Periodic tasks
celery_app.conf.beat_schedule = {
    "recalculate-trust-scores": {
        "task": "app.jobs.trust_score_job.recalculate_all_scores",
        "schedule": crontab(hour="*/6"),  # Every 6 hours
    },
    "settle-completed-payments": {
        "task": "app.jobs.payment_settlement_job.settle_completed_payments",
        "schedule": crontab(hour="*/1"),  # Every hour
    },
    "detect-overdue-rentals": {
        "task": "app.jobs.overdue_detection_job.detect_overdue_rentals",
        "schedule": crontab(minute="*/30"),  # Every 30 minutes
    },
}
