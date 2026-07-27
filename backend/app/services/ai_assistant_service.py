from __future__ import annotations

import json
from uuid import UUID, uuid4

import httpx
from fastapi import HTTPException, status
from pydantic import ValidationError
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.models.ai_assistant import AIFitnessPlan
from app.models.rbac import User
from app.schemas.ai_assistant import AIFitnessPlanContent, AIFitnessPlanRequest

GOAL_LABELS = {
    "weight_loss": "fat loss and body recomposition",
    "muscle_gain": "muscle gain",
    "strength": "strength development",
    "endurance": "endurance improvement",
    "general_fitness": "general fitness",
}

SYSTEM_PROMPT = """
You are FitTrack AI Fitness Assistant, a careful fitness planning assistant.
Create practical workout and nutrition recommendations for a mobile fitness app.
Return only valid JSON. Do not include markdown.
Do not diagnose disease or replace medical advice.
Use safe, beginner-friendly progressions when the user is not advanced.
""".strip()


class AIFitnessAssistantService:
    def __init__(self, db: Session, settings: Settings) -> None:
        self._db = db
        self._settings = settings

    def generate_plan(
        self,
        user: User,
        payload: AIFitnessPlanRequest,
    ) -> AIFitnessPlan:
        content = self._request_ai_plan(user, payload)
        plan = self._parse_plan_content(content)

        prompt_payload = payload.model_dump(mode="json")
        db_plan = AIFitnessPlan(
            user_id=user.id,
            goal=payload.goal,
            weight_kg=payload.weight_kg,
            height_cm=payload.height_cm,
            fitness_level=payload.fitness_level,
            prompt_payload=prompt_payload,
            summary=plan.summary,
            workout_plan=plan.workout_plan.model_dump(mode="json"),
            nutrition_recommendations=plan.nutrition_recommendations.model_dump(mode="json"),
            safety_notes=plan.safety_notes,
            raw_ai_response={"content": content},
            model=self._settings.zai_chat_model,
            status="generated",
        )
        self._db.add(db_plan)
        self._db.commit()
        self._db.refresh(db_plan)
        return db_plan

    def list_user_plans(self, user: User, limit: int = 20) -> list[AIFitnessPlan]:
        return list(
            self._db.scalars(
                select(AIFitnessPlan)
                .where(AIFitnessPlan.user_id == user.id)
                .order_by(AIFitnessPlan.created_at.desc())
                .limit(limit)
            )
        )

    def get_user_plan(self, user: User, plan_id: UUID) -> AIFitnessPlan:
        plan = self._db.scalar(
            select(AIFitnessPlan).where(
                AIFitnessPlan.id == plan_id,
                AIFitnessPlan.user_id == user.id,
            )
        )
        if plan is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="AI fitness plan not found",
            )
        return plan

    def _request_ai_plan(self, user: User, payload: AIFitnessPlanRequest) -> str:
        if not self._settings.zai_api_key:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="ZAI_API_KEY is not configured",
            )

        endpoint = f"{self._settings.zai_base_url.rstrip('/')}/chat/completions"
        request_body = {
            "model": self._settings.zai_chat_model,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": self._build_user_prompt(payload)},
            ],
            "temperature": 0.35,
            "max_tokens": 3000,
            "stream": False,
            "thinking": {"type": "disabled"},
            "response_format": {"type": "json_object"},
            "request_id": f"fittrack-{uuid4().hex}",
            "user_id": str(user.id),
        }

        try:
            response = httpx.post(
                endpoint,
                headers={
                    "Authorization": f"Bearer {self._settings.zai_api_key}",
                    "Content-Type": "application/json",
                    "Accept-Language": "en-US,en",
                },
                json=request_body,
                timeout=self._settings.zai_timeout_seconds,
            )
            response.raise_for_status()
        except httpx.TimeoutException as exc:
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail="Z.AI request timed out",
            ) from exc
        except httpx.HTTPStatusError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Z.AI API returned status {exc.response.status_code}",
            ) from exc
        except httpx.RequestError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Z.AI API is unavailable",
            ) from exc

        data = response.json()
        try:
            content = data["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError) as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Z.AI response has unexpected format",
            ) from exc

        if not isinstance(content, str) or not content.strip():
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Z.AI response content is empty",
            )

        return content

    def _parse_plan_content(self, content: str) -> AIFitnessPlanContent:
        try:
            data = json.loads(_strip_json_fence(content))
            return AIFitnessPlanContent.model_validate(data)
        except (json.JSONDecodeError, ValidationError) as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Z.AI returned a plan that does not match FitTrack schema",
            ) from exc

    def _build_user_prompt(self, payload: AIFitnessPlanRequest) -> str:
        goal_label = GOAL_LABELS[payload.goal]
        return f"""
Create a personalized plan for this user:
- goal: {goal_label}
- weight: {payload.weight_kg} kg
- height: {payload.height_cm} cm
- fitness level: {payload.fitness_level}

Return JSON with this exact structure:
{{
  "summary": "short explanation",
  "workout_plan": {{
    "weekly_schedule": [
      {{
        "day": 1,
        "focus": "full body strength",
        "duration_minutes": 45,
        "warm_up": ["5 min treadmill", "dynamic shoulder circles"],
        "exercises": [
          {{
            "name": "Goblet squat",
            "muscle_group": "legs",
            "equipment": "dumbbell",
            "sets": 3,
            "reps": "10-12",
            "rest_seconds": 90,
            "technique_tip": "Keep chest tall and knees tracking over toes."
          }}
        ],
        "cooldown": ["hamstring stretch", "deep breathing"]
      }}
    ],
    "progression": ["how to progress week by week"]
  }},
  "nutrition_recommendations": {{
    "calories_per_day": 2200,
    "protein_g": 150,
    "fats_g": 70,
    "carbs_g": 240,
    "meals_per_day": 4,
    "hydration_liters": 2.5,
    "recommendations": ["practical food guidance"]
  }},
  "safety_notes": ["stop if pain appears", "consult a doctor for medical limitations"]
}}
""".strip()


def _strip_json_fence(content: str) -> str:
    stripped = content.strip()
    if stripped.startswith("```"):
        lines = stripped.splitlines()
        if lines and lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].startswith("```"):
            lines = lines[:-1]
        stripped = "\n".join(lines).strip()
    return stripped
