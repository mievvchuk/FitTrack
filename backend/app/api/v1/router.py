from fastapi import APIRouter

from app.api.v1 import ai_assistant, analytics, auth, notifications, roles, subscription

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(roles.router)
api_router.include_router(subscription.router)
api_router.include_router(notifications.router)
api_router.include_router(ai_assistant.router)
api_router.include_router(analytics.router)
