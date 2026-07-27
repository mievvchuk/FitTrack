from __future__ import annotations

from datetime import datetime, timedelta, timezone
from uuid import UUID

import stripe
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.models.payments import Payment, PaymentHistory, Subscription
from app.models.rbac import User


def premium_plans(settings: Settings) -> list[dict[str, object]]:
    return [
        {
            "code": "free",
            "name": "Free",
            "price_cents": 0,
            "currency": settings.premium_currency.upper(),
            "features": [
                "Exercise library",
                "Basic workouts",
                "Basic progress tracking",
            ],
        },
        {
            "code": "premium",
            "name": "Premium",
            "price_cents": settings.premium_price_cents,
            "currency": settings.premium_currency.upper(),
            "features": [
                "Unlimited workouts",
                "Advanced statistics",
                "Full payment history",
                "Priority trainer programs",
            ],
        },
    ]


def get_or_create_subscription(db: Session, user: User) -> Subscription:
    subscription = db.scalar(
        select(Subscription)
        .where(Subscription.user_id == user.id)
        .order_by(Subscription.created_at.desc())
    )
    if subscription is not None:
        return subscription

    subscription = Subscription(
        user_id=user.id,
        plan="free",
        status="active",
        price_cents=0,
        currency="USD",
    )
    db.add(subscription)
    db.flush()
    return subscription


def create_checkout_session(
    db: Session,
    user: User,
    settings: Settings,
    success_url: str | None = None,
    cancel_url: str | None = None,
) -> Payment:
    _configure_stripe_test_mode(settings)

    subscription = get_or_create_subscription(db, user)
    payment = Payment(
        user_id=user.id,
        subscription_id=subscription.id,
        plan="premium",
        amount_cents=settings.premium_price_cents,
        currency=settings.premium_currency.upper(),
        status="pending",
        provider="stripe",
        mode="test",
        description="FitTrack Premium test checkout",
    )
    db.add(payment)
    db.flush()

    checkout_session = stripe.checkout.Session.create(
        mode="payment",
        success_url=success_url or settings.stripe_success_url,
        cancel_url=cancel_url or settings.stripe_cancel_url,
        client_reference_id=str(user.id),
        customer_email=user.email,
        line_items=[
            {
                "price_data": {
                    "currency": settings.premium_currency.lower(),
                    "unit_amount": settings.premium_price_cents,
                    "product_data": {"name": "FitTrack Premium"},
                },
                "quantity": 1,
            }
        ],
        metadata={
            "payment_id": str(payment.id),
            "user_id": str(user.id),
            "plan": "premium",
            "mode": "test",
        },
    )

    payment.stripe_checkout_session_id = checkout_session.id
    payment.stripe_checkout_url = checkout_session.url
    _add_history(
        db,
        payment,
        old_status=None,
        new_status="pending",
        event_type="checkout_created",
        message="Stripe test Checkout Session created",
    )
    db.commit()
    db.refresh(payment)
    return payment


def confirm_checkout_session(
    db: Session,
    user: User,
    settings: Settings,
    stripe_checkout_session_id: str,
) -> Payment:
    _configure_stripe_test_mode(settings)

    payment = _get_user_payment_by_session(db, user, stripe_checkout_session_id)
    checkout_session = stripe.checkout.Session.retrieve(stripe_checkout_session_id)

    if checkout_session.payment_status == "paid":
        return mark_payment_succeeded(
            db,
            payment,
            event_type="checkout_confirmed",
            stripe_payment_intent_id=checkout_session.payment_intent,
        )

    if checkout_session.status in {"expired", "canceled"}:
        return mark_payment_status(
            db,
            payment,
            new_status="cancelled",
            event_type="checkout_cancelled",
            message="Stripe Checkout Session was cancelled or expired",
        )

    return mark_payment_status(
        db,
        payment,
        new_status="processing",
        event_type="checkout_processing",
        message=f"Stripe payment_status={checkout_session.payment_status}",
    )


def confirm_test_payment(db: Session, user: User, payment_id: UUID) -> Payment:
    payment = _get_user_payment(db, user, payment_id)
    if payment.mode != "test":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only test payments can be manually confirmed",
        )
    return mark_payment_succeeded(
        db,
        payment,
        event_type="manual_test_confirmation",
        message="Manual test confirmation for coursework demo",
    )


