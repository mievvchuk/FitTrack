# Міністерство освіти і науки України

## Курсова робота

**Тема:** FitTrack - мобільний застосунок для персональних тренувань  
**Рівень:** 4 курс, курсовий проєкт рівня 5 балів  
**Студент:** ____________________________  
**Група:** ______________________________  
**Керівник:** ___________________________  
**Місто, рік:** _________________________

---

## Зміст

1. Опис предметної області
2. Мета проєкту
3. Актуальність теми
4. Архітектура системи
5. Опис використаних технологій
6. Опис бази даних
7. Опис API
8. UML діаграми
9. Інструкція запуску
10. Висновки

---

## Вступ

FitTrack - це навчальний full-stack курсовий проєкт мобільного застосунку для персональних тренувань. Система призначена для користувачів, які хочуть планувати тренування, вести історію виконаних вправ, відстежувати фізичний прогрес, контролювати харчування та користуватися Premium-функціями через тестову оплату.

Проєкт складається з мобільного застосунку Flutter для Android та iOS, backend на Python FastAPI, PostgreSQL бази даних, Firebase Authentication для авторизації та Stripe test API для демонстрації Premium-підписки. У системі також реалізовано рольову модель доступу: `User`, `Trainer`, `Admin`.

---

## 1. Опис предметної області

Предметна область проєкту - цифрові сервіси для фітнесу, персональних тренувань і контролю фізичного прогресу. Сучасний користувач фітнес-застосунку очікує не лише список вправ, а повноцінну персональну систему, яка допомагає планувати тренування, фіксувати результати, аналізувати зміни та отримувати зручну візуалізацію прогресу.

Основні об'єкти предметної області:

- користувач;
- профіль користувача;
- тренер;
- адміністратор;
- вправа;
- група м'язів;
- тренування;
- вправа у тренуванні;
- прогрес;
- прийом їжі;
- підписка;
- платіж;
- роль;
- permission.

Типовий користувач FitTrack може зареєструватися, заповнити профіль, переглядати бібліотеку вправ, створювати тренування, додавати вправи з вагою, повтореннями, підходами та часом відпочинку, а також вести історію прогресу. Тренер може створювати програми тренувань і переглядати клієнтів. Адміністратор керує користувачами, вправами та платежами.

---

## 2. Мета проєкту

Метою курсового проєкту є розробка архітектури та програмної реалізації мобільного застосунку FitTrack для персональних тренувань з використанням сучасного cross-platform frontend, REST backend, реляційної бази даних, авторизації, role-based access control, тестових платежів і production-oriented security layer.

Для досягнення мети потрібно реалізувати:

- мобільний застосунок на Flutter;
- backend API на FastAPI;
- PostgreSQL базу даних;
- Firebase Authentication;
- авторизацію через email/password і Google Sign-In;
- локальну біометричну перевірку Face ID / Touch ID;
- профіль користувача;
- бібліотеку вправ;
- конструктор тренувань;
- модуль прогресу;
- модуль харчування;
- Premium-підписку через Stripe test API;
- адміністративну частину;
- ролі та permissions;
- базові UML-діаграми;
- інструкцію запуску та документацію.

---

## 3. Актуальність

Актуальність теми зумовлена поширенням мобільних сервісів для здоров'я, спорту та самоконтролю. Користувачі все частіше використовують смартфон як основний інструмент для планування щоденної активності, контролю ваги, аналізу тренувань і формування корисних звичок.

FitTrack є актуальним з таких причин:

- мобільний формат дає змогу користуватися застосунком безпосередньо у спортзалі;
- персональні тренування потребують збереження історії та параметрів виконання;
- візуалізація прогресу мотивує користувача продовжувати тренування;
- роль тренера дозволяє розширити систему до персонального коучингу;
- Premium-модель демонструє реальний бізнес-сценарій монетизації;
- production security layer показує практичне застосування сучасних підходів до безпеки API.

Проєкт також є корисним як навчальний приклад повноцінної mobile-backend системи, оскільки охоплює frontend, backend, базу даних, зовнішні сервіси, безпеку, ролі, платежі та документацію.

---

## 4. Архітектура системи

FitTrack побудовано як client-server систему.

```text
Flutter Mobile App
  Android / iOS
        |
        | HTTPS REST API
        | Firebase ID Token або FitTrack JWT
        v
FastAPI Backend
        |
        | SQLAlchemy / SQL
        v
PostgreSQL Database

External services:
- Firebase Authentication
- Firebase Admin SDK
- Stripe test API
- Local device biometrics
```

### 4.1. Mobile layer

Мобільний застосунок реалізується на Flutter з feature-first Clean Architecture:

```text
lib/
  app/
  core/
    config/
    constants/
    errors/
    navigation/
    network/
    providers/
    storage/
    widgets/
  features/
    auth/
    profile/
    exercises/
    workouts/
    progress/
    payments/
    trainer/
    admin/
  models/
  services/
```

