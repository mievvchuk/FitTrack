# FitTrack

FitTrack is a 4th-year coursework project: a cross-platform mobile application for personal workouts, progress tracking, nutrition tracking, role-based coaching/admin workflows, and Premium test payments.

The project demonstrates a full mobile + backend architecture:

- Flutter mobile app for Android and iOS.
- Python FastAPI backend.
- PostgreSQL relational database.
- Firebase Authentication.
- FitTrack JWT access/refresh token security layer.
- Role-based access control.
- Stripe test API for Premium payments.

> This is an educational coursework project. Stripe integration is test-mode only. FitTrack does not store real bank cards, card numbers, CVV, or payment credentials.

## Main Features

- Email/password registration and login.
- Google Sign-In through Firebase.
- Password reset and password change through Firebase.
- Backend JWT login flow with refresh token rotation.
- Email verification tokens.
- Face ID / Touch ID local unlock.
- User profile with age, gender, height, weight, and training goal.
- Exercise library with media, technique, muscle group, equipment, and difficulty.
- Workout builder with exercises, sets, reps, weight, and rest time.
- Progress tracking and workout history.
- Analytics dashboard with workouts, weight, calories, progress, and activity charts.
- Nutrition tracking: calories, protein, fats, carbohydrates.
- Premium subscription with Stripe test checkout.
- Payment status and payment history.
- AI Fitness Assistant for workout and nutrition plan generation.
- Roles: `User`, `Trainer`, `Admin`.
- Permissions and backend access checks.
- Production-oriented API security layer.

## User Roles

| Role | Capabilities |
| --- | --- |
| `User` | Completes workouts, views exercises, tracks progress, manages nutrition, pays for Premium |
| `Trainer` | Creates training programs, adds exercises, views assigned clients |
| `Admin` | Manages users, edits exercises, reviews payments |

## Tech Stack

### Mobile

- Flutter
- Riverpod
- GoRouter
- Dio
- Firebase Auth
- Google Sign-In
- Local Auth
- Flutter Secure Storage
- Flutter Localizations / ARB
- URL Launcher

### Backend

- Python FastAPI
- SQLAlchemy
- PostgreSQL / psycopg
- Firebase Admin SDK
- Stripe Python SDK
- HTTPX
- Z.AI Chat Completions API
- PyJWT
- Argon2id via `pwdlib[argon2]`
- SlowAPI rate limiting
- Pydantic Settings

### Database

- PostgreSQL
- UUID primary keys
- Foreign keys
- Enum types
- Indexes
- RBAC tables
- Payment audit history

## Repository Structure

```text
FitTrack/
  .github/
    workflows/
      ci.yml
      deploy-backend.yml
    dependabot.yml

  backend/
    app/
      api/v1/
      core/
      db/
      models/
      schemas/
      services/
    alembic/
    Dockerfile
    requirements.txt
    requirements-dev.txt
    README.md

  database/
    migrations/
    seed/
    schema.sql
    course_schema.sql

  mobile/
    lib/
      app/
      core/
      features/
      models/
      services/
    assets/exercises/
    pubspec.yaml
    README.md

  tests/
    backend/
    mobile/
    e2e/

  docker/
    README.md

  deploy/
    docker-compose.prod.yml
    .env.production.example

  docs/
    coursework_defense_ua.md
    API.md
    UML/
    architecture/
    requirements/
    uml_diagrams_ua.md
    launch_guide_ua.md
    presentation_plan_ua.md
    architecture_ua.md
    api_methods_ua.md
    software_architecture_ua.md
    oop_analysis_ua.md
    design_patterns_ua.md
    notifications_fcm_ua.md
    ai_fitness_assistant_ua.md
    analytics_module_ua.md
    flutter_localization_ua.md
    code_examples/
    postgresql_design_ua.md
    rbac_ua.md
    premium_payments_ua.md
    production_security_ua.md
    qa_test_plan_ua.md
    devops_ua.md
    ui_ux_design_ua.md

  docker-compose.yml
  .dockerignore
  .env.example
  .gitignore
  LICENSE
  README.md
```

## Documentation

Course defense documents:

- [Coursework defense text](docs/coursework_defense_ua.md)
- [UML documentation](docs/uml_diagrams_ua.md)
- [Launch guide](docs/launch_guide_ua.md)
- [Presentation plan](docs/presentation_plan_ua.md)

Technical documentation:

