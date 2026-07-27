# DevOps налаштування FitTrack

## 1. GitHub repository structure

```text
FitTrack/
  .github/
    workflows/
      ci.yml
      deploy-backend.yml
    dependabot.yml

  backend/
    Dockerfile
    alembic.ini
    alembic/
      env.py
      script.py.mako
      versions/
        20260727_0001_initial_schema.py
    scripts/
      entrypoint.sh
    requirements.txt
    requirements-dev.txt
    tests/

  database/
    course_schema.sql
    schema.sql

  deploy/
    docker-compose.prod.yml
    .env.production.example

  mobile/
    lib/
    test/
    pubspec.yaml

  docker-compose.yml
  .env.example
  .dockerignore
  .gitignore
```

## 2. CI/CD overview

FitTrack використовує GitHub Actions:

- `ci.yml` запускається на `push`, `pull_request` та вручну через `workflow_dispatch`;
- `deploy-backend.yml` запускається на `push` у `main`, якщо змінено backend, database, deploy або сам workflow;
- backend тестується на PostgreSQL service container;
- PostgreSQL schema застосовується через Alembic migration;
- Flutter проходить `flutter analyze`, `flutter test` і Android debug build;
- backend Docker image збирається через Docker Buildx;
- production backend image публікується в GitHub Container Registry;
- cloud server оновлюється через SSH і `docker compose`.

## 3. CI pipeline

### Backend tests and migrations

Job `backend-tests` виконує:

1. Підіймає PostgreSQL `postgres:16-alpine`.
2. Встановлює Python 3.13.
3. Встановлює `backend/requirements.txt` і `backend/requirements-dev.txt`.
4. Запускає:

```bash
alembic -c alembic.ini upgrade head
pytest -q --cov=app --cov-report=term-missing
```

Очікуваний результат:

- база створена з нуля;
- схема FitTrack застосована;
- backend tests проходять;
- формується coverage report у логах CI.

### Flutter analyze and tests

Job `flutter-tests` виконує:

```bash
flutter pub get
flutter analyze
flutter test
```

Очікуваний результат:

- Dart/Flutter код не має analyzer errors;
- unit/widget тести проходять.

### Flutter Android build

Job `flutter-build-android` виконує:

```bash
flutter create --platforms=android .
flutter build apk --debug \
  --dart-define=API_BASE_URL=https://api.fittrack.example/api/v1 \
  --dart-define=REQUIRE_HTTPS=true
```

Оскільки в репозиторії поки зберігається тільки coursework Flutter source structure без generated Android/iOS платформ, Android platform files генеруються тимчасово в CI.

### Docker build

Job `docker-build` перевіряє, що backend Docker image збирається:

```bash
docker build -f backend/Dockerfile .
```

## 4. Backend Docker

Backend image містить:

- Python 3.13 slim runtime;
- FastAPI application;
- Alembic migration environment;
- PostgreSQL schema files;
- non-root user `fittrack`;
- healthcheck `/health`.

Startup command:

```bash
sh scripts/entrypoint.sh
```

`entrypoint.sh`:

1. Якщо `RUN_MIGRATIONS=true`, запускає `alembic upgrade head`.
2. Стартує FastAPI через Uvicorn на `0.0.0.0:8000`.

## 5. Local Docker run

1. Створити локальний env:

```bash
cp .env.example .env
```

2. Запустити PostgreSQL і backend:

```bash
docker compose up --build
```

3. Перевірити backend:

```text
http://127.0.0.1:8000/health
http://127.0.0.1:8000/docs
```

## 6. PostgreSQL migrations

FitTrack використовує Alembic.

Основні файли:

- `backend/alembic.ini` - конфігурація Alembic;
- `backend/alembic/env.py` - підключення `DATABASE_URL`;
- `backend/alembic/versions/20260727_0001_initial_schema.py` - початкова міграція;
- `database/course_schema.sql` - повна SQL-схема курсового проєкту.

Команди:

```bash
cd backend
alembic -c alembic.ini upgrade head
alembic -c alembic.ini current
alembic -c alembic.ini history
```

Rollback для демонстраційного середовища:

```bash
alembic -c alembic.ini downgrade base
```

## 7. Cloud server deployment

Production compose file:

```text
deploy/docker-compose.prod.yml
```

Він підіймає:

- `postgres` - PostgreSQL container без зовнішнього порту;
- `api` - backend image з GHCR;
- persistent Docker volume для даних PostgreSQL.

Для реального production середовища PostgreSQL бажано винести в managed database, але для курсового cloud demo поточний compose є достатнім.

## 8. GitHub Secrets

Для `deploy-backend.yml` потрібно додати secrets у GitHub repository settings:

| Secret | Призначення |
| --- | --- |
| `CLOUD_HOST` | IP або domain cloud server |
| `CLOUD_USER` | SSH user |
| `CLOUD_PORT` | SSH port, за замовчуванням `22` |
| `CLOUD_SSH_KEY` | Private SSH key для deploy |
| `GHCR_TOKEN` | Optional PAT для GHCR pull, якщо package приватний |
| `POSTGRES_PASSWORD` | Пароль PostgreSQL container |
| `DATABASE_URL` | PostgreSQL connection string |
| `FIREBASE_PROJECT_ID` | Firebase project id |
| `STRIPE_SECRET_KEY` | Stripe test secret key |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook secret |
| `JWT_SECRET_KEY` | Довгий production JWT secret |
| `ALLOWED_HOSTS` | Host allowlist, наприклад `api.fittrack.example` |
| `ALLOWED_ORIGINS` | CORS origins |

Приклад `DATABASE_URL` для bundled PostgreSQL:

```text
postgresql+psycopg://fittrack:<POSTGRES_PASSWORD>@postgres:5432/fittrack
```

## 9. Deployment flow

1. Developer push у `main`.
2. GitHub Actions збирає Docker image.
3. Image публікується в GHCR.
4. Workflow підключається до cloud server через SSH.
5. Оновлює `~/fittrack/docker-compose.prod.yml`.
6. Створює `.env` на сервері із GitHub Secrets.
7. Виконує:

```bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

8. При старті backend автоматично запускає Alembic migration.

## 10. Production notes

Для повноцінного production запуску треба додати:

- HTTPS reverse proxy, наприклад Nginx або Traefik;
- Redis для distributed rate limiting замість `memory://`;
- managed PostgreSQL або регулярні backup-и Docker volume;
- monitoring і log aggregation;
- branch protection rule: PR merge тільки після зеленого CI;
- GitHub Environment protection для `production`.
