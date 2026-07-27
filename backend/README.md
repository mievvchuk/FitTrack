# FitTrack Backend

FastAPI backend skeleton for FitTrack with Firebase Authentication verification and role-based access control.

## Run locally

```bash
pip install -r requirements.txt
alembic -c alembic.ini upgrade head
uvicorn app.main:app --reload
```

Required environment variables:

- `DATABASE_URL`: PostgreSQL connection string.
- `FIREBASE_PROJECT_ID`: Firebase project id when using Application Default Credentials.
- `STRIPE_SECRET_KEY`: Stripe test secret key. Must start with `sk_test_`.
- `STRIPE_WEBHOOK_SECRET`: Stripe test webhook signing secret.
- `STRIPE_SUCCESS_URL`: Checkout success redirect URL.
- `STRIPE_CANCEL_URL`: Checkout cancel redirect URL.
- `JWT_SECRET_KEY`: long random secret for FitTrack access JWT and refresh token digests.
- `RATE_LIMIT_STORAGE_URI`: use `redis://...` in production.
- `ENFORCE_HTTPS`: set `true` in production behind HTTPS-aware proxy setup.
- `ALLOWED_HOSTS`: trusted host allowlist.
- `ALLOWED_ORIGINS`: CORS origin allowlist.
- `NOTIFICATIONS_ENABLED`: enables Firebase Cloud Messaging sends.
- `FCM_DRY_RUN`: validates FCM payloads without delivering messages when `true`.
- `ZAI_API_KEY`: backend-only Z.AI API key for AI Fitness Assistant.
- `ZAI_BASE_URL`: Z.AI base URL, default `https://api.z.ai/api/paas/v4`.
- `ZAI_CHAT_MODEL`: chat model, default `glm-5.2`.
- `ZAI_TIMEOUT_SECONDS`: outbound Z.AI request timeout.

## Docker

From the repository root:

```bash
cp .env.example .env
docker compose up --build
```

The backend container runs Alembic automatically when `RUN_MIGRATIONS=true`.
The API is available at `http://127.0.0.1:8000`, and OpenAPI docs are available at `http://127.0.0.1:8000/docs`.
If Docker Compose v2 is unavailable, use `docker-compose up --build`.

Useful Docker commands:

```bash
docker compose ps
docker compose logs -f api
docker compose exec postgres psql -U fittrack -d fittrack
docker compose down
```

See `docs/docker_setup_ua.md` for the full Ukrainian launch guide.

## Migrations

```bash
alembic -c alembic.ini upgrade head
alembic -c alembic.ini current
alembic -c alembic.ini history
```

The initial migration applies `database/course_schema.sql`.

## RBAC

Users authenticate with Firebase. The backend verifies the Firebase ID token, finds the local `users` row by `firebase_uid`, then checks permissions from:

`users -> user_roles -> roles -> role_permissions -> permissions`

Default role on `/api/v1/auth/sync-user` is `user`.

## Premium payments

The Premium flow uses Stripe Checkout in test mode only:

- `GET /api/v1/subscription/plans`
- `POST /api/v1/subscription/checkout-session`
- `POST /api/v1/subscription/checkout-session/{session_id}/confirm`
- `POST /api/v1/subscription/payments/{payment_id}/confirm-test`
- `GET /api/v1/subscription/payments`
- `POST /api/v1/subscription/webhook/stripe`

The backend rejects non-test Stripe secret keys and never stores card data.

## AI Fitness Assistant

The AI Assistant flow uses Z.AI Chat Completions from the backend only:

- `POST /api/v1/ai-assistant/plans`
- `GET /api/v1/ai-assistant/plans`
- `GET /api/v1/ai-assistant/plans/{plan_id}`

The mobile app sends user inputs to FitTrack API. The backend validates them, checks `ai:generate`, calls Z.AI with JSON mode, validates the model response, and stores the generated plan in PostgreSQL.

## Analytics

The analytics dashboard reads existing `workouts`, `progress`, and `meals` data:

- `GET /api/v1/analytics/dashboard?days=30`

The endpoint requires `analytics:read` and returns summary metrics plus chart series for weight, workouts, training volume, calories, and recent activity.

## Production security

Implemented security layers:

- JWT access tokens and rotating refresh tokens.
- Argon2id password hashing.
- Email verification tokens.
- FastAPI/Pydantic request validation.
- SlowAPI rate limiting.
- RBAC permission dependencies.
- Security headers, TrustedHost, CORS, optional HTTPS redirect.