- [Architecture](docs/architecture_ua.md)
- [Software architecture](docs/software_architecture_ua.md)
- [OOP analysis](docs/oop_analysis_ua.md)
- [Design patterns](docs/design_patterns_ua.md)
- [Firebase Cloud Messaging notifications](docs/notifications_fcm_ua.md)
- [AI Fitness Assistant](docs/ai_fitness_assistant_ua.md)
- [Analytics module](docs/analytics_module_ua.md)
- [Flutter localization](docs/flutter_localization_ua.md)
- [Docker setup](docs/docker_setup_ua.md)
- [Codemagic iOS build](docs/codemagic_ios_ua.md)
- [UI/UX design](docs/ui_ux_design_ua.md)
- [PostgreSQL database design](docs/postgresql_design_ua.md)
- [API documentation](docs/API.md)
- [REST API documentation](docs/api_methods_ua.md)
- [Role-based access control](docs/rbac_ua.md)
- [Premium and test payments](docs/premium_payments_ua.md)
- [Production security](docs/production_security_ua.md)
- [QA test plan](docs/qa_test_plan_ua.md)
- [DevOps and deployment](docs/devops_ua.md)
- [Course compliance audit](docs/course_compliance_audit_ua.md)

Database schemas:

- [Extended PostgreSQL schema](database/schema.sql)
- [Course PostgreSQL schema](database/course_schema.sql)

## Quick Start

### 1. Database

```bash
psql -U postgres
CREATE DATABASE fittrack;
\c fittrack
\i database/course_schema.sql
```

Docker alternative:

```bash
cp .env.example .env
docker compose up --build
```

Detailed Docker instructions are available in [docs/docker_setup_ua.md](docs/docker_setup_ua.md).
If Docker Compose v2 is unavailable, use `docker-compose up --build`.

### 2. Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
alembic -c alembic.ini upgrade head
uvicorn app.main:app --reload
```

Backend health check:

```text
http://127.0.0.1:8000/health
```

OpenAPI docs:

```text
http://127.0.0.1:8000/docs
```

Example backend environment:

```env
DATABASE_URL=postgresql+psycopg://fittrack:fittrack@localhost:5432/fittrack
FIREBASE_PROJECT_ID=fittrack-demo
JWT_SECRET_KEY=replace-with-long-random-secret
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
ZAI_API_KEY=zai_replace_me
ZAI_CHAT_MODEL=glm-5.2
RATE_LIMIT_STORAGE_URI=memory://
ENFORCE_HTTPS=false
```

### 3. Mobile

```bash
cd mobile
flutter pub get
flutterfire configure
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Production-like mobile API mode:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.fittrack.example/api/v1 \
  --dart-define=REQUIRE_HTTPS=true
```

## API Overview

Base path:

```text
/api/v1
```

Main groups:

- `/auth/*`
- `/roles`
- `/permissions`
- `/users/{user_id}/roles`
- `/trainer/*`
- `/admin/*`
- `/subscription/*`
- `/ai-assistant/*`
- `/analytics/*`

Examples:

```http
POST /api/v1/auth/login
POST /api/v1/auth/refresh
GET /api/v1/auth/me
POST /api/v1/subscription/checkout-session
GET /api/v1/subscription/payments
GET /api/v1/admin/payments
POST /api/v1/ai-assistant/plans
GET /api/v1/analytics/dashboard?days=30
```

## Security

Implemented security layers:

- Firebase ID Token verification.
- FitTrack JWT access tokens.
- Refresh token rotation.
- Argon2id password hashing.
- Email verification tokens.
- Rate limiting for sensitive auth endpoints.
- RBAC permission checks.
- Security headers.
- TrustedHost middleware.
- CORS allowlist.
- Optional HTTPS redirect.
- Flutter encrypted token storage.
- HTTPS-only production mobile mode.

## Premium Payments

Premium payment flow uses Stripe test API:

1. Flutter calls `/subscription/checkout-session`.
2. Backend creates local payment with `pending` status.
3. Backend creates Stripe Checkout Session.
4. Flutter opens hosted Stripe Checkout URL.
5. Stripe webhook or manual test confirm marks payment as `succeeded`.
6. Backend activates Premium subscription.
7. User can view payment history.

Stored payment data:

- amount;
- currency;
- status;
- Stripe Checkout Session ID;
- Stripe Payment Intent ID;
- audit events.

Not stored:

- card number;
- CVV;
- bank credentials;
- real payment method details.

## Coursework Defense

Recommended defense order:

1. Explain domain and relevance.
2. Show project goal and requirements.
3. Present architecture.
4. Present database model.
5. Present API and security.
6. Show mobile screens.
7. Demonstrate Premium test payment.
8. Explain roles and permissions.
9. Show UML diagrams.
10. Summarize results and future improvements.

See [presentation_plan_ua.md](docs/presentation_plan_ua.md) for a full slide-by-slide plan.

## Project Status

The repository contains:

- designed and partially implemented Flutter app;
- FastAPI backend skeleton with implemented security/RBAC/payment modules;
- PostgreSQL schemas;
- generated exercise image assets;
- documentation package for university coursework defense.

Before live demo, configure:

- real Firebase project;
- real `firebase_options.dart`;
- PostgreSQL runtime database;
- Stripe test keys;
- Z.AI API key in backend environment;
- Flutter SDK in PATH.
- GitHub Actions secrets for cloud deployment.
