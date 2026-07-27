from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "FitTrack API"
    api_v1_prefix: str = "/api/v1"
    database_url: str = "postgresql+psycopg://fittrack:fittrack@localhost:5432/fittrack"
    firebase_project_id: str | None = None
    stripe_secret_key: str | None = None
    stripe_webhook_secret: str | None = None
    stripe_success_url: str = "fittrack://payment-success?session_id={CHECKOUT_SESSION_ID}"
    stripe_cancel_url: str = "fittrack://payment-cancel"
    premium_price_cents: int = 999
    premium_currency: str = "usd"
    jwt_secret_key: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_issuer: str = "fittrack-api"
    jwt_audience: str = "fittrack-mobile"
    jwt_access_token_minutes: int = 15
    jwt_refresh_token_days: int = 30
    email_verification_token_minutes: int = 60
    max_failed_login_attempts: int = 5
    account_lockout_minutes: int = 15
    rate_limit_default: str = "100/minute"
    rate_limit_auth: str = "5/minute"
    rate_limit_storage_uri: str = "memory://"
    allowed_origins: list[str] = ["http://localhost", "http://127.0.0.1"]
    allowed_hosts: list[str] = ["localhost", "127.0.0.1", "10.0.2.2", "testserver"]
    enforce_https: bool = False
    notifications_enabled: bool = True
    fcm_dry_run: bool = False
    zai_api_key: str | None = None
    zai_base_url: str = "https://api.z.ai/api/paas/v4"
    zai_chat_model: str = "glm-5.2"
    zai_timeout_seconds: float = 30.0

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
