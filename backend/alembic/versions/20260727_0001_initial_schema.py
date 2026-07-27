"""Initial FitTrack PostgreSQL schema.

Revision ID: 20260727_0001
Revises:
Create Date: 2026-07-27 00:00:00

"""
from __future__ import annotations

from pathlib import Path

from alembic import op

revision = "20260727_0001"
down_revision = None
branch_labels = None
depends_on = None


def _course_schema_sql() -> str:
    repo_root = Path(__file__).resolve().parents[3]
    sql_path = repo_root / "database" / "course_schema.sql"
    if not sql_path.exists():
        raise FileNotFoundError(
            "Cannot find database/course_schema.sql. "
            "Run Alembic from the repository root or use the provided Docker image."
        )
    return sql_path.read_text(encoding="utf-8")


def upgrade() -> None:
    op.get_bind().exec_driver_sql(_course_schema_sql())


def downgrade() -> None:
    op.execute("DROP SCHEMA IF EXISTS fittrack_course CASCADE")