Ключові mobile-модулі:

- `features/auth` - login, register, password reset, Google Sign-In;
- `features/payments` - Premium, Checkout, Payment success, Payment history;
- `features/trainer` - trainer dashboard, clients, programs;
- `features/admin` - users, exercises, payments;
- `core/network` - API client;
- `core/storage` - encrypted token storage;
- `core/navigation` - role-aware navigation.

### 4.2. Backend layer

Backend реалізовано на FastAPI:

```text
backend/app/
  api/v1/
    auth.py
    roles.py
    subscription.py
    router.py
  core/
    config.py
    firebase.py
    rate_limit.py
    security.py
    security_headers.py
  db/
    session.py
  models/
    rbac.py
    security.py
    payments.py
  schemas/
    rbac.py
    security.py
    payments.py
  services/
    auth_security_service.py
    payment_service.py
    rbac_service.py
  main.py
```

Backend виконує:

- перевірку Firebase ID token;
- видачу та перевірку FitTrack JWT;
- refresh token rotation;
- password hashing;
- email verification;
- permission checking;
- rate limiting;
- обробку Stripe test checkout;
- роботу з PostgreSQL.

### 4.3. Security architecture

Захищені API endpoints приймають:

- `Authorization: Bearer <firebase_id_token>`;
- або `Authorization: Bearer <fittrack_access_jwt>`.

Після автентифікації backend завжди перевіряє permissions у PostgreSQL. Flutter може приховувати кнопки та екрани, але не є джерелом прав доступу.

---

## 5. Опис технологій

### Flutter

Flutter використовується для створення cross-platform мобільного застосунку для Android та iOS. Він дозволяє мати єдину кодову базу, швидко створювати адаптивний UI та використовувати native можливості пристрою.

Використані Flutter-пакети:

- `flutter_riverpod` - керування станом;
- `go_router` - маршрутизація;
- `dio` - REST API client;
- `firebase_core`, `firebase_auth` - Firebase Authentication;
- `google_sign_in` - Google Sign-In;
- `local_auth` - Face ID / Touch ID;
- `flutter_secure_storage` - encrypted storage;
- `url_launcher` - відкриття Stripe Checkout URL.

### FastAPI

FastAPI використовується для backend API. Переваги:

- висока швидкодія;
- автоматична OpenAPI-документація;
- Pydantic validation;
- dependency injection;
- зручна інтеграція з JWT, Firebase Admin, SQLAlchemy.

Backend-бібліотеки:

- `fastapi`;
- `uvicorn`;
- `sqlalchemy`;
- `psycopg`;
- `firebase-admin`;
- `stripe`;
- `PyJWT[crypto]`;
- `pwdlib[argon2]`;
- `slowapi`;
- `pydantic-settings`.

### PostgreSQL

PostgreSQL використовується як реляційна база даних. Вибір PostgreSQL обґрунтований підтримкою:

- UUID primary keys;
- foreign keys;
- enum types;
- індексів;
- транзакцій;
- strict relational integrity;
- масштабованої структури для ролей, платежів і прогресу.

### Firebase Authentication

Firebase Authentication використовується для:

- email/password входу;
- Google Sign-In;
- password reset;
- password change;
- email verification на стороні Firebase.

Backend перевіряє Firebase ID Token через Firebase Admin SDK.

### Stripe Test API

Stripe використовується тільки у test mode:

- створення Checkout Session;
- підтвердження платежу;
- webhook verification;
- історія платежів;
- статус платежу.

FitTrack не зберігає номери карток, CVV або реальні банківські реквізити.

---

## 6. Опис бази даних

У проєкті створено PostgreSQL-схему з такими основними таблицями:

| Таблиця | Призначення |
| --- | --- |
| `users` | Облікові записи користувачів |
| `profiles` | Персональні фітнес-дані користувача |
| `roles` | Ролі системи: user, trainer, admin |
| `permissions` | Довідник permissions |
| `user_roles` | Призначення ролей користувачам |
| `role_permissions` | Призначення permissions ролям |
| `trainer_clients` | Зв'язок тренера з клієнтами |
| `refresh_tokens` | Хеші refresh tokens |
| `email_verification_tokens` | Хеші email verification tokens |
| `muscle_groups` | Групи м'язів |
| `exercises` | Бібліотека вправ |
| `workouts` | Тренування користувача |
| `workout_exercises` | Вправи у тренуванні |
| `progress` | Прогрес користувача |
| `meals` | Харчування та макронутрієнти |
| `subscriptions` | Підписки Free/Premium |
| `payments` | Платежі Stripe test mode |
| `payment_history` | Історія зміни статусів платежів |

### 6.1. Основні зв'язки

