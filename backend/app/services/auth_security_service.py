from __future__ import annotations

import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from uuid import UUID

import jwt
from fastapi import HTTPException, Request, status
from jwt import InvalidTokenError
from pwdlib import PasswordHash
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.config import Settings
from app.models.rbac import Role, User
from app.models.security import EmailVerificationToken, RefreshToken
from app.services.rbac_service import current_user_payload, permission_codes, role_codes

password_hasher = PasswordHash.recommended()


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return password_hasher.verify(password, password_hash)


def register_password_user(
    db: Session,
    settings: Settings,
    email: str,
    password: str,
) -> tuple[User, str]:
    existing_user = db.scalar(select(User).where(User.email == email.lower()))
    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email is already registered",
        )

    default_role = db.scalar(select(Role).where(Role.code == "user"))
    if default_role is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Default user role is not configured",
        )

    user = User(
        firebase_uid=f"local:{secrets.token_urlsafe(24)}",
        email=email.lower(),
        auth_provider="email_password",
        password_hash=hash_password(password),
        roles=[default_role],
    )
    db.add(user)
    db.flush()

    verification_token = create_email_verification_token(db, user, settings)
    db.commit()
    db.refresh(user)
    return user, verification_token


def authenticate_password_user(
    db: Session,
    settings: Settings,
    email: str,
    password: str,
) -> User:
    user = db.scalar(
        select(User)
        .options(selectinload(User.roles).selectinload(Role.permissions))
        .where(User.email == email.lower(), User.is_active.is_(True))
    )
    if user is None or user.password_hash is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    now = datetime.now(timezone.utc)
    if user.locked_until and user.locked_until > now:
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail="Account is temporarily locked",
        )

    if not verify_password(password, user.password_hash):
        user.failed_login_attempts += 1
        if user.failed_login_attempts >= settings.max_failed_login_attempts:
            user.locked_until = now + timedelta(minutes=settings.account_lockout_minutes)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    if user.email_verified_at is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Email address is not verified",
        )

    user.failed_login_attempts = 0
    user.locked_until = None
    user.last_login_at = now
    db.commit()
    db.refresh(user)
    return user


def issue_token_pair(
    db: Session,
    user: User,
    settings: Settings,
    request: Request | None = None,
    device_id: str | None = None,
) -> dict[str, object]:
    refresh_token = secrets.token_urlsafe(64)
    refresh_expires_at = datetime.now(timezone.utc) + timedelta(
        days=settings.jwt_refresh_token_days
    )

    db.add(
        RefreshToken(
            user_id=user.id,
            token_hash=token_digest(refresh_token, settings),
            device_id=device_id,
            user_agent=request.headers.get("user-agent") if request else None,
            ip_address=request.client.host if request and request.client else None,
            expires_at=refresh_expires_at,
        )
    )

    access_token = create_access_token(user, settings)
    db.commit()

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "Bearer",
        "expires_in": settings.jwt_access_token_minutes * 60,
        "user": current_user_payload(user),
    }


def refresh_token_pair(
    db: Session,
    settings: Settings,
    refresh_token: str,
    request: Request | None = None,
    device_id: str | None = None,
) -> dict[str, object]:
    stored_token = _get_active_refresh_token(db, settings, refresh_token)
    user = db.scalar(
        select(User)
        .options(selectinload(User.roles).selectinload(Role.permissions))
        .where(User.id == stored_token.user_id, User.is_active.is_(True))
    )
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    stored_token.revoked_at = datetime.now(timezone.utc)
    stored_token.last_used_at = datetime.now(timezone.utc)
    return issue_token_pair(db, user, settings, request, device_id=device_id)


def revoke_refresh_token(db: Session, settings: Settings, refresh_token: str) -> None:
    stored_token = _get_active_refresh_token(db, settings, refresh_token)
    stored_token.revoked_at = datetime.now(timezone.utc)
    db.commit()


def create_access_token(user: User, settings: Settings) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "iss": settings.jwt_issuer,
        "aud": settings.jwt_audience,
        "sub": str(user.id),
        "email": user.email,
        "roles": role_codes(user),
        "permissions": permission_codes(user),
        "token_version": user.token_version,
        "type": "access",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=settings.jwt_access_token_minutes)).timestamp()),
        "jti": secrets.token_urlsafe(16),
    }
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str, settings: Settings) -> dict[str, object]:
    payload = jwt.decode(
        token,
        settings.jwt_secret_key,
        algorithms=[settings.jwt_algorithm],
        audience=settings.jwt_audience,
        issuer=settings.jwt_issuer,
    )
    if payload.get("type") != "access":
        raise InvalidTokenError("Invalid token type")
    return payload


def token_digest(token: str, settings: Settings) -> str:
    return hmac.new(
        settings.jwt_secret_key.encode("utf-8"),
        token.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def create_email_verification_token(db: Session, user: User, settings: Settings) -> str:
    token = secrets.token_urlsafe(48)
    db.add(
        EmailVerificationToken(
            user_id=user.id,
            token_hash=token_digest(token, settings),
            expires_at=datetime.now(timezone.utc)
            + timedelta(minutes=settings.email_verification_token_minutes),
        )
    )
    return token


def request_email_verification(
    db: Session,
    settings: Settings,
    email: str,
) -> tuple[User, str]:
    user = db.scalar(select(User).where(User.email == email.lower(), User.is_active.is_(True)))
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if user.email_verified_at is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email is already verified")

    token = create_email_verification_token(db, user, settings)
    db.commit()
    return user, token


def verify_email_token(db: Session, settings: Settings, token: str) -> User:
    token_hash = token_digest(token, settings)
    verification_token = db.scalar(
        select(EmailVerificationToken).where(
            EmailVerificationToken.token_hash == token_hash,
            EmailVerificationToken.consumed_at.is_(None),
        )
    )
    if verification_token is None or verification_token.expires_at < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired verification token",
        )

    user = db.scalar(
        select(User)
        .options(selectinload(User.roles).selectinload(Role.permissions))
        .where(User.id == verification_token.user_id)
    )
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    verification_token.consumed_at = datetime.now(timezone.utc)
    user.email_verified_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user)
    return user


def _get_active_refresh_token(
    db: Session,
    settings: Settings,
    refresh_token: str,
) -> RefreshToken:
    stored_token = db.scalar(
        select(RefreshToken).where(
            RefreshToken.token_hash == token_digest(refresh_token, settings),
            RefreshToken.revoked_at.is_(None),
        )
    )
    if stored_token is None or stored_token.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")
    return stored_token


def get_user_id_from_claims(payload: dict[str, object]) -> UUID:
    subject = payload.get("sub")
    if not subject:
        raise InvalidTokenError("Missing subject")
    return UUID(str(subject))
