"""
Payment controller.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.payment import CreatePaymentRequest, PaymentResponse
from app.services.payment_service import PaymentService
from app.middleware.auth import get_current_user, get_verified_user, CurrentUser

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("", response_model=PaymentResponse, status_code=201)
async def create_payment(
    body: CreatePaymentRequest,
    current_user: CurrentUser = Depends(get_verified_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a payment record (idempotent)."""
    service = PaymentService(db, current_user.community_id)
    payment = await service.create_payment(
        transaction_id=body.transaction_id,
        payment_type=body.payment_type,
        amount=body.amount,
        idempotency_key=body.idempotency_key,
        payer_id=current_user.user_id,
        gateway_provider=body.gateway_provider,
    )
    return PaymentResponse.model_validate(payment)


@router.get("/transaction/{txn_id}", response_model=list[PaymentResponse])
async def get_transaction_payments(
    txn_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all payments for a transaction."""
    service = PaymentService(db, current_user.community_id)
    payments = await service.get_transaction_payments(txn_id)
    return [PaymentResponse.model_validate(p) for p in payments]


@router.patch("/{payment_id}/collect")
async def collect_to_escrow(
    payment_id: str,
    gateway_reference: str,
    current_user: CurrentUser = Depends(get_verified_user),
    db: AsyncSession = Depends(get_db),
):
    """Collect payment and hold in escrow."""
    service = PaymentService(db, current_user.community_id)
    payment = await service.collect_to_escrow(payment_id, gateway_reference)
    return PaymentResponse.model_validate(payment)


@router.patch("/{payment_id}/release")
async def release_escrow(
    payment_id: str,
    current_user: CurrentUser = Depends(get_verified_user),
    db: AsyncSession = Depends(get_db),
):
    """Release payment from escrow."""
    service = PaymentService(db, current_user.community_id)
    payment = await service.release_escrow(payment_id)
    return PaymentResponse.model_validate(payment)
