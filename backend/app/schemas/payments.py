from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class SubscriptionPlanRead(BaseModel):
    code: str
    name: str
    price_cents: int
    currency: str
    features: list[str]


class SubscriptionRead(BaseModel):
    id: UUID
    plan: str
    status: str
    price_cents: int
    currency: str
    started_at: datetime
    expires_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


class CreateCheckoutSessionRequest(BaseModel):
    success_url: str | None = Field(
        default=None,
        description="Deep link or web URL used only for Stripe test Checkout redirect.",
    )
    cancel_url: str | None = None


class CheckoutSessionRead(BaseModel):
    payment_id: UUID
    stripe_checkout_session_id: str
    checkout_url: HttpUrl
    status: str
    amount_cents: int
    currency: str


class PaymentRead(BaseModel):
    id: UUID
    subscription_id: UUID | None = None
    plan: str
    amount_cents: int
    currency: str
    status: str
    provider: str
    mode: str
    stripe_payment_intent_id: str | None = None
    stripe_checkout_session_id: str | None = None
    stripe_checkout_url: str | None = None
    description: str | None = None
    paid_at: datetime | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PaymentHistoryRead(BaseModel):
    id: UUID
    payment_id: UUID
    old_status: str | None = None
    new_status: str
    event_type: str
    provider: str
    mode: str
    stripe_event_id: str | None = None
    message: str | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
