from uuid import UUID

from fastapi import APIRouter, Depends, Header, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.security import get_current_user, require_permission
from app.db.session import get_db
from app.models.payments import Payment
from app.models.rbac import User
from app.schemas.payments import (
    CheckoutSessionRead,
    CreateCheckoutSessionRequest,
    PaymentHistoryRead,
    PaymentRead,
    SubscriptionPlanRead,
    SubscriptionRead,
)
from app.services.notification_service import NotificationService
from app.services.payment_service import (
    apply_stripe_webhook_event,
    confirm_checkout_session,
    confirm_test_payment,
    construct_webhook_event,
    create_checkout_session,
    get_or_create_subscription,
    get_user_payment,
    list_payment_history,
    list_user_payments,
    premium_plans,
)

router = APIRouter(prefix="/subscription", tags=["Subscription"])


@router.get("/plans", response_model=list[SubscriptionPlanRead])
def plans(settings: Settings = Depends(get_settings)) -> list[dict[str, object]]:
    return premium_plans(settings)


@router.get("/me", response_model=SubscriptionRead)
def my_subscription(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> object:
    subscription = get_or_create_subscription(db, current_user)
    db.commit()
    db.refresh(subscription)
    return subscription


@router.post("/checkout-session", response_model=CheckoutSessionRead)
def create_premium_checkout(
    payload: CreateCheckoutSessionRequest,
    current_user: User = Depends(require_permission("premium:pay")),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict[str, object]:
    payment = create_checkout_session(
        db=db,
        user=current_user,
        settings=settings,
        success_url=payload.success_url,
        cancel_url=payload.cancel_url,
    )
    return {
        "payment_id": payment.id,
        "stripe_checkout_session_id": payment.stripe_checkout_session_id,
        "checkout_url": payment.stripe_checkout_url,
        "status": payment.status,
        "amount_cents": payment.amount_cents,
        "currency": payment.currency,
    }


@router.post("/checkout-session/{stripe_checkout_session_id}/confirm", response_model=PaymentRead)
def confirm_premium_checkout(
    stripe_checkout_session_id: str,
    current_user: User = Depends(require_permission("premium:pay")),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> object:
    payment = confirm_checkout_session(db, current_user, settings, stripe_checkout_session_id)
    _send_payment_notification_safely(db, settings, current_user, payment)
    return payment


@router.post("/payments/{payment_id}/confirm-test", response_model=PaymentRead)
def confirm_manual_test_payment(
    payment_id: UUID,
    current_user: User = Depends(require_permission("premium:pay")),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> object:
    payment = confirm_test_payment(db, current_user, payment_id)
    _send_payment_notification_safely(db, settings, current_user, payment)
    return payment


@router.get("/payments", response_model=list[PaymentRead])
def my_payments(
    current_user: User = Depends(require_permission("premium:pay")),
    db: Session = Depends(get_db),
) -> list[object]:
    return list_user_payments(db, current_user)


@router.get("/payments/{payment_id}", response_model=PaymentRead)
def payment_status(
    payment_id: UUID,
    current_user: User = Depends(require_permission("premium:pay")),
    db: Session = Depends(get_db),
) -> object:
    return get_user_payment(db, current_user, payment_id)


@router.get("/payments/{payment_id}/history", response_model=list[PaymentHistoryRead])
def payment_events(
    payment_id: UUID,
    current_user: User = Depends(require_permission("premium:pay")),
    db: Session = Depends(get_db),
) -> list[object]:
    return list_payment_history(db, current_user, payment_id)


@router.post("/webhook/stripe", status_code=status.HTTP_200_OK)
async def stripe_webhook(
    request: Request,
    stripe_signature: str | None = Header(default=None, alias="Stripe-Signature"),
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> dict[str, bool]:
    payload = await request.body()
    event = construct_webhook_event(settings, payload, stripe_signature)
    payment = apply_stripe_webhook_event(db, event)
    if payment is not None:
        user = db.scalar(select(User).where(User.id == payment.user_id))
        if user is not None:
            _send_payment_notification_safely(db, settings, user, payment)
    return {"received": True}


def _send_payment_notification_safely(
    db: Session,
    settings: Settings,
    user: User,
    payment: Payment,
) -> None:
    try:
        NotificationService(db, settings).send_payment_notification(
            user,
            payment_id=str(payment.id),
            status=str(payment.status),
        )
    except Exception:
        # Payment state is more important than a non-critical push failure.
        return
