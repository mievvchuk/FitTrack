# FitTrack - план презентації на захист

## Формат

Рекомендована тривалість: 7-10 хвилин.  
Кількість слайдів: 10-12.

## Слайд 1. Титульний слайд

**Тема:** FitTrack - мобільний застосунок для персональних тренувань.

Що сказати:

- назвати тему;
- коротко пояснити, що FitTrack - це mobile + backend + database система;
- зазначити основні технології: Flutter, FastAPI, PostgreSQL, Firebase, Stripe test.

## Слайд 2. Актуальність

Показати проблему:

- користувачам потрібен зручний спосіб вести тренування;
- паперові щоденники тренувань незручні;
- фітнес-прогрес краще сприймається через графіки та статистику;
- тренери потребують цифрового інструменту для клієнтів.

Ключова фраза:

> FitTrack вирішує задачу персонального планування тренувань, відстеження прогресу та монетизації Premium-функцій.

## Слайд 3. Мета і завдання

Мета:

- створити повноцінний мобільний застосунок для персональних тренувань.

Завдання:

- авторизація;
- профіль;
- бібліотека вправ;
- тренування;
- прогрес;
- харчування;
- Premium;
- admin/trainer roles;
- backend security.

## Слайд 4. Ролі користувачів

Показати 3 ролі:

- `User`: тренування, вправи, прогрес, Premium;
- `Trainer`: програми, вправи, клієнти;
- `Admin`: користувачі, вправи, платежі.

Пояснити:

- у БД є `roles`, `permissions`, `user_roles`, `role_permissions`;
- перевірка доступу виконується на backend.

## Слайд 5. Архітектура системи

Показати component diagram:

- Flutter App;
- FastAPI Backend;
- PostgreSQL;
- Firebase Authentication;
- Stripe test API.

Ключова фраза:

> Flutter відповідає за інтерфейс, FastAPI - за бізнес-логіку та безпеку, PostgreSQL - за збереження даних.

## Слайд 6. База даних

Показати ER/UML fragment:

- `users`;
- `profiles`;
- `exercises`;
- `workouts`;
- `progress`;
- `meals`;
- `subscriptions`;
- `payments`;
- `payment_history`;
- RBAC таблиці.

Акцент:

- UUID primary keys;
- foreign keys;
- normalized RBAC;
- окремий audit платежів.

## Слайд 7. API

Показати групи endpoints:

- Auth;
- RBAC;
- Subscription/Payments;
- Exercises;
- Workouts;
- Progress;
- Nutrition.

Приклад:

```http
POST /api/v1/subscription/checkout-session
Authorization: Bearer <token>
```

## Слайд 8. Безпека

Показати security stack:

- Firebase ID Token або FitTrack JWT;
- refresh token rotation;
- Argon2id password hashing;
- email verification;
- rate limiting;
- RBAC permissions;
- secure storage on mobile;
- HTTPS-only production mode;
- Stripe test mode only.

Ключова фраза:

> Frontend не є джерелом прав доступу. Остаточну перевірку виконує backend.

## Слайд 9. Premium і платежі

Показати flow:

- Premium screen;
- Checkout screen;
- Stripe Checkout test URL;
- webhook / manual test confirm;
- payment history.

Наголосити:

- реальні банківські картки не зберігаються;
- використовується тільки `sk_test_...`;
- у БД зберігаються тільки Stripe IDs і статуси.

## Слайд 10. Мобільний інтерфейс

Показати екрани:

- Splash;
- Login/Register;
- Home Dashboard;
- Exercise Library;
- Workout Builder;
- Progress;
- Profile;
- Premium;
- Payment History;
- Admin/Trainer screens.

## Слайд 11. Демонстрація

Сценарій демо:

1. Запуск застосунку.
2. Login/Register.
3. Перехід на Dashboard.
4. Перегляд бібліотеки вправ.
5. Перехід у Premium.
6. Створення test checkout.
7. Підтвердження test payment.
8. Перегляд Payment History.
9. Показ role-based navigation.

## Слайд 12. Висновки

Сказати:

- спроєктовано full-stack mobile систему;
- реалізовано backend, DB, roles, security, Premium flow;
- створено документацію й UML;
- проєкт відповідає вимогам курсової роботи рівня 5 балів.

## Можливі питання викладача

### Чому Flutter?

Flutter дозволяє створити Android та iOS застосунок з однієї кодової бази, має високу швидкість розробки та багату екосистему пакетів.

### Чому FastAPI?

FastAPI має високу продуктивність, автоматичну OpenAPI-документацію, Pydantic validation і зручну систему dependencies.

### Чому PostgreSQL?

PostgreSQL добре підходить для структурованих даних, має foreign keys, enum, індекси та транзакції.

### Чи зберігаються банківські картки?

Ні. Усі карткові дані вводяться тільки на Stripe-hosted Checkout сторінці у test mode. FitTrack зберігає лише Stripe IDs і статуси платежів.

### Де перевіряються ролі?

На backend через `require_permission(...)`. Flutter лише приховує або показує екрани для UX.

### Як захищені паролі?

Паролі не зберігаються у відкритому вигляді. Використовується Argon2id password hashing через `pwdlib[argon2]`.

### Як працює refresh token?

Plain refresh token повертається клієнту один раз і зберігається у secure storage. У PostgreSQL зберігається тільки HMAC/SHA-256 digest. При refresh старий token відкликається, а новий створюється.
