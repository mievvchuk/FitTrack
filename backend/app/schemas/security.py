from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.schemas.rbac import CurrentUserRead


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=12, max_length=128)
    display_name: str | None = Field(default=None, max_length=120)

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, value: str) -> str:
        has_upper = any(char.isupper() for char in value)
        has_lower = any(char.islower() for char in value)
        has_digit = any(char.isdigit() for char in value)
        has_symbol = any(not char.isalnum() for char in value)
        if not all((has_upper, has_lower, has_digit, has_symbol)):
            raise ValueError("Password must contain uppercase, lowercase, digit, and symbol")
        return value


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)
    device_id: str | None = Field(default=None, max_length=120)


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(min_length=32)
    device_id: str | None = Field(default=None, max_length=120)


class LogoutRequest(BaseModel):
    refresh_token: str = Field(min_length=32)


class EmailVerificationRequest(BaseModel):
    token: str = Field(min_length=32)


class RequestEmailVerificationRequest(BaseModel):
    email: EmailStr


class AuthTokenRead(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int
    user: CurrentUserRead


class EmailVerificationCreatedRead(BaseModel):
    user_id: UUID
    email: EmailStr
    expires_in_minutes: int
    verification_token_demo: str
