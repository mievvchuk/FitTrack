from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.security import get_current_user
from app.db.session import get_db
from app.models.notifications import NotificationPreference, NotificationRecord
from app.models.rbac import User
from app.schemas.notifications import (
    DeviceTokenRead,
    DeviceTokenUpsertRequest,
    NotificationPreferenceRead,
    NotificationPreferenceUpdate,
    NotificationRead,
    NotificationSendRead,
    SendNotificationRequest,
)
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["Notifications"])


def _service(
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> NotificationService:
    return NotificationService(db, settings)


@router.post("/device-tokens", response_model=DeviceTokenRead, status_code=status.HTTP_201_CREATED)
def upsert_device_token(
    payload: DeviceTokenUpsertRequest,
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(_service),
) -> object:
    return service.upsert_device_token(current_user, payload)


@router.delete("/device-tokens/{token_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_device_token(
    token_id: UUID,
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(_service),
) -> None:
    service.deactivate_device_token(current_user, token_id)


@router.get("/preferences", response_model=NotificationPreferenceRead)
def get_preferences(
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(_service),
) -> object:
    return service.get_or_create_preferences(current_user)


@router.put("/preferences", response_model=NotificationPreferenceRead)
def update_preferences(
    payload: NotificationPreferenceUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    service: NotificationService = Depends(_service),
) -> object:
    preferences = service.get_or_create_preferences(current_user)
    preferences.workout_reminders_enabled = payload.workout_reminders_enabled
    preferences.workout_reminder_time = payload.workout_reminder_time
    preferences.payment_notifications_enabled = payload.payment_notifications_enabled
    preferences.premium_expiration_enabled = payload.premium_expiration_enabled
    preferences.premium_expiration_days_before = payload.premium_expiration_days_before
    db.commit()
    db.refresh(preferences)
    return preferences


@router.get("", response_model=list[NotificationRead])
def list_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[NotificationRecord]:
    return list(
        db.scalars(
            select(NotificationRecord)
            .where(NotificationRecord.user_id == current_user.id)
            .order_by(NotificationRecord.created_at.desc())
            .limit(100)
        )
    )


@router.patch("/{notification_id}/read", response_model=NotificationRead)
def mark_notification_read(
    notification_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> NotificationRecord:
    notification = db.scalar(
        select(NotificationRecord).where(
            NotificationRecord.id == notification_id,
            NotificationRecord.user_id == current_user.id,
        )
    )
    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )
    from datetime import datetime, timezone

    notification.read_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(notification)
    return notification


@router.post("/test", response_model=NotificationSendRead)
def send_test_notification(
    payload: SendNotificationRequest,
    current_user: User = Depends(get_current_user),
    service: NotificationService = Depends(_service),
) -> dict[str, object]:
    notification, sent_count, failed_count = service.send_to_user(
        current_user,
        notification_type=payload.type,
        title=payload.title,
        body=payload.body,
        data=payload.data,
    )
    return {
        "notification": notification,
        "sent_count": sent_count,
        "failed_count": failed_count,
    }