- `users 1:1 profiles`;
- `users 1:N workouts`;
- `workouts 1:N workout_exercises`;
- `exercises 1:N workout_exercises`;
- `muscle_groups 1:N exercises`;
- `users 1:N progress`;
- `users 1:N meals`;
- `users 1:N subscriptions`;
- `subscriptions 1:N payments`;
- `payments 1:N payment_history`;
- `users N:M roles`;
- `roles N:M permissions`;
- `trainer_clients` реалізує зв'язок тренера з клієнтами.

### 6.2. Безпека в базі даних

Паролі не зберігаються у відкритому вигляді. Для backend JWT auth використовується `password_hash`, сформований через Argon2id. Refresh tokens і email verification tokens зберігаються тільки як HMAC/SHA-256 digest.

---

## 7. Опис API

Базовий шлях API:

```text
/api/v1
```

### 7.1. Auth API

| Method | Endpoint | Опис |
| --- | --- | --- |
| POST | `/auth/register` | Backend registration з Argon2id hash |
| POST | `/auth/verify-email` | Підтвердження email |
| POST | `/auth/request-email-verification` | Повторний verification token |
| POST | `/auth/login` | Login, access JWT, refresh token |
| POST | `/auth/refresh` | Refresh token rotation |
| POST | `/auth/logout` | Revoke refresh token |
| POST | `/auth/sync-user` | Синхронізація Firebase-користувача |
| GET | `/auth/me` | Поточний користувач |

### 7.2. RBAC API

| Method | Endpoint | Permission |
| --- | --- | --- |
| GET | `/roles` | `users:manage` |
| GET | `/permissions` | `users:manage` |
| GET | `/users/{user_id}/roles` | `users:manage` |
| POST | `/users/{user_id}/roles` | `users:manage` |
| DELETE | `/users/{user_id}/roles/{role_code}` | `users:manage` |
| GET | `/trainer/clients` | `clients:read` |
| POST | `/trainer/programs` | `programs:create` |
| GET | `/admin/payments` | `payments:read` |

### 7.3. Premium API

| Method | Endpoint | Опис |
| --- | --- | --- |
| GET | `/subscription/plans` | Список тарифів |
| GET | `/subscription/me` | Поточна підписка |
| POST | `/subscription/checkout-session` | Створити Stripe test checkout |
| POST | `/subscription/checkout-session/{session_id}/confirm` | Підтвердити Checkout Session |
| POST | `/subscription/payments/{payment_id}/confirm-test` | Manual test confirm |
| GET | `/subscription/payments` | Історія платежів |
| GET | `/subscription/payments/{payment_id}` | Статус платежу |
| GET | `/subscription/payments/{payment_id}/history` | Історія статусів |
| POST | `/subscription/webhook/stripe` | Stripe webhook |

---

## 8. UML діаграми

UML-діаграми винесені в окремий документ:

- [UML diagrams](uml_diagrams_ua.md)

У документі наведено:

- use case diagram;
- component diagram;
- class diagram;
- sequence diagram авторизації;
- sequence diagram Premium платежу;
- activity diagram тренування;
- deployment diagram.

---

## 9. Інструкція запуску

### 9.1. Передумови

Необхідно встановити:

- Flutter SDK;
- Android Studio або Xcode;
- Python 3.11+;
- PostgreSQL 15+;
- Firebase project;
- Stripe test account.

### 9.2. Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Приклад `.env`:

```env
DATABASE_URL=postgresql+psycopg://fittrack:fittrack@localhost:5432/fittrack
FIREBASE_PROJECT_ID=fittrack-demo
JWT_SECRET_KEY=change-this-to-long-random-secret
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
RATE_LIMIT_STORAGE_URI=memory://
ENFORCE_HTTPS=false
```

### 9.3. Database

```bash
psql -U postgres
CREATE DATABASE fittrack;
\c fittrack
\i database/course_schema.sql
```

### 9.4. Mobile

```bash
cd mobile
flutter pub get
flutterfire configure
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Production API:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.fittrack.example/api/v1 \
  --dart-define=REQUIRE_HTTPS=true
```

---

## 10. Висновки

У результаті виконання курсового проєкту було спроєктовано та частково реалізовано full-stack систему FitTrack для персональних тренувань. Проєкт містить мобільний Flutter-застосунок, FastAPI backend, PostgreSQL базу даних, Firebase Authentication, Premium test payments через Stripe, RBAC-модель ролей і production-oriented security layer.

Розроблена система демонструє практичне застосування сучасних технологій мобільної та серверної розробки, принципів Clean Architecture, REST API, реляційного моделювання, токен-базованої авторизації, permission checking і тестової платіжної інтеграції.

FitTrack відповідає вимогам курсового проєкту рівня 5 балів як архітектурно повна система з документацією, базою даних, API, UI-структурою, security layer та UML-діаграмами.
