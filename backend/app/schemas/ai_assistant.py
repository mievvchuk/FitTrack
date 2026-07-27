from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

TrainingGoal = Literal[
    "weight_loss",
    "muscle_gain",
    "strength",
    "endurance",
    "general_fitness",
]

FitnessLevel = Literal["beginner", "intermediate", "advanced"]


class AIFitnessPlanRequest(BaseModel):
    goal: TrainingGoal
    weight_kg: Decimal = Field(ge=25, le=300)
    height_cm: Decimal = Field(ge=80, le=250)
    fitness_level: FitnessLevel


class AIExerciseRecommendation(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    muscle_group: str = Field(min_length=2, max_length=80)
    equipment: str = Field(min_length=2, max_length=120)
    sets: int = Field(ge=1, le=8)
    reps: str = Field(min_length=1, max_length=40)
    rest_seconds: int = Field(ge=0, le=600)
    technique_tip: str = Field(min_length=2, max_length=300)


class AIWorkoutDay(BaseModel):
    day: int = Field(ge=1, le=7)
    focus: str = Field(min_length=2, max_length=120)
    duration_minutes: int = Field(ge=15, le=150)
    warm_up: list[str] = Field(min_length=1, max_length=5)
    exercises: list[AIExerciseRecommendation] = Field(min_length=2, max_length=10)
    cooldown: list[str] = Field(min_length=1, max_length=5)


class AIWorkoutPlan(BaseModel):
    weekly_schedule: list[AIWorkoutDay] = Field(min_length=2, max_length=7)
    progression: list[str] = Field(min_length=1, max_length=6)


class AINutritionRecommendations(BaseModel):
    calories_per_day: int = Field(ge=1000, le=6000)
    protein_g: int = Field(ge=30, le=400)
    fats_g: int = Field(ge=20, le=250)
    carbs_g: int = Field(ge=50, le=800)
    meals_per_day: int = Field(ge=2, le=8)
    hydration_liters: float = Field(ge=1.0, le=8.0)
    recommendations: list[str] = Field(min_length=2, max_length=8)


class AIFitnessPlanContent(BaseModel):
    summary: str = Field(min_length=10, max_length=1000)
    workout_plan: AIWorkoutPlan
    nutrition_recommendations: AINutritionRecommendations
    safety_notes: list[str] = Field(min_length=1, max_length=6)


class AIFitnessPlanRead(BaseModel):
    id: UUID
    user_id: UUID
    goal: str
    weight_kg: Decimal
    height_cm: Decimal
    fitness_level: str
    summary: str
    workout_plan: AIWorkoutPlan
    nutrition_recommendations: AINutritionRecommendations
    safety_notes: list[str]
    model: str
    status: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
