from collections.abc import Callable
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth as firebase_auth
from jwt import InvalidTokenError
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.config import Settings, get_settings
from app.db.session import get_db
from app.models.rbac import Role, User
from app.services.auth_security_service import decode_access_token, get_user_id_from_claims
from app.services.rbac_service import permission_codes, role_codes

bearer_scheme = HTTPBearer(auto_error=True)


async def get_firebase_claims(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict[str, object]:
    try:
        return firebase_auth.verify_id_token(credentials.credentials)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired Firebase token",
        ) from exc


def _user_query():
    return select(User).options(selectinload(User.roles).selectinload(Role.permissions))


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> User:
    token = credentials.credentials

    user = _get_user_from_fittrack_jwt(token, db, settings)
    if user is not None:
        return user

    user = _get_user_from_firebase_token(token, db)
    if user is not None:
        return user

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired authentication token",
    )


def _get_user_from_fittrack_jwt(
    token: str,
    db: Session,
    settings: Settings,
) -> User | None:
    try:
        payload = decode_access_token(token, settings)
        user_id = get_user_id_from_claims(payload)
    except (InvalidTokenError, ValueError, TypeError):
        return None

    return db.scalar(
        _user_query().where(
            User.id == user_id,
            User.is_active.is_(True),
        )
    )


def _get_user_from_firebase_token(token: str, db: Session) -> User | None:
    try:
        claims = firebase_auth.verify_id_token(token)
    except Exception:
        return None

    firebase_uid = claims.get("uid")
    if not firebase_uid:
        return None

    return db.scalar(
        _user_query().where(
            User.firebase_uid == str(firebase_uid),
            User.is_active.is_(True),
        )
    )


def require_role(*allowed_roles: str) -> Callable[[User], User]:
    def dependency(current_user: User = Depends(get_current_user)) -> User:
        if set(role_codes(current_user)).intersection(allowed_roles):
            return current_user
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Required role: {', '.join(allowed_roles)}",
        )

    return dependency


def require_permission(permission_code: str) -> Callable[[User], User]:
    def dependency(current_user: User = Depends(get_current_user)) -> User:
        if permission_code in permission_codes(current_user):
            return current_user
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Missing permission: {permission_code}",
        )

    return dependency
