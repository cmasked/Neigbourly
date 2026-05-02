"""Dispute schemas."""

from pydantic import BaseModel
from datetime import datetime


class CreateDisputeRequest(BaseModel):
    transaction_id: str
    damage_report_id: str | None = None
    reason: str
    evidence_urls: list[str] | None = None


class ResolveDisputeRequest(BaseModel):
    verdict: str
    action: str | None = None  # e.g. "refund_deposit", "deduct_deposit"


class DisputeResponse(BaseModel):
    id: str
    transaction_id: str
    damage_report_id: str | None = None
    community_id: str
    filed_by: str
    status: str
    reason: str
    evidence_urls: list[str] | None = None
    verdict: str | None = None
    verdict_by: str | None = None
    resolved_at: datetime | None = None
    created_at: datetime

    class Config:
        from_attributes = True
