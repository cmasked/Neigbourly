"""
Notification service — event-driven, stored in DB.
"""

import uuid
from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from app.models.notification import Notification


class NotificationService:
    def __init__(self, db: AsyncSession, community_id: str):
        self.db = db
        self.community_id = community_id

    async def create_notification(
        self, user_id: str, notif_type: str,
        title: str, message: str | None = None,
        data: dict | None = None,
    ) -> Notification:
        """Create and store a notification."""
        notif = Notification(
            id=str(uuid.uuid4()),
            user_id=user_id,
            community_id=self.community_id,
            type=notif_type,
            title=title,
            message=message,
            data=data,
        )
        self.db.add(notif)
        await self.db.flush()
        await self.db.refresh(notif)
        return notif

    async def get_user_notifications(
        self, user_id: str, unread_only: bool = False,
        limit: int = 20, cursor_id: str | None = None,
    ) -> list[Notification]:
        """Get notifications for a user."""
        query = (
            select(Notification)
            .where(
                Notification.user_id == user_id,
                Notification.community_id == self.community_id,
            )
            .order_by(Notification.created_at.desc())
        )
        if unread_only:
            query = query.where(Notification.is_read == False)
        if cursor_id:
            # Get cursor notification's created_at
            cursor_result = await self.db.execute(
                select(Notification).where(Notification.id == cursor_id)
            )
            cursor_notif = cursor_result.scalar_one_or_none()
            if cursor_notif:
                query = query.where(Notification.created_at < cursor_notif.created_at)
        query = query.limit(limit)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def mark_as_read(self, notification_id: str, user_id: str) -> bool:
        """Mark a notification as read."""
        result = await self.db.execute(
            select(Notification).where(
                Notification.id == notification_id,
                Notification.user_id == user_id,
                Notification.community_id == self.community_id,
            )
        )
        notif = result.scalar_one_or_none()
        if not notif:
            return False
        notif.is_read = True
        notif.read_at = datetime.utcnow()
        await self.db.flush()
        return True

    async def mark_all_read(self, user_id: str) -> int:
        """Mark all notifications as read for a user."""
        result = await self.db.execute(
            update(Notification)
            .where(
                Notification.user_id == user_id,
                Notification.community_id == self.community_id,
                Notification.is_read == False,
            )
            .values(is_read=True, read_at=datetime.utcnow())
        )
        await self.db.flush()
        return result.rowcount
