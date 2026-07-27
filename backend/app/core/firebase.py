import firebase_admin
from firebase_admin import credentials

from app.core.config import get_settings


def initialize_firebase() -> None:
    if firebase_admin._apps:
        return

    settings = get_settings()

    if settings.firebase_project_id:
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(
            cred,
            {"projectId": settings.firebase_project_id},
        )
        return

    firebase_admin.initialize_app()
