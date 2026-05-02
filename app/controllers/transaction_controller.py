"""
Transaction controller.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.transaction import (
    ConfirmTransactionRequest, UpdateTransactionStatusRequest, TransactionResponse,
)
from app.services.transaction_service import TransactionService
from app.middleware.auth import get_current_user, get_verified_user, CurrentUser

router = APIRouter(prefix="/transactions", tags=["Transactions"])


@router.post("/confirm", response_model=TransactionResponse, status_code=201)
async def confirm_booking(
    body: ConfirmTransactionRequest,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a transaction from an accepted rental request (idempotent)."""
    service = TransactionService(db, current_user.community_id)
    txn = await service.confirm_booking(body.rental_request_id, body.idempotency_key)
    return TransactionResponse.model_validate(txn)


@router.get("", response_model=list[TransactionResponse])
async def get_my_transactions(
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all my transactions."""
    service = TransactionService(db, current_user.community_id)
    txns = await service.get_my_transactions(current_user.user_id)
    return [TransactionResponse.model_validate(t) for t in txns]


@router.get("/{txn_id}", response_model=TransactionResponse)
async def get_transaction(
    txn_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get transaction details."""
    service = TransactionService(db, current_user.community_id)
    txn = await service.get_transaction(txn_id)
    return TransactionResponse.model_validate(txn)


@router.patch("/{txn_id}/status", response_model=TransactionResponse)
async def update_status(
    txn_id: str,
    body: UpdateTransactionStatusRequest,
    current_user: CurrentUser = Depends(get_verified_user),
    db: AsyncSession = Depends(get_db),
):
    """Advance transaction to next lifecycle status."""
    service = TransactionService(db, current_user.community_id)
    txn = await service.update_status(txn_id, body.status, current_user.user_id)
    return TransactionResponse.model_validate(txn)
