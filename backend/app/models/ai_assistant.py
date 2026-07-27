from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.rbac import Base, SCHEMA


class AIFitnessPlan(Base):
    __tablename__ = "ai_fitness_plans"
    __table_args__ = {"schema": SCHEMA}

    id: Mapped[UUID] = mapped_column(PG_UUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        ForeignKey(f"{SCHEMA}.users.id", ondelete="CASCADE"),
        index=True,
    )
    goal: Mapped[str] = mapped_column(String(40))
    weight_kg: Mapped[Decimal] = mapped_column(Numeric(5, 2))
    height_cm: Mapped[Decimal] = mapped_column(Numeric(5, 2))
    fitness_level: Mapped[str] = mapped_column(String(20))
    prompt_payload: Mapped[dict[str, object]] = mapped_column(JSONB, default=dict)
    summary: Mapped[str] = mapped_column(Text)
    workout_plan: Mapped[dict[str, object]] = mapped_column(JSONB)
    nutrition_recommendations: Mapped[dict[str, object]] = mapped_column(JSONB)
    safety_notes: Mapped[list[str]] = mapped_column(JSONB, default=list)
    raw_ai_response: Mapped[dict[str, object]] = mapped_column(JSONB, default=dict)
    model: Mapped[str] = mapped_column(String(80))
    status: Mapped[str] = mapped_column(String(20), default="generated")
    error_message: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
