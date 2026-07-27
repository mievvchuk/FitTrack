"""Add analytics dashboard permission.

Revision ID: 20260727_0004
Revises: 20260727_0003
Create Date: 2026-07-27 00:04:00

"""
from __future__ import annotations

from alembic import op

revision = "20260727_0004"
down_revision = "20260727_0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        INSERT INTO fittrack_course.permissions (code, name, description, resource, action)
        VALUES (
            'analytics:read',
            'Read analytics dashboard',
            'Allows viewing personal workout, weight, calorie and activity analytics',
            'analytics',
            'read'
        )
        ON CONFLICT (code) DO NOTHING;

        INSERT INTO fittrack_course.role_permissions (role_id, permission_id)
        SELECT r.id, p.id
        FROM fittrack_course.roles r
        JOIN fittrack_course.permissions p ON p.code = 'analytics:read'
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
          AND p.code = 'analytics:read';

        DELETE FROM fittrack_course.permissions
        WHERE code = 'analytics:read';
        """
    )
