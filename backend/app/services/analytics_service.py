from __future__ import annotations

from datetime import date, timedelta
from decimal import Decimal

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.models.rbac import SCHEMA, User


class AnalyticsService:
    def __init__(self, db: Session) -> None:
        self._db = db

    def dashboard(self, user: User, days: int) -> dict[str, object]:
        to_date = date.today()
        from_date = to_date - timedelta(days=days - 1)
        params = {
            "user_id": user.id,
            "from_date": from_date,
            "to_date": to_date,
        }

        workout_summary = self._workout_summary(params)
        progress_summary = self._progress_summary(params)
        meal_summary = self._meal_summary(params)
        weight_chart = self._weight_chart(params)
        volume_chart = self._volume_chart(params)
        activity = self._activity_points(params)

        calories_burned = int(progress_summary["calories_burned"] or 0)
        calories_consumed = int(meal_summary["calories_consumed"] or 0)
        active_days = int(
            len(
                {
                    row["date"]
                    for row in activity
                    if row["workouts_count"] > 0
                    or row["calories_burned"] > 0
                    or row["calories_consumed"] > 0
                }
            )
        )

        return {
            "period": {
                "from_date": from_date,
                "to_date": to_date,
                "days": days,
            },
            "summary": {
                "workout_count": int(workout_summary["workout_count"] or 0),
                "completed_workout_count": int(
                    workout_summary["completed_workout_count"] or 0
                ),
                "active_days": active_days,
                "average_weight_kg": _to_float_or_none(progress_summary["average_weight_kg"]),
                "latest_weight_kg": _to_float_or_none(progress_summary["latest_weight_kg"]),
                "weight_change_kg": _weight_change(progress_summary),
                "progress_percent": _progress_percent(progress_summary),
                "total_volume_kg": _to_float(progress_summary["total_volume_kg"]),
                "calories_burned": calories_burned,
                "calories_consumed": calories_consumed,
                "average_daily_calories": round(calories_consumed / days)
                if days > 0
                else 0,
                "activity_score": min(100, round((active_days / days) * 100))
                if days > 0
                else 0,
            },
            "weight_chart": weight_chart,
            "workout_activity_chart": [
                {"date": row["date"], "value": float(row["workouts_count"])}
                for row in activity
            ],
            "volume_chart": volume_chart,
            "calorie_chart": [
                {
                    "date": row["date"],
                    "consumed": int(row["calories_consumed"]),
                    "burned": int(row["calories_burned"]),
                }
                for row in activity
            ],
            "activity": activity,
        }

    def _workout_summary(self, params: dict[str, object]) -> dict[str, object]:
        return dict(
            self._db.execute(
                text(
                    f"""
                    SELECT
                        COUNT(*)::int AS workout_count,
                        COUNT(*) FILTER (WHERE is_completed IS TRUE)::int
                            AS completed_workout_count
                    FROM {SCHEMA}.workouts
                    WHERE user_id = :user_id
                      AND COALESCE(completed_at::date, scheduled_for, created_at::date)
                          BETWEEN :from_date AND :to_date
                    """
                ),
                params,
            )
            .mappings()
            .one()
        )

    def _progress_summary(self, params: dict[str, object]) -> dict[str, object]:
        return dict(
            self._db.execute(
                text(
                    f"""
                    WITH period_progress AS (
                        SELECT *
                        FROM {SCHEMA}.progress
                        WHERE user_id = :user_id
                          AND progress_date BETWEEN :from_date AND :to_date
                    ),
                    first_weight AS (
                        SELECT weight_kg
                        FROM period_progress
                        WHERE weight_kg IS NOT NULL
                        ORDER BY progress_date ASC, created_at ASC
                        LIMIT 1
                    ),
                    latest_weight AS (
                        SELECT weight_kg
                        FROM period_progress
                        WHERE weight_kg IS NOT NULL
                        ORDER BY progress_date DESC, created_at DESC
                        LIMIT 1
                    )
                    SELECT
                        AVG(weight_kg) AS average_weight_kg,
                        (SELECT weight_kg FROM first_weight) AS first_weight_kg,
                        (SELECT weight_kg FROM latest_weight) AS latest_weight_kg,
                        COALESCE(SUM(total_volume_kg), 0) AS total_volume_kg,
                        COALESCE(SUM(calories_burned), 0)::int AS calories_burned
                    FROM period_progress
                    """
                ),
                params,
            )
            .mappings()
            .one()
        )

    def _meal_summary(self, params: dict[str, object]) -> dict[str, object]:
        return dict(
            self._db.execute(
                text(
                    f"""
                    SELECT COALESCE(SUM(calories), 0)::int AS calories_consumed
                    FROM {SCHEMA}.meals
                    WHERE user_id = :user_id
                      AND meal_date BETWEEN :from_date AND :to_date
                    """
                ),
                params,
            )
            .mappings()
            .one()
        )

    def _weight_chart(self, params: dict[str, object]) -> list[dict[str, object]]:
        return [
            {"date": row["date"], "value": _to_float(row["value"])}
            for row in self._db.execute(
                text(
                    f"""
                    SELECT progress_date AS date, AVG(weight_kg) AS value
                    FROM {SCHEMA}.progress
                    WHERE user_id = :user_id
                      AND progress_date BETWEEN :from_date AND :to_date
                      AND weight_kg IS NOT NULL
                    GROUP BY progress_date
                    ORDER BY progress_date
                    """
                ),
                params,
            ).mappings()
        ]

    def _volume_chart(self, params: dict[str, object]) -> list[dict[str, object]]:
        return [
            {"date": row["date"], "value": _to_float(row["value"])}
            for row in self._db.execute(
                text(
                    f"""
                    SELECT progress_date AS date, COALESCE(SUM(total_volume_kg), 0) AS value
                    FROM {SCHEMA}.progress
                    WHERE user_id = :user_id
                      AND progress_date BETWEEN :from_date AND :to_date
                    GROUP BY progress_date
                    ORDER BY progress_date
                    """
                ),
                params,
            ).mappings()
        ]

    def _activity_points(self, params: dict[str, object]) -> list[dict[str, object]]:
        return [
            {
                "date": row["date"],
                "workouts_count": int(row["workouts_count"] or 0),
                "calories_burned": int(row["calories_burned"] or 0),
                "calories_consumed": int(row["calories_consumed"] or 0),
                "total_volume_kg": _to_float(row["total_volume_kg"]),
            }
            for row in self._db.execute(
                text(
                    f"""
                    WITH days AS (
                        SELECT generate_series(
                            CAST(:from_date AS date),
                            CAST(:to_date AS date),
                            INTERVAL '1 day'
                        )::date AS date
                    ),
                    workouts_daily AS (
                        SELECT
                            COALESCE(completed_at::date, scheduled_for, created_at::date)
                                AS date,
                            COUNT(*)::int AS workouts_count
                        FROM {SCHEMA}.workouts
                        WHERE user_id = :user_id
                          AND COALESCE(completed_at::date, scheduled_for, created_at::date)
                              BETWEEN :from_date AND :to_date
                        GROUP BY 1
                    ),
                    progress_daily AS (
                        SELECT
                            progress_date AS date,
                            COALESCE(SUM(calories_burned), 0)::int AS calories_burned,
                            COALESCE(SUM(total_volume_kg), 0) AS total_volume_kg
                        FROM {SCHEMA}.progress
                        WHERE user_id = :user_id
                          AND progress_date BETWEEN :from_date AND :to_date
                        GROUP BY progress_date
                    ),
                    meals_daily AS (
                        SELECT
                            meal_date AS date,
                            COALESCE(SUM(calories), 0)::int AS calories_consumed
                        FROM {SCHEMA}.meals
                        WHERE user_id = :user_id
                          AND meal_date BETWEEN :from_date AND :to_date
                        GROUP BY meal_date
                    )
                    SELECT
                        days.date,
                        COALESCE(workouts_daily.workouts_count, 0) AS workouts_count,
                        COALESCE(progress_daily.calories_burned, 0) AS calories_burned,
                        COALESCE(meals_daily.calories_consumed, 0) AS calories_consumed,
                        COALESCE(progress_daily.total_volume_kg, 0) AS total_volume_kg
                    FROM days
                    LEFT JOIN workouts_daily ON workouts_daily.date = days.date
                    LEFT JOIN progress_daily ON progress_daily.date = days.date
                    LEFT JOIN meals_daily ON meals_daily.date = days.date
                    ORDER BY days.date
                    """
                ),
                params,
            ).mappings()
        ]


def _to_float(value: object) -> float:
    if value is None:
        return 0.0
    if isinstance(value, Decimal):
        return float(value)
    return float(value)


def _to_float_or_none(value: object) -> float | None:
    if value is None:
        return None
    return _to_float(value)


def _weight_change(progress_summary: dict[str, object]) -> float | None:
    first = _to_float_or_none(progress_summary["first_weight_kg"])
    latest = _to_float_or_none(progress_summary["latest_weight_kg"])
    if first is None or latest is None:
        return None
    return round(latest - first, 2)


def _progress_percent(progress_summary: dict[str, object]) -> float | None:
    first = _to_float_or_none(progress_summary["first_weight_kg"])
    latest = _to_float_or_none(progress_summary["latest_weight_kg"])
    if first is None or latest is None or first == 0:
        return None
    return round(((latest - first) / first) * 100, 2)
