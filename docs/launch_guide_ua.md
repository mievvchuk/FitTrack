# FitTrack - інструкція запуску

## 1. Необхідне програмне забезпечення

- Flutter SDK 3.7+.
- Android Studio або Xcode.
- Python 3.11+.
- PostgreSQL 15+.
- Firebase CLI та FlutterFire CLI.
- Stripe test account.

## 2. Клонування репозиторію

```bash
git clone <repository-url>
cd FitTrack
```

## 3. Налаштування PostgreSQL

```bash
psql -U postgres
CREATE DATABASE fittrack;
\c fittrack
\i database/course_schema.sql
```

Якщо використовується окремий користувач:

```sql
CREATE USER fittrack WITH PASSWORD 'fittrack';
GRANT ALL PRIVILEGES ON DATABASE fittrack TO fittrack;
```

## 4. Налаштування backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

Створити `.env` у папці `backend`:

```env
APP_NAME=FitTrack API
API_V1_PREFIX=/api/v1
DATABASE_URL=postgresql+psycopg://fittrack:fittrack@localhost:5432/fittrack

FIREBASE_PROJECT_ID=fittrack-demo

JWT_SECRET_KEY=replace-with-long-random-secret
JWT_ACCESS_TOKEN_MINUTES=15
JWT_REFRESH_TOKEN_DAYS=30

STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_SUCCESS_URL=fittrack://payment-success?session_id={CHECKOUT_SESSION_ID}
STRIPE_CANCEL_URL=fittrack://payment-cancel

RATE_LIMIT_STORAGE_URI=memory://
ENFORCE_HTTPS=false
ALLOWED_HOSTS=["localhost","127.0.0.1","10.0.2.2","testserver"]
ALLOWED_ORIGINS=["http://localhost","http://127.0.0.1"]
```

Запуск backend:

```bash
uvicorn app.main:app --reload
```

Перевірка:

```bash
curl http://127.0.0.1:8000/health
```

OpenAPI:

```text
http://127.0.0.1:8000/docs
```

## 5. Налаштування Firebase

1. Створити Firebase project.
2. Увімкнути Authentication.
3. Увімкнути Email/Password provider.
4. Увімкнути Google provider.
5. Запустити:

```bash
cd mobile
flutterfire configure
```

Команда має згенерувати реальний `lib/firebase_options.dart`.

## 6. Налаштування Flutter

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Для iOS simulator:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Production-like запуск:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.fittrack.example/api/v1 \
  --dart-define=REQUIRE_HTTPS=true
```

## 7. Stripe test mode

1. У Stripe Dashboard отримати `sk_test_...`.
2. Додати ключ у backend `.env`.
3. Для webhook локально можна використати Stripe CLI:

```bash
stripe listen --forward-to localhost:8000/api/v1/subscription/webhook/stripe
```

4. Отриманий `whsec_...` додати у `.env`.

Для демонстрації без Stripe CLI передбачено endpoint:

```http
POST /api/v1/subscription/payments/{payment_id}/confirm-test
```

Він працює тільки з тестовими платежами.

## 8. Типовий сценарій перевірки

1. Запустити PostgreSQL.
2. Запустити FastAPI backend.
3. Запустити Flutter app.
4. Зареєструватися або увійти через Firebase.
5. Перейти на Premium.
6. Створити test checkout.
7. Підтвердити test payment.
8. Переглянути Payment History.
9. Перевірити Admin/Trainer routes через ролі.

## 9. Відомі умови для локального запуску

- `flutter` має бути встановлений у PATH.
- `firebase_options.dart` у репозиторії є placeholder і має бути замінений через FlutterFire CLI.
- Stripe використовується тільки у test mode.
- Для production потрібно використовувати HTTPS, Redis для rate limiting і безпечні secrets.
