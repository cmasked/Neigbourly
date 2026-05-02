"""
Review controller.
"""

import uuid
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.schemas.review import CreateReviewRequest, ReviewResponse
from app.models.review import Review
from app.models.transaction import Transaction
from app.services.trust_score_service import TrustScoreService
from app.middleware.auth import get_current_user, get_verified_user, CurrentUser
from app.utils.exceptions import NotFoundError, ForbiddenError, DuplicateError

router = APIRouter(prefix="/reviews", tags=["Reviews"])


@router.post("", response_model=ReviewResponse, status_code=201)
async def create_review(
    body: CreateReviewRequest,
    current_user: CurrentUser = Depends(get_verified_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a review for a completed transaction."""
    # Verify transaction
    result = await db.execute(
        select(Transaction).where(
            Transaction.id == body.transaction_id,
            Transaction.community_id == current_user.community_id,
        )
    )
    txn = result.scalar_one_or_none()
    if not txn:
        raise NotFoundError("Transaction", body.transaction_id)
    if txn.status.value != "completed":
        raise ForbiddenError("Can only review completed transactions")
    if current_user.user_id not in (txn.owner_id, txn.borrower_id):
        raise ForbiddenError("You are not part of this transaction")

    # Check for duplicate review
    dup = await db.execute(
        select(Review).where(
            Review.transaction_id == body.transaction_id,
            Review.reviewer_id == current_user.user_id,
        )
    )
    if dup.scalar_one_or_none():
        raise DuplicateError("You have already reviewed this transaction")

    review = Review(
        id=str(uuid.uuid4()),
        transaction_id=body.transaction_id,
        community_id=current_user.community_id,
        reviewer_id=current_user.user_id,
        reviewee_id=body.reviewee_id,
        rating=body.rating,
        comment=body.comment,
    )
    db.add(review)
    await db.flush()

    # Update trust score
    ts_service = TrustScoreService(db, current_user.community_id)
    event = "positive_review" if body.rating >= 4 else "negative_review" if body.rating <= 2 else None
    if event:
        await ts_service.record_event(body.reviewee_id, event)

    await db.refresh(review)
    return ReviewResponse.model_validate(review)


@router.get("/user/{user_id}", response_model=list[ReviewResponse])
async def get_user_reviews(
    user_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all reviews for a user."""
    result = await db.execute(
        select(Review).where(
            Review.reviewee_id == user_id,
            Review.community_id == current_user.community_id,
        ).order_by(Review.created_at.desc())
    )
    reviews = result.scalars().all()
    return [ReviewResponse.model_validate(r) for r in reviews]
