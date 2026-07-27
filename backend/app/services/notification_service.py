from __future__ import annotations

from datetime import datetime, timedelta, timezone
from uuid import UUID

from firebase_admin import messaging
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.models.notifications import (
    NotificationDeviceToken,
    NotificationPreference,
    NotificationRecord,
)
from app.models.rbac import User
from app.schemas.notifications import DeviceTokenUpsertRequest


class NotificationService:
    def __init__(self, db: Session, settings: Settings) -> None:
        self._db = db
        self._settings = settings

    def upsert_device_token(
        self,
        user: User,
        payload: DeviceTokenUpsertRequest,
    ) -> NotificationDeviceToken:
        token = self._db.scalar(
            select(NotificationDeviceToken).where(
                NotificationDeviceToken.fcm_token == payload.fcm_token,
            )
        )

        now = datetime.now(timezone.utc)
        if token is None:
            token = NotificationDeviceToken(
                user_id=user.id,
                fcm_token=payload.fcm_token,
                platform=payload.platform,
                device_id=payload.device_id,
                app_version=payload.app_version,
                is_active=True,
                last_seen_at=now,
            )
            self._db.add(token)
        else:
            token.user_id = user.id
            token.platform = payload.platform
            token.device_id = payload.device_id
            token.app_version = payload.app_version
            token.is_active = True
            token.last_seen_at = now

        self._db.commit()
        self._db.refresh(token)
        return token

    def deactivate_device_token(self, user: User, token_id: UUID) -> None:
        token = self._db.scalar(
            select(NotificationDeviceToken).where(
                NotificationDeviceToken.id == token_id,
                NotificationDeviceToken.user_id == user.id,
            )
        )
        if token is not None:
            token.is_active = False
            self._db.commit()

    def create_skipped_record(
        self,
        user: User,
        *,
        notification_type: str,
        title: str,
        body: str,
        data: dict[str, str] | None = None,
        reason: str,
    ) -> tuple[NotificationRecord, int, int]:
        record = NotificationRecord(
            user_id=user.id,
            type=notification_type,
            title=title,
            body=body,
            data=data or {},
            status="skipped",
            error_message=reason,
        )
        self._db.add(record)
        self._db.commit()
        self._db.refresh(record)
        return record, 0, 0

    def get_or_create_preferences(self, user: User) -> NotificationPreference:
        preferences = self._db.get(NotificationPreference, user.id)
        if preferences is None:
            preferences = NotificationPreference(user_id=user.id)
            self._db.add(preferences)
            self._db.commit()
            self._db.refresh(preferences)
        return preferences

    def send_to_user(
        self,
        user: User,
        *,
        notification_type: str,
        title: str,
        body: str,
        data: dict[str, str] | None = None,
    ) -> tuple[NotificationRecord, int, int]:
        payload_data = data or {}
        record = NotificationRecord(
            user_id=user.id,
            type=notification_type,
            title=title,
            body=body,
            data=payload_data,
            status="queued",
        )
        self._db.add(record)
        self._db.flush()

        tokens = list(
            self._db.scalars(
                select(NotificationDeviceToken).where(
                    NotificationDeviceToken.user_id == user.id,
                    NotificationDeviceToken.is_active.is_(True),
                )
            )
        )

        if not self._settings.notifications_enabled:
            record.status = "skipped"
            record.error_message = "Notifications are disabled by configuration."
            self._db.commit()
            self._db.refresh(record)
            return record, 0, 0

        if not tokens:
            record.status = "skipped"
            record.error_message = "No active FCM device tokens."
            self._db.commit()
            self._db.refresh(record)
            return record, 0, 0

        sent_count = 0
        failed_count = 0
        first_message_id: str | None = None
        last_error: str | None = None

        for token in tokens:
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data={
                    **payload_data,
                    "notification_id": str(record.id),
                    "type": notification_type,
                },
                token=token.fcm_token,
            )
            try:
                message_id = messaging.send(
                    message,
                    dry_run=self._settings.fcm_dry_run,
                )
                sent_count += 1
                first_message_id = first_message_id or message_id
            except Exception as exc:
                failed_count += 1
                token.is_active = False
                last_error = str(exc)

        record.status = "sent" if sent_count > 0 else "failed"
        record.fcm_message_id = first_message_id
        record.error_message = last_error
        record.sent_at = datetime.now(timezone.utc) if sent_count > 0 else None
        self._db.commit()
        self._db.refresh(record)
        return record, sent_count, failed_count

    def send_workout_reminder(
        self,
        user: User,
        *,
        workout_id: str,
        workout_title: str,
    ) -> tuple[NotificationRecord, int, int]:
        preferences = self.get_or_create_preferences(user)
        if not preferences.workout_reminders_enabled:
            return self.create_skipped_record(
                user,
                notification_type="workout_reminder",
                title="Workout reminder",
                body=f"Today planned workout: {workout_title}",
                data={"workout_id": workout_id},
                reason="Workout reminders are disabled by user preferences.",
            )
        return self.send_to_user(
            user,
            notification_type="workout_reminder",
            title="Workout reminder",
            body=f"Today planned workout: {workout_title}",
            data={"workout_id": workout_id},
        )

    def send_payment_notification(
        self,
        user: User,
        *,
        payment_id: str,
        status: str,
    ) -> tuple[NotificationRecord, int, int]:
        preferences = self.get_or_create_preferences(user)
        if not preferences.payment_notifications_enabled:
            return self.create_skipped_record(
                user,
                notification_type=f"payment_{status}",
                title="Payment update",
                body=f"Payment status: {status}",
                data={"payment_id": payment_id},
                reason="Payment notifications are disabled by user preferences.",
            )
        return self.send_to_user(
            user,
            notification_type=f"payment_{status}",
            title="Payment update",
            body=f"Payment status: {status}",
            data={"payment_id": payment_id},
        )

    def send_premium_expiration(
        self,
        user: User,
        *,
        subscription_id: str,
        expires_at: datetime,
    ) -> tuple[NotificationRecord, int, int]:
        preferences = self.get_or_create_preferences(user)
        days_left = max((expires_at - datetime.now(timezone.utc)).days, 0)
        notification_type = "premium_expired" if days_left == 0 else "premium_expiring"

        if not preferences.premium_expiration_enabled:
            return self.create_skipped_record(
                user,
                notification_type=notification_type,
                title="Premium status",
                body="Premium expiration notification is disabled.",
                data={"subscription_id": subscription_id},
                reason="Premium expiration notifications are disabled by user preferences.",
            )

        threshold = timedelta(days=preferences.premium_expiration_days_before)
        if expires_at - datetime.now(timezone.utc) > threshold:
            return self.create_skipped_record(
                user,
                notification_type=notification_type,
                title="Premium status",
                body="Premium expiration is not close enough for a reminder.",
                data={"subscription_id": subscription_id},
                reason="Premium expiration is outside the configured reminder window.",
            )

        body = "Premium has expired." if days_left == 0 else f"Premium expires in {days_left} day(s)."
        return self.send_to_user(
            user,
            notification_type=notification_type,
            title="Premium status",
            body=body,
            data={"subscription_id": subscription_id},
        )
