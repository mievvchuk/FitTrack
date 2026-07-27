# FitTrack - архітектура курсового проєкту

## 1. Загальна ідея

FitTrack - це мобільний застосунок для персональних тренувань, який дозволяє користувачу створювати власні тренування, вести історію активності, відстежувати зміну ваги, контролювати харчування та користуватися Premium-функціями через тестову оплату Stripe.

Застосунок підтримує Android та iOS завдяки Flutter. Серверна частина реалізується на Python FastAPI, дані зберігаються у PostgreSQL, а автентифікація користувачів виконується через Firebase Authentication.

## 2. Архітектура системи

```text
Android / iOS Flutter App
        |
        | HTTPS REST API + Firebase ID Token
        v
Python FastAPI Backend
        |
        | SQLAlchemy / Alembic
        v
PostgreSQL Database

External services:
- Firebase Authentication: email/password, Google Sign-In, password reset, password change.
- Firebase Admin SDK: verification of Firebase ID tokens on backend.
- Local device biometrics: Face ID / Touch ID through Flutter local_auth.
- Stripe API test mode: Premium checkout and payment history.
- Media storage: exercise photo/GIF URLs, recommended through Firebase Storage or another object storage.
```

## 3. Обрана архітектурна модель

### Mobile app

Для Flutter доцільно використати Clean Architecture з feature-first структурою:

- `features/auth` - авторизація, реєстрація, Google Sign-In, біометричне розблокування.
- `features/profile` - профіль користувача.
- `features/exercises` - бібліотека вправ.
- `features/workouts` - створення та проходження тренувань.
- `features/progress` - графіки, статистика, історія.
- `features/nutrition` - харчування та макронутрієнти.
- `features/subscription` - тарифи, Stripe, історія платежів.
- `features/admin` - адміністративна частина.

У кожній feature-папці:

```text
data/
  datasources/
  models/
  repositories/
domain/
  entities/
  repositories/
  usecases/
presentation/
  screens/
  widgets/
  providers/
```

Рекомендовані Flutter-пакети:

- `firebase_auth` - Firebase Authentication.
- `google_sign_in` - Google Sign-In.
- `local_auth` - Face ID / Touch ID.
- `flutter_secure_storage` - безпечне збереження токенів і налаштувань.
- `dio` - HTTP-клієнт.
- `go_router` - маршрутизація.
- `flutter_riverpod` або `bloc` - управління станом.
- `fl_chart` - графіки прогресу.
- `stripe_sdk` або `flutter_stripe` - Stripe Checkout/PaymentSheet.

### Backend

FastAPI реалізується як модульний моноліт з розділенням на шари:

- API routers - HTTP-ендпоїнти.
- Schemas - Pydantic DTO для request/response.
- Services - бізнес-логіка.
- Repositories - доступ до бази даних.
- Models - SQLAlchemy ORM-моделі.
- Core - конфігурація, Firebase Admin, безпека, middleware.

Backend не зберігає паролі користувачів. Реєстрація, вхід, Google Sign-In, відновлення та зміна паролю виконуються Firebase Authentication. Backend отримує Firebase ID Token, перевіряє його через Firebase Admin SDK і синхронізує користувача у PostgreSQL.

## 4. Авторизація

### Email/password

1. Користувач вводить email і пароль у Flutter.
2. Flutter викликає Firebase Authentication.
3. Firebase повертає ID Token.
4. Flutter надсилає ID Token у FastAPI в заголовку `Authorization: Bearer <token>`.
5. FastAPI перевіряє токен і створює або оновлює запис користувача у таблиці `users`.

### Google Sign-In

1. Flutter запускає Google Sign-In.
2. Firebase Authentication підтверджує Google-акаунт.
3. Далі використовується той самий backend flow через Firebase ID Token.

### Face ID / Touch ID

Біометрія використовується як локальне розблокування вже авторизованого акаунта:

1. Після успішного входу застосунок зберігає ознаку дозволеної біометрії у secure storage.
2. При наступному відкритті застосунку Flutter викликає `local_auth`.
3. Якщо перевірка успішна, користувач потрапляє в застосунок без повторного введення email/password.

### Відновлення і зміна паролю

Ці операції виконуються Firebase Authentication:

- відновлення: `sendPasswordResetEmail`;
- зміна: `updatePassword` після re-authentication.

## 5. Список екранів

### Авторизація

1. Splash Screen.
2. Onboarding Screen.
3. Login Screen.
4. Registration Screen.
5. Forgot Password Screen.
6. Change Password Screen.
7. Biometric Unlock Screen.

### Основна частина користувача

1. Home Dashboard.
2. Profile Screen.
3. Edit Profile Screen.
4. Exercise Library Screen.
5. Exercise Category Screen.
6. Exercise Details Screen.
7. Workouts List Screen.
8. Workout Builder Screen.
9. Add Exercise To Workout Screen.
10. Active Workout Session Screen.
11. Workout Summary Screen.
12. Workout History Screen.
13. Workout History Details Screen.
14. Progress Dashboard Screen.
15. Weight Chart Screen.
16. Training Statistics Screen.
17. Nutrition Diary Screen.
18. Add Nutrition Entry Screen.
19. Nutrition Daily Summary Screen.
20. Subscription Plans Screen.
21. Stripe Checkout Screen.
22. Payment History Screen.
23. Settings Screen.

### Адміністративна частина

1. Admin Dashboard Screen.
2. Admin Exercises List Screen.
3. Admin Create Exercise Screen.
4. Admin Edit Exercise Screen.
5. Admin Users List Screen.
6. Admin User Details Screen.

## 6. Основні модулі

