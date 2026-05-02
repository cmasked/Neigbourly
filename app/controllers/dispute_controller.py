"""
Dispute controller.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.dispute import CreateDisputeRequest, ResolveDisputeRequest, DisputeResponse
from app.services.dispute_service import DisputeService
from app.middleware.auth import get_current_user, get_verified_user, require_admin, CurrentUser

router = APIRouter(prefix="/disputes", tags=["Disputes"])


@router.post("", response_model=DisputeResponse, status_code=201)
async def file_dispute(
    body: CreateDisputeRequest,
    current_user: CurrentUser = Depends(get_verified_user),
    db: AsyncSession = Depends(get_db),
):
    """File a new dispute."""
    service = DisputeService(db, current_user.community_id)
    dispute = await service.file_dispute(
        filed_by=current_user.user_id,
        transaction_id=body.transaction_id,
        reason=body.reason,
        damage_report_id=body.damage_report_id,
        evidence_urls=body.evidence_urls,
    )
    return DisputeResponse.model_validate(dispute)


@router.get("", response_model=list[DisputeResponse])
async def get_open_disputes(
    current_user: CurrentUser = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get all open disputes (admin only)."""
    service = DisputeService(db, current_user.community_id)
    disputes = await service.get_open_disputes()
    return [DisputeResponse.model_validate(d) for d in disputes]


@router.patch("/{dispute_id}/review", response_model=DisputeResponse)
async def start_review(
    dispute_id: str,
    current_user: CurrentUser = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Start reviewing a dispute (admin only)."""
    service = DisputeService(db, current_user.community_id)
    dispute = await service.start_review(dispute_id, current_user.user_id)
    return DisputeResponse.model_validate(dispute)


@router.patch("/{dispute_id}/resolve", response_model=DisputeResponse)
async def resolve_dispute(
    dispute_id: str,
    body: ResolveDisputeRequest,
    current_user: CurrentUser = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Resolve a dispute with verdict (admin only)."""
    service = DisputeService(db, current_user.community_id)
    dispute = await service.resolve_dispute(
        dispute_id, current_user.user_id, body.verdict,
    )
    return DisputeResponse.model_validate(dispute)
