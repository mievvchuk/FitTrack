# FitTrack - аудит відповідності курсовому проєкту 4 курсу, рівень 5 балів

Дата аудиту: 2026-07-27.

Оновлення після аудиту: додано Premium систему з PostgreSQL `payment_history`, FastAPI Stripe test checkout/webhook/status endpoints та Flutter екранами Premium, Checkout, Payment success і Payment history. Старі рядки нижче залишаються історичним аудитом до цієї доробки.

Оновлення security layer: додано JWT access tokens, refresh token rotation, Argon2id password hashing, email verification tokens, SlowAPI rate limiting, security headers, TrustedHost/CORS/optional HTTPS redirect та Flutter encrypted token storage.

## 1. Загальний висновок

Поточний проєкт FitTrack має сильну проєктну основу: є архітектурна документація, UI/UX специфікація, API специфікація, PostgreSQL схеми, Flutter skeleton з Clean Architecture, Firebase Auth skeleton, REST client і набір exercise assets.

Але для рівня 5 балів проєкт ще не є повністю реалізованим застосунком. Основна проблема: backend на FastAPI поки відсутній як код, більшість CRUD/API/Stripe/admin сценаріїв існують лише в документації, а мобільний застосунок має переважно auth skeleton і placeholder-екрани.

Орієнтовна готовність:

- Документація: 75%.
- База даних: 70%.
- Flutter frontend: 35%.
- Backend: 10%.
- Інтеграції Firebase/Stripe: 25%.
- Тестування/deployment: 5%.

## 2. Що вже є

### Документація

- `README.md` з описом системи і запропонованою структурою.
- `docs/architecture_ua.md` з архітектурою Flutter + FastAPI + PostgreSQL + Firebase + Stripe.
- `docs/ui_ux_design_ua.md` з дизайн-системою, екранами, UX-переходами і Flutter-компонентами.
- `docs/api_methods_ua.md` зі списком REST API методів.
- `docs/postgresql_design_ua.md` з таблицями, PK/FK і текстовою ER-діаграмою.

### База даних

- `database/schema.sql` - розширена схема з users, exercises, workouts, workout sessions, nutrition, subscriptions, payments, admin actions.
- `database/course_schema.sql` - нормалізована схема саме під перелік таблиць з курсової: users, profiles, muscle_groups, exercises, workouts, workout_exercises, progress, meals, subscriptions, payments.
- Є UUID primary keys, foreign keys, enum-типи, індекси, `updated_at` triggers.

### Flutter frontend

- Створено `mobile/pubspec.yaml`.
- Є Clean Architecture структура:
  - `lib/core`
  - `lib/features/auth`
  - `lib/features/profile`
  - `lib/features/exercises`
  - `lib/features/workouts`
  - `lib/features/progress`
  - `lib/features/payments`
  - `lib/models`
  - `lib/services`
- Підключені залежності:
  - `firebase_core`
  - `firebase_auth`
  - `google_sign_in`
  - `flutter_riverpod`
  - `dio`
  - `go_router`
  - `local_auth`
  - `flutter_secure_storage`
- Є Firebase initialization через placeholder `firebase_options.dart`.
- Є auth repository, data source, use cases, Riverpod controller.
- Є екрани:
  - Login
  - Register
  - Forgot Password
  - Splash
  - Home Dashboard
  - Profile
  - Exercise Library
  - Workouts
  - Progress
  - Payment History
- Є REST client з Firebase ID token у `Authorization: Bearer <token>`.
- Є 10 PNG assets вправ у `mobile/assets/exercises`.

## 3. Детальна перевірка за вимогами