### Auth module

Відповідає за:

- реєстрацію через email/password;
- вхід через email/password;
- Google Sign-In;
- Firebase ID Token;
- біометричне розблокування;
- відновлення паролю;
- зміну паролю;
- logout.

### Profile module

Відповідає за:

- створення профілю після першого входу;
- перегляд профілю;
- редагування імені, віку, статі, зросту, ваги, цілі тренувань;
- видалення або деактивацію акаунта.

### Exercises module

Відповідає за:

- список вправ;
- фільтрацію за категоріями: груди, спина, ноги, плечі, руки, прес;
- пошук;
- сторінку детальної інформації;
- фото або GIF виконання;
- опис техніки;
- групу м'язів;
- обладнання;
- рівень складності.

### Workouts module

Відповідає за:

- створення власних тренувань;
- додавання вправ;
- налаштування ваги, повторень, підходів і часу відпочинку;
- запуск тренування;
- фіксацію фактично виконаних підходів;
- збереження історії тренувань.

### Progress module

Відповідає за:

- графік зміни ваги;
- історію тренувань;
- кількість тренувань за період;
- загальний обсяг навантаження;
- статистику за групами м'язів.

### Nutrition module

Відповідає за:

- щоденник харчування;
- додавання страв або продуктів;
- калорії;
- білки;
- жири;
- вуглеводи;
- денний підсумок.

### Subscription module

Відповідає за:

- Free plan;
- Premium plan;
- створення Stripe Checkout Session у test mode;
- обробку Stripe webhook;
- статус підписки;
- історію платежів.

### Admin module

Відповідає за:

- додавання вправ;
- редагування вправ;
- видалення або деактивацію вправ;
- перегляд користувачів;
- перегляд деталей користувача.

## 7. Структура бази даних

Головні таблиці:

- `users` - профіль користувача та роль.
- `exercises` - бібліотека вправ.
- `workouts` - шаблони або власні тренування користувачів.
- `workout_exercises` - вправи всередині тренування.
- `workout_sessions` - фактично виконані тренування.
- `workout_session_exercises` - вправи у виконаному тренуванні.
- `workout_sets` - підходи з вагою, повтореннями і відпочинком.
- `weight_logs` - історія зміни ваги.
- `nutrition_entries` - записи харчування.
- `subscription_plans` - тарифи.
- `user_subscriptions` - підписки користувачів.
- `payments` - історія оплат.
- `admin_actions` - журнал адміністративних дій.

Повна SQL-схема наведена у файлі `database/schema.sql`.

## 8. Ролі і права доступу

### User

Може:

- переглядати та редагувати власний профіль;
- переглядати бібліотеку вправ;
- створювати власні тренування;
- запускати тренування;
- переглядати свою історію;
- вести вагу та харчування;
- оформлювати Premium;
- переглядати власні платежі.

### Admin

Може:

- виконувати всі дії користувача;
- додавати вправи;
- редагувати вправи;
- видаляти або деактивувати вправи;
- переглядати список користувачів;
- переглядати деталі користувачів.

## 9. Premium модель

### Free plan

Можливості:

- базова бібліотека вправ;
- створення обмеженої кількості власних тренувань;
- базова історія тренувань;
- базовий щоденник харчування.

### Premium plan

Можливості:

- необмежена кількість тренувань;
- розширена статистика;
- детальні графіки прогресу;
- повна історія тренувань;
- розширена бібліотека вправ;
- експорт прогресу у майбутніх версіях.

## 10. Вимоги до безпеки

- Усі запити до backend виконуються через HTTPS.
- Backend приймає тільки валідний Firebase ID Token.
- Паролі не зберігаються у PostgreSQL.
- Stripe secret key зберігається тільки на backend.
- Stripe webhook перевіряється через webhook signing secret.
- Роль `admin` перевіряється на backend, а не тільки у Flutter.
- Біометрія не передає біометричні дані на сервер, а працює локально на пристрої.

## 11. Мінімальний план реалізації

1. Налаштувати Flutter-проєкт.
2. Налаштувати Firebase Authentication.
3. Реалізувати базову навігацію та auth screens.
4. Налаштувати FastAPI, PostgreSQL, SQLAlchemy та Alembic.
5. Додати перевірку Firebase ID Token на backend.
6. Реалізувати профіль користувача.
7. Реалізувати бібліотеку вправ.
8. Реалізувати створення тренувань.
9. Реалізувати історію тренувань і статистику.
10. Реалізувати nutrition diary.
11. Додати Stripe test checkout.
12. Додати admin screens і admin API.
13. Покрити основні сценарії тестами.
14. Підготувати демонстраційні дані для захисту.

## 12. Відповідність вимогам на 5 балів

| Вимога | Реалізація |
| --- | --- |
| Android та iOS | Flutter |
| Backend | Python FastAPI |
| База даних | PostgreSQL |
| Авторизація | Firebase Authentication |
| Email/password | Firebase email/password |
| Google Sign-In | Firebase + Google provider |
| Face ID / Touch ID | Flutter `local_auth` |
| Відновлення паролю | Firebase password reset |
| Зміна паролю | Firebase update password |
| Профіль користувача | `users` table + profile API |
| Бібліотека вправ | `exercises` table + exercises API |
| Категорії вправ | chest, back, legs, shoulders, arms, abs |
| Тренування | workouts, workout_exercises, workout_sessions |
| Прогрес | weight_logs, workout history, stats API |
| Харчування | nutrition_entries |
| Premium | subscription_plans, user_subscriptions, payments |
| Stripe test payment | checkout session + webhook |
| Admin | admin role + exercise/user management |
