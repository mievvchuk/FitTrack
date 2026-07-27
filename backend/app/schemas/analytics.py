from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field


class AnalyticsPeriodRead(BaseModel):
    from_date: date
    to_date: date
    days: int = Field(ge=1, le=365)


class AnalyticsSummaryRead(BaseModel):
    workout_count: int
    completed_workout_count: int
    active_days: int
    average_weight_kg: float | None = None
    latest_weight_kg: float | None = None
    weight_change_kg: float | None = None
    progress_percent: float | None = None
    total_volume_kg: float
    calories_burned: int
    calories_consumed: int
    average_daily_calories: int
    activity_score: int


class AnalyticsPointRead(BaseModel):
    date: date
    value: float


class AnalyticsCaloriesPointRead(BaseModel):
    date: date
    consumed: int
    burned: int


class AnalyticsActivityPointRead(BaseModel):
    date: date
    workouts_count: int
    calories_burned: int
    calories_consumed: int
    total_volume_kg: float


class AnalyticsDashboardRead(BaseModel):
    period: AnalyticsPeriodRead
    summary: AnalyticsSummaryRead
    weight_chart: list[AnalyticsPointRead]
    workout_activity_chart: list[AnalyticsPointRead]
    volume_chart: list[AnalyticsPointRead]
    calorie_chart: list[AnalyticsCaloriesPointRead]
    activity: list[AnalyticsActivityPointRead]
