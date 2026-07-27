from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.security import require_permission
from app.db.session import get_db
from app.models.rbac import User
from app.schemas.analytics import AnalyticsDashboardRead
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/dashboard", response_model=AnalyticsDashboardRead)
def analytics_dashboard(
    days: int = Query(default=30, ge=7, le=365),
    current_user: User = Depends(require_permission("analytics:read")),
    db: Session = Depends(get_db),
) -> dict[str, object]:
    return AnalyticsService(db).dashboard(current_user, days)
