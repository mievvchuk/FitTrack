from uuid import UUID

from fastapi import APIRouter, Depends, Query, Request, status
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.rate_limit import limiter
from app.core.security import require_permission
from app.db.session import get_db
from app.models.rbac import User
from app.schemas.ai_assistant import AIFitnessPlanRead, AIFitnessPlanRequest
from app.services.ai_assistant_service import AIFitnessAssistantService

router = APIRouter(prefix="/ai-assistant", tags=["AI Fitness Assistant"])


@router.post(
    "/plans",
    response_model=AIFitnessPlanRead,
    status_code=status.HTTP_201_CREATED,
)
@limiter.limit("5/minute")
def generate_ai_fitness_plan(
    request: Request,
    payload: AIFitnessPlanRequest,
    current_user: User = Depends(require_permission("ai:generate")),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> object:
    return AIFitnessAssistantService(db, settings).generate_plan(current_user, payload)


@router.get("/plans", response_model=list[AIFitnessPlanRead])
def list_ai_fitness_plans(
    limit: int = Query(default=20, ge=1, le=50),
    current_user: User = Depends(require_permission("ai:generate")),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> list[object]:
    return AIFitnessAssistantService(db, settings).list_user_plans(
        current_user,
        limit=limit,
    )


@router.get("/plans/{plan_id}", response_model=AIFitnessPlanRead)
def get_ai_fitness_plan(
    plan_id: UUID,
    current_user: User = Depends(require_permission("ai:generate")),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> object:
    return AIFitnessAssistantService(db, settings).get_user_plan(current_user, plan_id)
