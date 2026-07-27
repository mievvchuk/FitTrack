# Docker конфігурація FitTrack

Цей документ описує локальний запуск FitTrack через Docker Compose. Конфігурація містить два основні контейнери:

- `fittrack-api` - FastAPI backend;
- `fittrack-postgres` - PostgreSQL database.

## Структура файлів

```text
FitTrack/
  docker-compose.yml
  .env.example
  .dockerignore
  backend/
    Dockerfile
    scripts/
      entrypoint.sh
  database/
    course_schema.sql
```

## Backend container

Backend збирається з `backend/Dockerfile`.

Основні характеристики:

- базовий образ `python:3.13-slim`;
- встановлення залежностей з `backend/requirements.txt`;
- запуск від окремого користувача `fittrack`;
- робоча директорія `/app/backend`;
- порт контейнера `8000`;
- автоматичний запуск Alembic міграцій, якщо `RUN_MIGRATIONS=true`;
- запуск сервера через `uvicorn app.main:app`.

## Database container

PostgreSQL запускається з образу `postgres:16-alpine`.

Основні характеристики:

- база даних `fittrack`;
- користувач `fittrack`;
- volume `fittrack-postgres-data` для збереження даних;
- healthcheck через `pg_isready`;
- backend стартує після готовності PostgreSQL.

## Environment variables

Перед запуском потрібно створити локальний `.env` файл:

```powershell
Copy-Item .env.example .env
```

Для macOS/Linux:

```bash
cp .env.example .env
```

Основні змінні:

| Змінна | Призначення |
| --- | --- |
| `API_PORT` | Порт backend на локальній машині |
| `POSTGRES_PORT` | Порт PostgreSQL на локальній машині |
| `POSTGRES_DB` | Назва бази даних |
| `POSTGRES_USER` | Користувач PostgreSQL |
| `POSTGRES_PASSWORD` | Пароль PostgreSQL |
| `DATABASE_URL` | URL підключення backend до PostgreSQL |
| `FIREBASE_PROJECT_ID` | Firebase project id |
| `STRIPE_SECRET_KEY` | Stripe test secret key |
| `STRIPE_WEBHOOK_SECRET` | Stripe test webhook secret |
| `JWT_SECRET_KEY` | Секрет для JWT та refresh token digest |
| `RATE_LIMIT_STORAGE_URI` | Сховище rate limiting, локально `memory://` |
| `ALLOWED_HOSTS` | Дозволені host names для backend |
| `ALLOWED_ORIGINS` | Дозволені CORS origins |
| `ENFORCE_HTTPS` | У production має бути `true` |
| `RUN_MIGRATIONS` | Автоматичний запуск Alembic міграцій |
| `NOTIFICATIONS_ENABLED` | Увімкнення Firebase Cloud Messaging |
| `FCM_DRY_RUN` | Тестова перевірка FCM без реальної доставки |
| `ZAI_API_KEY` | Backend-only ключ AI Fitness Assistant |

Важливо: реальні секрети не можна комітити в Git. Для курсового проєкту Stripe використовується тільки в test mode, а реальні банківські картки не зберігаються.

## Запуск

1. Перейти в корінь проєкту:

```powershell
cd C:\Users\Misha\Documents\FitTrack
```

2. Створити `.env`:

```powershell
Copy-Item .env.example .env
```

3. За потреби змінити значення в `.env`.

4. Запустити backend і database:

```powershell
docker compose up --build
```

Якщо Docker Compose v2 недоступний, використовуйте legacy команду:

```powershell
docker-compose up --build
```

5. Перевірити стан контейнерів:

```powershell
docker compose ps
```

6. Перевірити backend healthcheck:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

OpenAPI документація:

```text
http://127.0.0.1:8000/docs
```

## Підключення до PostgreSQL

```powershell
docker compose exec postgres psql -U fittrack -d fittrack
```

Перегляд таблиць у `psql`:

```sql
\dt
```

## Міграції бази даних

За замовчуванням backend автоматично запускає:

```bash
alembic -c alembic.ini upgrade head
```

Для ручного запуску:

```powershell
docker compose exec api alembic -c alembic.ini upgrade head
```

Перевірити поточну міграцію:

```powershell
docker compose exec api alembic -c alembic.ini current
```

## Логи

Backend:

```powershell
docker compose logs -f api
```

Database:

```powershell
docker compose logs -f postgres
```

## Зупинка

Зупинити контейнери:

```powershell
docker compose down
```

Зупинити контейнери і видалити локальні дані PostgreSQL:

```powershell
docker compose down -v
```

Команда `down -v` видаляє volume `fittrack-postgres-data`, тому її варто виконувати тільки коли тестові дані більше не потрібні.

## Підключення Flutter до Docker backend

Android emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

iOS simulator або desktop/browser:

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Production notes

Для production deployment потрібно:

- замінити `JWT_SECRET_KEY`, `POSTGRES_PASSWORD`, Stripe і Z.AI ключі;
- встановити `ENFORCE_HTTPS=true`;
- використовувати HTTPS reverse proxy;
- обмежити `ALLOWED_HOSTS` і `ALLOWED_ORIGINS` реальними доменами;
- використовувати зовнішній PostgreSQL volume або managed database;
- використовувати Redis для `RATE_LIMIT_STORAGE_URI`;
- зберігати секрети в GitHub Actions Secrets або cloud secret manager.