| # | Вимога | Поточний статус | Що є | Чого не вистачає |
| --- | --- | --- | --- | --- |
| 1 | Frontend + Backend архітектура | Частково | Архітектура описана, Flutter skeleton створений | Немає реального `backend/` FastAPI проєкту, немає docker-compose |
| 2 | Авторизація | Частково | Firebase Auth data source, auth controller, login screen | Немає реального Firebase config, backend token verification не реалізований |
| 3 | Реєстрація | Частково | Register screen, `createUserWithEmailAndPassword` | Немає profile setup після реєстрації, немає backend sync реалізації |
| 4 | Відновлення паролю | Частково | Forgot Password screen, `sendPasswordResetEmail` | Немає UX підтвердження через email state, немає інтеграційного тесту |
| 5 | Зміна паролю | Не реалізовано | Описано в документації | Немає screen, use case, repository method, re-authentication flow |
| 6 | 2FA | Не реалізовано | Немає | Потрібно додати MFA/TOTP або Firebase Multi-Factor Authentication flow |
| 7 | Face ID / Touch ID | Частково | `BiometricAuthService` з `local_auth` | Немає Biometric Unlock screen, secure storage flag, route guard |
| 8 | SSO | Частково | Google Sign-In через `google_sign_in` + Firebase credential | Немає повної platform configuration Android/iOS, немає Apple Sign-In |
| 9 | Ролі користувачів | Частково | `role` у DB, admin endpoints описані | Немає backend RBAC middleware/dependency, немає admin UI |
| 10 | CRUD операції | Частково | CRUD описаний в API документації, частково DB готова | Немає FastAPI CRUD handlers, немає Flutter repositories для profile/exercises/workouts/progress/payments |
| 11 | База даних | Добре, але не завершено | SQL схеми, PK/FK, індекси, enum-и, ER опис | Немає Alembic migrations, seed data, зв'язку з backend ORM |
| 12 | API | Частково | `docs/api_methods_ua.md`, Flutter `ApiClient` | Немає FastAPI implementation, OpenAPI прикладів з реального сервера |
| 13 | Платежі | Частково в документації | Stripe checkout описаний, payments DB є, Payment screen placeholder | Немає Stripe backend service, webhook, mobile checkout flow |
| 14 | Історія платежів | Частково | `payments` table, API endpoint описаний, UI placeholder | Немає реального GET `/subscription/payments`, немає payment details |
| 15 | Безпека | Частково | Описано HTTPS, Firebase token, Stripe secret, admin check | Немає backend security implementation, rate limiting, CORS config, secrets handling |
| 16 | Логування | Майже немає | `admin_actions` table у розширеній DB схемі | Немає structured logging, audit middleware, request id, error logging |
| 17 | Тестування | Майже немає | Один placeholder Flutter widget test | Немає unit/integration tests, backend tests, auth tests, API tests |
| 18 | Документація | Добре | Архітектура, API, UI/UX, DB design | Потрібно додати setup guide, deployment guide, test plan, user manual |
| 19 | UML діаграми | Частково | Є текстова ER-діаграма | Немає UML use case, class, sequence, component, deployment diagrams |
| 20 | Deployment | Не реалізовано | У README запропоновано Dockerfile/docker-compose як майбутню структуру | Немає Dockerfile, docker-compose, env templates, CI/CD, production config |

## 4. Найважливіші прогалини

### P0 - критично для захисту на 5 балів

1. Створити реальний FastAPI backend:
   - `backend/app/main.py`
   - routers: auth, users, profiles, exercises, workouts, progress, meals, subscriptions, payments, admin
   - SQLAlchemy models
   - Pydantic schemas
   - repositories/services
   - DB session config

2. Підключити PostgreSQL через SQLAlchemy + Alembic:
   - migration files;
   - database URL через `.env`;
   - seed для muscle groups і базових вправ.

3. Реалізувати Firebase Admin verification:
   - перевірка Firebase ID token;
   - dependency `get_current_user`;
   - sync user endpoint;
   - role-based dependency `require_admin`.

4. Реалізувати основні CRUD API:
   - profile CRUD;
   - exercises list/detail/admin CRUD;
   - workouts CRUD;
   - workout exercises CRUD;
   - progress CRUD;
   - meals CRUD.

5. Зробити Flutter підключення до реального API:
   - repositories для profile/exercises/workouts/progress/payments;
   - screen states: loading/error/empty/success;
   - замінити placeholder cards на API data.

### P1 - дуже важливо для високої оцінки

1. Додати зміну паролю:
   - Change Password screen;
   - Firebase re-authentication;
   - `updatePassword`.

2. Додати Face ID / Touch ID flow:
   - Biometric Unlock screen;
   - secure storage flag `biometrics_enabled`;
   - route guard після Splash.

3. Додати Stripe test payments:
   - backend endpoint створення Checkout Session;
   - Stripe webhook;
   - запис у `payments`;
   - mobile redirect success/cancel;
   - реальна історія платежів.

4. Додати ролі й admin panel:
   - admin screens;
   - admin exercise CRUD;
   - users list;
   - backend RBAC enforcement.

5. Додати логування:
   - structured logs;
   - request id middleware;
   - audit log для admin actions;
   - error handler.

