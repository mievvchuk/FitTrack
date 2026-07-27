# FitTrack - Premium та тестові платежі Stripe

## 1. Тарифи

| Тариф | Вартість | Можливості |
| --- | --- | --- |
| `free` | 0 USD | бібліотека вправ, базові тренування, базовий прогрес |
| `premium` | 9.99 USD у test mode | необмежені тренування, розширена статистика, історія платежів, тренерські програми |

## 2. Безпека платежів

- FitTrack використовує тільки Stripe test API.
- Backend приймає лише ключі, що починаються з `sk_test_`.
- Реальні банківські картки не зберігаються у PostgreSQL.
- Карткові дані вводяться тільки на Stripe-hosted Checkout сторінці.
- У базі зберігаються лише `stripe_checkout_session_id`, `stripe_payment_intent_id`, checkout URL, статус, сума та історія статусів.

## 3. Database

### `subscriptions`

Зберігає поточний тариф користувача:

- `plan`: `free` або `premium`;
- `status`: `active`, `trialing`, `past_due`, `cancelled`, `expired`;
- `price_cents`, `currency`;
- `started_at`, `expires_at`, `cancelled_at`;
- Stripe identifiers без карткових даних.

### `payments`

Зберігає одну спробу оплати:

- `plan`: тариф, за який створено платіж;
- `amount_cents`, `currency`;
- `status`: `pending`, `processing`, `succeeded`, `failed`, `cancelled`, `refunded`;
- `provider = stripe`;
- `mode = test`;
- `stripe_checkout_session_id`;
- `stripe_payment_intent_id`;
- `stripe_checkout_url`;
- `paid_at`.

### `payment_history`

Аудит зміни статусів платежу:

- `payment_id`;
- `old_status`;
- `new_status`;
- `event_type`;
- `stripe_event_id`;
- `message`;
- `created_at`.

## 4. Backend API

| Method | Endpoint | Auth | Опис |
| --- | --- | --- | --- |
| GET | `/api/v1/subscription/plans` | Firebase token | Free/Premium тарифи |
| GET | `/api/v1/subscription/me` | Firebase token | Поточний тариф користувача |
| POST | `/api/v1/subscription/checkout-session` | `premium:pay` | Створити Stripe Checkout Session у test mode |
| POST | `/api/v1/subscription/checkout-session/{session_id}/confirm` | `premium:pay` | Перевірити статус Stripe Checkout Session |
| POST | `/api/v1/subscription/payments/{payment_id}/confirm-test` | `premium:pay` | Ручне тестове підтвердження для демо |
| GET | `/api/v1/subscription/payments` | `premium:pay` | Історія платежів користувача |
| GET | `/api/v1/subscription/payments/{payment_id}` | `premium:pay` | Статус конкретного платежу |
| GET | `/api/v1/subscription/payments/{payment_id}/history` | `premium:pay` | Історія зміни статусів платежу |
| POST | `/api/v1/subscription/webhook/stripe` | Stripe signature | Webhook для `checkout.session.completed` та `checkout.session.expired` |
| GET | `/api/v1/admin/payments` | `payments:read` | Admin перегляд останніх платежів |

## 5. Payment flow

```text
Flutter Premium Screen
  -> POST /subscription/checkout-session
  -> Backend creates Payment(status=pending)
  -> Backend creates Stripe Checkout Session
  -> Flutter opens checkout_url externally
  -> Stripe test payment succeeds
  -> Stripe webhook calls /subscription/webhook/stripe
  -> Backend updates Payment(status=succeeded)
  -> Backend activates Subscription(plan=premium)
  -> Flutter shows Payment success and Payment history
```

Для локального захисту курсової без Stripe CLI можна використати:

```text
POST /api/v1/subscription/payments/{payment_id}/confirm-test
```

Цей endpoint працює тільки з `mode = test`.

## 6. Environment variables

```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_SUCCESS_URL=fittrack://payment-success?session_id={CHECKOUT_SESSION_ID}
STRIPE_CANCEL_URL=fittrack://payment-cancel
PREMIUM_PRICE_CENTS=999
PREMIUM_CURRENCY=usd
```