def mark_payment_succeeded(
    db: Session,
    payment: Payment,
    event_type: str,
    stripe_payment_intent_id: str | None = None,
    stripe_event_id: str | None = None,
    message: str | None = None,
) -> Payment:
    payment.stripe_payment_intent_id = stripe_payment_intent_id or payment.stripe_payment_intent_id
    payment.paid_at = datetime.now(timezone.utc)
    payment = mark_payment_status(
        db,
        payment,
        new_status="succeeded",
        event_type=event_type,
        stripe_event_id=stripe_event_id,
        message=message or "Payment succeeded in Stripe test mode",
        commit=False,
    )

    subscription = db.get(Subscription, payment.subscription_id) if payment.subscription_id else None
    if subscription is not None:
        subscription.plan = "premium"
        subscription.status = "active"
        subscription.price_cents = payment.amount_cents
        subscription.currency = payment.currency
        subscription.started_at = datetime.now(timezone.utc)
        subscription.expires_at = datetime.now(timezone.utc) + timedelta(days=30)

    db.commit()
    db.refresh(payment)
    return payment


def mark_payment_status(
    db: Session,
    payment: Payment,
    new_status: str,
    event_type: str,
    stripe_event_id: str | None = None,
    message: str | None = None,
    commit: bool = True,
) -> Payment:
    old_status = payment.status
    if old_status != new_status:
        payment.status = new_status
        _add_history(
            db,
            payment,
            old_status=old_status,
            new_status=new_status,
            event_type=event_type,
            stripe_event_id=stripe_event_id,
            message=message,
        )
    if commit:
        db.commit()
        db.refresh(payment)
    return payment


def apply_stripe_webhook_event(db: Session, event: stripe.Event) -> Payment | None:
    event_type = event["type"]
    data_object = event["data"]["object"]

    if event_type == "checkout.session.completed":
        payment = _get_payment_by_session(db, data_object["id"])
        mark_payment_succeeded(
            db,
            payment,
            event_type=event_type,
            stripe_payment_intent_id=data_object.get("payment_intent"),
            stripe_event_id=event["id"],
        )
        return payment

    if event_type == "checkout.session.expired":
        payment = _get_payment_by_session(db, data_object["id"])
        mark_payment_status(
            db,
            payment,
            new_status="cancelled",
            event_type=event_type,
            stripe_event_id=event["id"],
            message="Stripe Checkout Session expired",
        )
        return payment

    return None


def construct_webhook_event(settings: Settings, payload: bytes, signature: str | None) -> stripe.Event:
    _configure_stripe_test_mode(settings)

    if not settings.stripe_webhook_secret:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="STRIPE_WEBHOOK_SECRET is not configured",
        )
    if not signature:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Stripe-Signature header is required",
        )

    try:
        return stripe.Webhook.construct_event(
            payload,
            signature,
            settings.stripe_webhook_secret,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid Stripe payload") from exc
    except Exception as exc:
        if exc.__class__.__name__ == "SignatureVerificationError":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid Stripe signature",
            ) from exc
        raise


def list_user_payments(db: Session, user: User) -> list[Payment]:
    return list(
        db.scalars(
            select(Payment)
            .where(Payment.user_id == user.id)
            .order_by(Payment.created_at.desc())
        )
    )


def get_user_payment(db: Session, user: User, payment_id: UUID) -> Payment:
    return _get_user_payment(db, user, payment_id)


def list_payment_history(db: Session, user: User, payment_id: UUID) -> list[PaymentHistory]:
    payment = _get_user_payment(db, user, payment_id)
    return list(
        db.scalars(
            select(PaymentHistory)
            .where(PaymentHistory.payment_id == payment.id)
            .order_by(PaymentHistory.created_at.desc())
        )
    )


def _configure_stripe_test_mode(settings: Settings) -> None:
    if not settings.stripe_secret_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="STRIPE_SECRET_KEY is not configured",
        )
    if not settings.stripe_secret_key.startswith("sk_test_"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only Stripe test keys are allowed in this coursework project",
        )
    stripe.api_key = settings.stripe_secret_key


def _get_user_payment(db: Session, user: User, payment_id: UUID) -> Payment:
    payment = db.scalar(
        select(Payment).where(Payment.id == payment_id, Payment.user_id == user.id)
    )
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    return payment


def _get_user_payment_by_session(db: Session, user: User, session_id: str) -> Payment:
    payment = db.scalar(
        select(Payment).where(
            Payment.stripe_checkout_session_id == session_id,
            Payment.user_id == user.id,
        )
    )
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    return payment


def _get_payment_by_session(db: Session, session_id: str) -> Payment:
    payment = db.scalar(select(Payment).where(Payment.stripe_checkout_session_id == session_id))
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    return payment


def _add_history(
    db: Session,
    payment: Payment,
    old_status: str | None,
    new_status: str,
    event_type: str,
    stripe_event_id: str | None = None,
    message: str | None = None,
) -> None:
    db.add(
        PaymentHistory(
            payment_id=payment.id,
            user_id=payment.user_id,
            old_status=old_status,
            new_status=new_status,
            event_type=event_type,
            provider="stripe",
            mode="test",
            stripe_event_id=stripe_event_id,
            message=message,
        )
    )
