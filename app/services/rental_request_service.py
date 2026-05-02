"""
Rental request service — state machine logic.
"""

import uuid
from datetime import datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.rental_request import RentalRequest, RentalRequestStatus
from app.repositories.rental_request_repo import RentalRequestRepository
from app.repositories.item_repo import ItemRepository
from app.services.notification_service import NotificationService
from app.utils.exceptions import (
    NotFoundError, ForbiddenError, BadRequestError,
    DoubleBookingError, InvalidStateTransitionError,
)


VALID_TRANSITIONS = {
    RentalRequestStatus.PENDING: [
        RentalRequestStatus.ACCEPTED,
        RentalRequestStatus.REJECTED,
        RentalRequestStatus.COUNTER_PROPOSED,
        RentalRequestStatus.EXPIRED,
        RentalRequestStatus.CANCELLED,
    ],
    RentalRequestStatus.COUNTER_PROPOSED: [
        RentalRequestStatus.ACCEPTED,
        RentalRequestStatus.REJECTED,
        RentalRequestStatus.CANCELLED,
    ],
}


class RentalRequestService:
    def __init__(self, db: AsyncSession, community_id: str):
        self.db = db
        self.community_id = community_id
        self.repo = RentalRequestRepository(db, community_id)
        self.item_repo = ItemRepository(db, community_id)
        self.notif_service = NotificationService(db, community_id)

    async def create_request(
        self, borrower_id: str, item_id: str,
        start_date, end_date, proposed_daily_rate: float,
        message: str | None = None,
    ) -> RentalRequest:
        """Create a new rental request with availability check."""
        # Verify item exists and is active
        item = await self.item_repo.get_by_id(item_id)
        if not item or not item.is_active:
            raise NotFoundError("Item", item_id)

        if item.owner_id == borrower_id:
            raise BadRequestError("You cannot rent your own item")

        if end_date < start_date:
            raise BadRequestError("end_date must be >= start_date")

        # Check availability (with locking)
        is_available = await self.item_repo.check_availability(item_id, start_date, end_date)
        if not is_available:
            raise DoubleBookingError()

        request = RentalRequest(
            id=str(uuid.uuid4()),
            item_id=item_id,
            borrower_id=borrower_id,
            community_id=self.community_id,
            status=RentalRequestStatus.PENDING,
            start_date=start_date,
            end_date=end_date,
            proposed_daily_rate=proposed_daily_rate,
            message=message,
            expires_at=datetime.utcnow() + timedelta(hours=48),
        )
        created = await self.repo.create(request)

        # Notify item owner
        await self.notif_service.create_notification(
            user_id=item.owner_id,
            notif_type="rental_request",
            title="New Rental Request",
            message=f"You have a new rental request for '{item.title}'",
            data={"rental_request_id": created.id, "item_id": item_id},
        )

        return created

    async def accept_request(self, request_id: str, owner_id: str) -> RentalRequest:
        """Accept a rental request (only item owner can accept)."""
        request = await self._get_and_validate_owner(request_id, owner_id)
        self._validate_transition(request.status, RentalRequestStatus.ACCEPTED)

        request.status = RentalRequestStatus.ACCEPTED
        request.responded_at = datetime.utcnow()
        await self.db.flush()
        await self.db.refresh(request)

        # Block dates for the item
        await self.item_repo.block_dates(
            request.item_id, request.start_date, request.end_date, "rental_accepted"
        )

        # Automatically create (or return existing) transaction when request is accepted.
        from app.services.transaction_service import TransactionService
        txn_service = TransactionService(self.db, self.community_id)
        await txn_service.confirm_booking(request.id, f"accept:{request.id}")

        # Notify borrower
        await self.notif_service.create_notification(
            user_id=request.borrower_id,
            notif_type="rental_request",
            title="Request Accepted!",
            message="Your rental request has been accepted.",
            data={"rental_request_id": request.id},
        )

        return request

    async def reject_request(self, request_id: str, owner_id: str) -> RentalRequest:
        """Reject a rental request."""
        request = await self._get_and_validate_owner(request_id, owner_id)
        self._validate_transition(request.status, RentalRequestStatus.REJECTED)

        request.status = RentalRequestStatus.REJECTED
        request.responded_at = datetime.utcnow()
        await self.db.flush()
        await self.db.refresh(request)
        return request

    async def counter_propose(
        self, request_id: str, owner_id: str,
        counter_start_date, counter_end_date,
        counter_daily_rate: float, counter_message: str | None = None,
    ) -> RentalRequest:
        """Counter-propose with different terms."""
        request = await self._get_and_validate_owner(request_id, owner_id)
        self._validate_transition(request.status, RentalRequestStatus.COUNTER_PROPOSED)

        request.status = RentalRequestStatus.COUNTER_PROPOSED
        request.counter_start_date = counter_start_date
        request.counter_end_date = counter_end_date
        request.counter_daily_rate = counter_daily_rate
        request.counter_message = counter_message
        request.responded_at = datetime.utcnow()
        request.expires_at = datetime.utcnow() + timedelta(hours=48)
        await self.db.flush()
        await self.db.refresh(request)
        return request

    async def cancel_request(self, request_id: str, borrower_id: str) -> RentalRequest:
        """Cancel request (only borrower can cancel)."""
        request = await self.repo.get_by_id(request_id)
        if not request:
            raise NotFoundError("RentalRequest", request_id)
        if request.borrower_id != borrower_id:
            raise ForbiddenError("Only the borrower can cancel this request")
        self._validate_transition(request.status, RentalRequestStatus.CANCELLED)

        request.status = RentalRequestStatus.CANCELLED
        await self.db.flush()
        await self.db.refresh(request)
        return request

    async def get_my_requests(self, user_id: str) -> list[RentalRequest]:
        return await self.repo.get_by_borrower(user_id)

    async def get_incoming_requests(self, owner_id: str) -> list[RentalRequest]:
        """Get requests received for items owned by this user."""
        return await self.repo.get_for_owner(owner_id)

    async def get_requests_for_item(self, item_id: str, owner_id: str) -> list[RentalRequest]:
        item = await self.item_repo.get_by_id(item_id)
        if not item or item.owner_id != owner_id:
            raise ForbiddenError("Not your item")
        return await self.repo.get_by_item(item_id)

    # ─── Private helpers ─────────────────────────

    async def _get_and_validate_owner(self, request_id: str, owner_id: str) -> RentalRequest:
        request = await self.repo.get_by_id(request_id)
        if not request:
            raise NotFoundError("RentalRequest", request_id)
        if request.borrower_id == owner_id:
            raise ForbiddenError("Borrower cannot approve, reject, or counter their own request")
        item = await self.item_repo.get_by_id(request.item_id)
        if not item or item.owner_id != owner_id:
            raise ForbiddenError("Only the item owner can perform this action")
        return request

    def _validate_transition(self, current: RentalRequestStatus, target: RentalRequestStatus):
        allowed = VALID_TRANSITIONS.get(current, [])
        if target not in allowed:
            raise InvalidStateTransitionError(current.value, target.value)
