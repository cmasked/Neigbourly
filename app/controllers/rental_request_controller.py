"""
Rental request controller.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.rental_request import (
    CreateRentalRequestSchema, CounterProposalSchema, RentalRequestResponse,
)
from app.services.rental_request_service import RentalRequestService
from app.middleware.auth import get_current_user, get_verified_user, CurrentUser

router = APIRouter(prefix="/rental-requests", tags=["Rental Requests"])


@router.post("", response_model=RentalRequestResponse, status_code=201)
async def create_request(
    body: CreateRentalRequestSchema,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a rental request."""
    service = RentalRequestService(db, current_user.community_id)
    rr = await service.create_request(
        borrower_id=current_user.user_id,
        item_id=body.item_id,
        start_date=body.start_date,
        end_date=body.end_date,
        proposed_daily_rate=body.proposed_daily_rate,
        message=body.message,
    )
    return RentalRequestResponse.model_validate(rr)


@router.get("", response_model=list[RentalRequestResponse])
async def get_my_requests(
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get my rental requests (as borrower)."""
    service = RentalRequestService(db, current_user.community_id)
    requests = await service.get_my_requests(current_user.user_id)
    return [RentalRequestResponse.model_validate(r) for r in requests]


@router.get("/incoming", response_model=list[RentalRequestResponse])
async def get_incoming_requests(
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get rental requests received on items owned by the current user."""
    service = RentalRequestService(db, current_user.community_id)
    requests = await service.get_incoming_requests(current_user.user_id)
    return [RentalRequestResponse.model_validate(r) for r in requests]


@router.patch("/{request_id}/accept", response_model=RentalRequestResponse)
async def accept_request(
    request_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Accept a rental request (item owner only)."""
    service = RentalRequestService(db, current_user.community_id)
    rr = await service.accept_request(request_id, current_user.user_id)
    return RentalRequestResponse.model_validate(rr)


@router.patch("/{request_id}/reject", response_model=RentalRequestResponse)
async def reject_request(
    request_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Reject a rental request (item owner only)."""
    service = RentalRequestService(db, current_user.community_id)
    rr = await service.reject_request(request_id, current_user.user_id)
    return RentalRequestResponse.model_validate(rr)


@router.patch("/{request_id}/counter", response_model=RentalRequestResponse)
async def counter_propose(
    request_id: str,
    body: CounterProposalSchema,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Counter-propose a rental request (item owner only)."""
    service = RentalRequestService(db, current_user.community_id)
    rr = await service.counter_propose(
        request_id, current_user.user_id,
        body.counter_start_date, body.counter_end_date,
        body.counter_daily_rate, body.counter_message,
    )
    return RentalRequestResponse.model_validate(rr)


@router.patch("/{request_id}/cancel", response_model=RentalRequestResponse)
async def cancel_request(
    request_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cancel a rental request (borrower only)."""
    service = RentalRequestService(db, current_user.community_id)
    rr = await service.cancel_request(request_id, current_user.user_id)
    return RentalRequestResponse.model_validate(rr)
