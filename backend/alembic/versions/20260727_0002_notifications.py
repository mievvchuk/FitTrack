"""Add Firebase Cloud Messaging notification tables.

Revision ID: 20260727_0002
Revises: 20260727_0001
Create Date: 2026-07-27 00:10:00

"""
from __future__ import annotations

from alembic import op

revision = "20260727_0002"
down_revision = "20260727_0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS fittrack_course.notification_device_tokens (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES fittrack_course.users(id) ON DELETE CASCADE,
            fcm_token TEXT NOT NULL UNIQUE,
            platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
            device_id VARCHAR(120),
            app_version VARCHAR(40),
            is_active BOOLEAN NOT NULL DEFAULT TRUE,
            last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS fittrack_course.notification_preferences (
            user_id UUID PRIMARY KEY REFERENCES fittrack_course.users(id) ON DELETE CASCADE,
            workout_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
            workout_reminder_time TIME NOT NULL DEFAULT '09:00',
            payment_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
            premium_expiration_enabled BOOLEAN NOT NULL DEFAULT TRUE,
            premium_expiration_days_before INTEGER NOT NULL DEFAULT 3 CHECK (
                premium_expiration_days_before BETWEEN 1 AND 30
            ),
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS fittrack_course.notifications (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES fittrack_course.users(id) ON DELETE CASCADE,
            type VARCHAR(40) NOT NULL CHECK (
                type IN (
                    'workout_reminder',
                    'payment_succeeded',
                    'payment_failed',
                    'premium_expiring',
                    'premium_expired',
                    'system'
                )
                OR type LIKE 'payment_%'
            ),
            title VARCHAR(160) NOT NULL,
            body TEXT NOT NULL,
            data JSONB NOT NULL DEFAULT '{}'::jsonb,
            status VARCHAR(20) NOT NULL DEFAULT 'queued' CHECK (
                status IN ('queued', 'sent', 'failed', 'skipped', 'read')
            ),
            fcm_message_id TEXT,
            error_message TEXT,
            sent_at TIMESTAMPTZ,
            read_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_notification_device_tokens_user_id
        ON fittrack_course.notification_device_tokens(user_id)
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_notification_device_tokens_fcm_token
        ON fittrack_course.notification_device_tokens(fcm_token)
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_notification_device_tokens_active
        ON fittrack_course.notification_device_tokens(user_id, is_active)
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_notifications_user_created
        ON fittrack_course.notifications(user_id, created_at DESC)
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_notifications_user_read
        ON fittrack_course.notifications(user_id, read_at)
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_notifications_type_status
        ON fittrack_course.notifications(type, status)
        """
    )
    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_trigger WHERE tgname = 'trg_notification_device_tokens_updated_at'
            ) THEN
                CREATE TRIGGER trg_notification_device_tokens_updated_at
                BEFORE UPDATE ON fittrack_course.notification_device_tokens
                FOR EACH ROW EXECUTE FUNCTION fittrack_course.set_updated_at();
            END IF;

            IF NOT EXISTS (
                SELECT 1 FROM pg_trigger WHERE tgname = 'trg_notification_preferences_updated_at'
            ) THEN
                CREATE TRIGGER trg_notification_preferences_updated_at
                BEFORE UPDATE ON fittrack_course.notification_preferences
                FOR EACH ROW EXECUTE FUNCTION fittrack_course.set_updated_at();
            END IF;

            IF NOT EXISTS (
                SELECT 1 FROM pg_trigger WHERE tgname = 'trg_notifications_updated_at'
            ) THEN
                CREATE TRIGGER trg_notifications_updated_at
                BEFORE UPDATE ON fittrack_course.notifications
                FOR EACH ROW EXECUTE FUNCTION fittrack_course.set_updated_at();
            END IF;
        END $$;
        """
    )


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS fittrack_course.notifications CASCADE")
    op.execute("DROP TABLE IF EXISTS fittrack_course.notification_preferences CASCADE")
    op.execute("DROP TABLE IF EXISTS fittrack_course.notification_device_tokens CASCADE")
