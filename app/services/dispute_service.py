"""
Dispute service — filing, evidence, admin verdicts.
"""

import uuid
from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.dispute import Dispute, DisputeStatus
from app.models.admin_action import AdminAction
from app.repositories.dispute_repo import DisputeRepository
from app.repositories.transaction_repo import TransactionRepository
from app.utils.exceptions import NotFoundError, ForbiddenError, BadRequestError


class DisputeService:
    def __init__(self, db: AsyncSession, community_id: str):
        self.db = db
        self.community_id = community_id
        self.repo = DisputeRepository(db, community_id)
        self.txn_repo = TransactionRepository(db, community_id)

    async def file_dispute(
        self, filed_by: str, transaction_id: str,
        reason: str, damage_report_id: str | None = None,
        evidence_urls: list[str] | None = None,
    ) -> Dispute:
        """File a new dispute."""
        txn = await self.txn_repo.get_by_id(transaction_id)
        if not txn:
            raise NotFoundError("Transaction", transaction_id)
        if filed_by not in (txn.owner_id, txn.borrower_id):
            raise ForbiddenError("Only parties in the transaction can file a dispute")

        dispute = Dispute(
            id=str(uuid.uuid4()),
            transaction_id=transaction_id,
            damage_report_id=damage_report_id,
            community_id=self.community_id,
            filed_by=filed_by,
            status=DisputeStatus.OPEN,
            reason=reason,
            evidence_urls=evidence_urls,
        )
        created = await self.repo.create(dispute)
        return created

    async def start_review(self, dispute_id: str, admin_id: str) -> Dispute:
        """Admin starts reviewing a dispute."""
        dispute = await self.repo.get_by_id(dispute_id)
        if not dispute:
            raise NotFoundError("Dispute", dispute_id)
        if dispute.status != DisputeStatus.OPEN:
            raise BadRequestError("Dispute is not open")

        dispute.status = DisputeStatus.UNDER_REVIEW
        await self._log_admin_action(admin_id, "start_review", "dispute", dispute_id)
        await self.db.flush()
        await self.db.refresh(dispute)
        return dispute

    async def resolve_dispute(
        self, dispute_id: str, admin_id: str, verdict: str,
    ) -> Dispute:
        """Admin resolves a dispute with a verdict."""
        dispute = await self.repo.get_by_id(dispute_id)
        if not dispute:
            raise NotFoundError("Dispute", dispute_id)
        if dispute.status not in (DisputeStatus.OPEN, DisputeStatus.UNDER_REVIEW, DisputeStatus.ESCALATED):
            raise BadRequestError("Dispute cannot be resolved in current state")

        dispute.status = DisputeStatus.RESOLVED
        dispute.verdict = verdict
        dispute.verdict_by = admin_id
        dispute.resolved_at = datetime.utcnow()

        await self._log_admin_action(admin_id, "resolve_dispute", "dispute", dispute_id, verdict)
        await self.db.flush()
        await self.db.refresh(dispute)
        return dispute

    async def escalate(self, dispute_id: str, admin_id: str) -> Dispute:
        """Escalate dispute to higher authority."""
        dispute = await self.repo.get_by_id(dispute_id)
        if not dispute:
            raise NotFoundError("Dispute", dispute_id)
        dispute.status = DisputeStatus.ESCALATED
        await self._log_admin_action(admin_id, "escalate", "dispute", dispute_id)
        await self.db.flush()
        await self.db.refresh(dispute)
        return dispute

    async def get_open_disputes(self) -> list[Dispute]:
        return await self.repo.get_open_disputes()

    async def _log_admin_action(
        self, admin_id: str, action_type: str,
        target_type: str, target_id: str, reason: str | None = None,
    ):
        action = AdminAction(
            id=str(uuid.uuid4()),
            admin_id=admin_id,
            community_id=self.community_id,
            action_type=action_type,
            target_type=target_type,
            target_id=target_id,
            reason=reason,
        )
        self.db.add(action)
        await self.db.flush()
