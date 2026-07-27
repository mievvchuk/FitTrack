from datetime import datetime, time
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

NotificationType = Literal[
    "workout_reminder",
    "payment_succeeded",
    "payment_failed",
    "premium_expiring",
    "premium_expired",
    "system",
]


class DeviceTokenUpsertRequest(BaseModel):
    fcm_token: str = Field(min_length=20, max_length=4096)
    platform: Literal["android", "ios", "web"]
    device_id: str | None = Field(default=None, max_length=120)
    app_version: str | None = Field(default=None, max_length=40)


class DeviceTokenRead(BaseModel):
    id: UUID
    user_id: UUID
    platform: str
    device_id: str | None = None
    app_version: str | None = None
    is_active: bool
    last_seen_at: datetime
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class NotificationPreferenceRead(BaseModel):
    user_id: UUID
    workout_reminders_enabled: bool
    workout_reminder_time: time
    payment_notifications_enabled: bool
    premium_expiration_enabled: bool
    premium_expiration_days_before: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class NotificationPreferenceUpdate(BaseModel):
    workout_reminders_enabled: bool = True
    workout_reminder_time: time = time(9, 0)
    payment_notifications_enabled: bool = True
    premium_expiration_enabled: bool = True
    premium_expiration_days_before: int = Field(default=3, ge=1, le=30)


class NotificationRead(BaseModel):
    id: UUID
    user_id: UUID
    type: str
    title: str
    body: str
    data: dict[str, str]
    status: str
    fcm_message_id: str | None = None
    error_message: str | None = None
    sent_at: datetime | None = None
    read_at: datetime | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class SendNotificationRequest(BaseModel):
    type: NotificationType = "system"
    title: str = Field(min_length=2, max_length=160)
    body: str = Field(min_length=2, max_length=2000)
    data: dict[str, str] = Field(default_factory=dict)


class NotificationSendRead(BaseModel):
    notification: NotificationRead
    sent_count: int
    failed_count: int
