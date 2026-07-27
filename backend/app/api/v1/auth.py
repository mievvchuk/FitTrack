from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.config import Settings, get_settings
from app.core.rate_limit import limiter
from app.core.security import get_current_user, get_firebase_claims
from app.db.session import get_db
from app.models.rbac import Role, User
from app.schemas.rbac import CurrentUserRead, SyncUserRequest
from app.schemas.security import (
    AuthTokenRead,
    EmailVerificationCreatedRead,
    EmailVerificationRequest,
    LoginRequest,
    LogoutRequest,
    RefreshTokenRequest,
    RegisterRequest,
    RequestEmailVerificationRequest,
)
from app.services.auth_security_service import (
    authenticate_password_user,
    issue_token_pair,
    refresh_token_pair,
    register_password_user,
    request_email_verification,
    revoke_refresh_token,
    verify_email_token,
)
from app.services.rbac_service import current_user_payload

router = APIRouter(prefix="/auth", tags=["Auth"])


def _user_with_roles(firebase_uid: str):
    return (
        select(User)
        .options(selectinload(User.roles).selectinload(Role.permissions))
        .where(User.firebase_uid == firebase_uid)
    )


@router.post(
    "/register",
    response_model=EmailVerificationCreatedRead,
    status_code=status.HTTP_201_CREATED,
)
@limiter.limit("3/minute")
def register(
    request: Request,
    payload: RegisterRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict[str, object]:
    user, verification_token = register_password_user(
        db=db,
        settings=settings,
        email=payload.email,
        password=payload.password,
    )
    return {
        "user_id": user.id,
        "email": user.email,
        "expires_in_minutes": settings.email_verification_token_minutes,
        "verification_token_demo": verification_token,
    }


@router.post("/verify-email", response_model=CurrentUserRead)
@limiter.limit("10/minute")
def verify_email(
    request: Request,
    payload: EmailVerificationRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict[str, object]:
    user = verify_email_token(db, settings, payload.token)
    return current_user_payload(user)


@router.post("/request-email-verification", response_model=EmailVerificationCreatedRead)
@limiter.limit("3/minute")
def request_verification(
    request: Request,
    payload: RequestEmailVerificationRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict[str, object]:
    user, verification_token = request_email_verification(db, settings, payload.email)
    return {
        "user_id": user.id,
        "email": user.email,
        "expires_in_minutes": settings.email_verification_token_minutes,
        "verification_token_demo": verification_token,
    }


@router.post("/login", response_model=AuthTokenRead)
@limiter.limit("5/minute")
def login(
    request: Request,
    payload: LoginRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict[str, object]:
    user = authenticate_password_user(db, settings, payload.email, payload.password)
    return issue_token_pair(
        db,
        user,
        settings,
        request=request,
        device_id=payload.device_id,
    )


@router.post("/refresh", response_model=AuthTokenRead)
@limiter.limit("10/minute")
def refresh(
    request: Request,
    payload: RefreshTokenRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict[str, object]:
    return refresh_token_pair(
        db,
        settings,
        payload.refresh_token,
        request=request,
        device_id=payload.device_id,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(
    payload: LogoutRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> None:
    revoke_refresh_token(db, settings, payload.refresh_token)


@router.post("/sync-user", response_model=CurrentUserRead)
def sync_user(
    payload: SyncUserRequest,
    claims: dict[str, object] = Depends(get_firebase_claims),
    db: Session = Depends(get_db),
) -> dict[str, object]:
    firebase_uid = claims.get("uid")
    email = claims.get("email") or payload.email

    if not firebase_uid or not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Firebase uid and email are required",
        )

    user = db.scalar(_user_with_roles(str(firebase_uid)))
    if user is None:
        default_role = db.scalar(select(Role).where(Role.code == "user"))
        if default_role is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Default user role is not configured",
            )

        firebase_claim = claims.get("firebase")
        sign_in_provider = (
            firebase_claim.get("sign_in_provider")
            if isinstance(firebase_claim, dict)
            else None
        )

        user = User(
            firebase_uid=str(firebase_uid),
            email=str(email),
            auth_provider="google"
            if sign_in_provider == "google.com"
            else "email_password",
            email_verified_at=datetime.now(timezone.utc)
            if claims.get("email_verified") is True
            else None,
            roles=[default_role],
        )
        db.add(user)
    else:
        user.email = str(email)
        if claims.get("email_verified") is True and user.email_verified_at is None:
            user.email_verified_at = datetime.now(timezone.utc)

    db.commit()
    user = db.scalar(_user_with_roles(str(firebase_uid)))
    return current_user_payload(user)


@router.get("/me", response_model=CurrentUserRead)
def me(current_user: User = Depends(get_current_user)) -> dict[str, object]:
    return current_user_payload(current_user)
