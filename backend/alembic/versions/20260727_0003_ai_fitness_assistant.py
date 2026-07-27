"""Add AI Fitness Assistant plans.

Revision ID: 20260727_0003
Revises: 20260727_0002
Create Date: 2026-07-27 00:03:00

"""
from __future__ import annotations

from alembic import op

revision = "20260727_0003"
down_revision = "20260727_0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM pg_type t
                JOIN pg_namespace n ON n.oid = t.typnamespace
                WHERE t.typname = 'fittrack_fitness_level'
                  AND n.nspname = 'fittrack_course'
            ) THEN
                CREATE TYPE fittrack_course.fittrack_fitness_level
                AS ENUM ('beginner', 'intermediate', 'advanced');
            END IF;
        END
        $$;
        """
    )
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS fittrack_course.ai_fitness_plans (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES fittrack_course.users(id) ON DELETE CASCADE,
            goal fittrack_course.fittrack_training_goal NOT NULL,
            weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg BETWEEN 25 AND 300),
            height_cm NUMERIC(5,2) NOT NULL CHECK (height_cm BETWEEN 80 AND 250),
            fitness_level fittrack_course.fittrack_fitness_level NOT NULL,
            prompt_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
            summary TEXT NOT NULL,
            workout_plan JSONB NOT NULL,
            nutrition_recommendations JSONB NOT NULL,
            safety_notes JSONB NOT NULL DEFAULT '[]'::jsonb,
            raw_ai_response JSONB NOT NULL DEFAULT '{}'::jsonb,
            model VARCHAR(80) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'generated' CHECK (
                status IN ('generated', 'failed')
            ),
            error_message TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        """
    )
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_ai_fitness_plans_user_created
        ON fittrack_course.ai_fitness_plans(user_id, created_at DESC);

        CREATE INDEX IF NOT EXISTS idx_ai_fitness_plans_goal
        ON fittrack_course.ai_fitness_plans(goal);
        """
    )
    op.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM pg_trigger
                WHERE tgname = 'trg_ai_fitness_plans_updated_at'
            ) THEN
                CREATE TRIGGER trg_ai_fitness_plans_updated_at
                BEFORE UPDATE ON fittrack_course.ai_fitness_plans
                FOR EACH ROW EXECUTE FUNCTION fittrack_course.set_updated_at();
            END IF;
        END
        $$;
        """
    )
    op.execute(
        """
        INSERT INTO fittrack_course.permissions (code, name, description, resource, action)
        VALUES (
            'ai:generate',
            'Generate AI fitness plans',
            'Allows generating AI workout and nutrition recommendations',
            'ai_assistant',
            'generate'
        )
        ON CONFLICT (code) DO NOTHING;

        INSERT INTO fittrack_course.role_permissions (role_id, permission_id)
        SELECT r.id, p.id
        FROM fittrack_course.roles r
        JOIN fittrack_course.permissions p ON p.code = 'ai:generate'
        WHERE r.code IN ('user', 'trainer', 'admin')
        ON CONFLICT DO NOTHING;
        """
    )


def downgrade() -> None:
    op.execute(
        """
        DELETE FROM fittrack_course.role_permissions rp
        USING fittrack_course.permissions p
        WHERE rp.permission_id = p.id
          AND p.code = 'ai:generate';

        DELETE FROM fittrack_course.permissions
        WHERE code = 'ai:generate';

        DROP TABLE IF EXISTS fittrack_course.ai_fitness_plans;
        DROP TYPE IF EXISTS fittrack_course.fittrack_fitness_level;
        """
    )