### P2 - потрібно для якості й надійності

1. Додати 2FA:
   - Firebase MFA, якщо доступно в обраному плані;
   - або TOTP flow на backend;
   - recovery codes для демонстрації.

2. Розширити SSO:
   - Google Sign-In уже є частково;
   - для iOS бажано Apple Sign-In як додатковий SSO;
   - налаштувати Android SHA-1/SHA-256 і iOS URL schemes.

3. Додати повні тести:
   - Flutter unit tests для auth controller;
   - widget tests для auth screens;
   - FastAPI tests через pytest/httpx;
   - repository tests;
   - payment webhook tests.

4. Додати UML:
   - Use Case diagram;
   - Class diagram;
   - Sequence diagram для login і workout creation;
   - Component diagram;
   - Deployment diagram.

### P3 - полірування перед фінальним захистом

1. Додати deployment:
   - backend Dockerfile;
   - docker-compose для FastAPI + PostgreSQL;
   - `.env.example`;
   - healthcheck;
   - README з командами запуску.

2. Додати демонстраційні дані:
   - 10-20 вправ;
   - test user;
   - admin user;
   - sample workouts;
   - sample progress;
   - sample payments.

3. Додати user manual:
   - як зареєструватися;
   - як створити тренування;
   - як додати харчування;
   - як переглянути прогрес;
   - як оформити Premium.

4. Додати скриншоти або mockups:
   - login;
   - home;
   - exercises;
   - workout builder;
   - progress;
   - payments.

## 5. Рекомендований порядок реалізації

### Етап 1 - зробити систему виконуваною

1. Встановити Flutter SDK і згенерувати native wrappers:
   - `flutter create --platforms=android,ios .` у папці `mobile`.
2. Створити `backend/` FastAPI skeleton.
3. Додати `docker-compose.yml` для PostgreSQL і backend.
4. Підключити Alembic migrations.
5. Реалізувати `/health`.

### Етап 2 - закрити авторизацію

1. Замінити placeholder `firebase_options.dart` на реальний.
2. Увімкнути Email/Password і Google provider у Firebase Console.
3. Додати Firebase Admin SDK на backend.
4. Реалізувати `/auth/sync-user` і `/auth/me`.
5. Додати role sync і admin dependency.

### Етап 3 - основна бізнес-логіка

1. Profile CRUD.
2. Exercise library + admin CRUD.
3. Workout builder + workout exercises.
4. Progress + weight chart data.
5. Meals/nutrition CRUD.

### Етап 4 - Premium і платежі

1. Stripe Checkout Session.
2. Stripe webhook validation.
3. Payment history API.
4. Flutter payment screen integration.
5. Premium state у profile/home.

### Етап 5 - безпека, тести, deployment

1. Structured logging.
2. Rate limiting.
3. Centralized exception handling.
4. Unit/integration tests.
5. UML diagrams.
6. Deployment guide.

## 6. Ризики для оцінки

Найбільші ризики:

- немає backend implementation;
- немає реального запуску Android/iOS через відсутні native wrappers;
- немає реальних CRUD сценаріїв;
- немає Stripe flow;
- немає тестів;
- немає deployment;
- 2FA повністю відсутня.

Якщо доробити P0 і P1, проєкт буде виглядати як повноцінна курсова система. Якщо додати P2-P3, це вже рівень сильної демонстрації з хорошою інженерною подачею.

## 7. Короткий чекліст готовності

| Блок | Для 5 балів має бути | Поточний стан |
| --- | --- | --- |
| Mobile app запускається | Так | Ні, потрібен Flutter SDK/native wrappers |
| Backend запускається | Так | Ні, backend відсутній |
| PostgreSQL працює | Так | Є SQL, немає runtime setup |
| Firebase Auth працює | Так | Код частково є, config placeholder |
| Google Sign-In працює | Так | Код частково є, platform setup відсутній |
| Face ID / Touch ID працює | Так | Service є, flow відсутній |
| 2FA працює | Бажано/у вимогах аудиту | Немає |
| CRUD profile/exercises/workouts | Так | Описано, не реалізовано |
| Progress charts | Так | Placeholder |
| Nutrition | Так | DB/API docs, frontend відсутній |
| Stripe test payment | Так | DB/API docs, UI placeholder |
| Admin panel | Так | Описано, не реалізовано |
| Tests | Так | Placeholder test |
| UML | Так | ER text є, UML немає |
| Deployment | Так | Немає |
