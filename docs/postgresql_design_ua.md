# FitTrack - проєктування PostgreSQL бази даних

## 1. Правило іменування

У завданні таблиці названі у стилі `Users`, `Profiles`, `MuscleGroups`. У PostgreSQL краще використовувати `snake_case` без лапок, тому фізичні назви таблиць такі:

| Назва у завданні | Назва в PostgreSQL |
| --- | --- |
| Users | `users` |
| Profiles | `profiles` |
| Exercises | `exercises` |
| MuscleGroups | `muscle_groups` |
| Workouts | `workouts` |
| WorkoutExercises | `workout_exercises` |
| Progress | `progress` |
| Meals | `meals` |
| Subscriptions | `subscriptions` |
| Payments | `payments` |

SQL-реалізація цієї схеми знаходиться у файлі `database/course_schema.sql`.

## 2. Таблиця Users

Призначення: зберігає базові дані акаунта, Firebase UID, email і статус. Ролі зберігаються окремо через `user_roles`.

| Поле | Тип даних | Обмеження | Опис |
| --- | --- | --- | --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Унікальний ідентифікатор користувача |
| `firebase_uid` | `VARCHAR(128)` | `NOT NULL`, `UNIQUE` | UID користувача у Firebase Authentication |
| `email` | `VARCHAR(255)` | `NOT NULL`, `UNIQUE` | Email користувача |
| `auth_provider` | `fittrack_auth_provider` | `NOT NULL`, `DEFAULT 'email_password'` | Спосіб входу: email/password або Google |
| `password_hash` | `TEXT` | nullable | Argon2id hash для backend JWT auth |
| `email_verified_at` | `TIMESTAMPTZ` | nullable | Час підтвердження email |
| `failed_login_attempts` | `INTEGER` | `NOT NULL`, `DEFAULT 0` | Лічильник невдалих входів |
| `locked_until` | `TIMESTAMPTZ` | nullable | Тимчасове блокування після brute-force спроб |
| `last_password_changed_at` | `TIMESTAMPTZ` | nullable | Час останньої зміни паролю |
| `token_version` | `INTEGER` | `NOT NULL`, `DEFAULT 0` | Версія токенів для масового revoke |
| `is_active` | `BOOLEAN` | `NOT NULL`, `DEFAULT TRUE` | Активність акаунта |
| `last_login_at` | `TIMESTAMPTZ` | nullable | Час останнього входу |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата створення |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата оновлення |

Primary key: `users.id`

Foreign keys: немає.

Зв'язки:

- `users 1:1 profiles`
- `users 1:N workouts`
- `users 1:N progress`
- `users 1:N meals`
- `users 1:N subscriptions`
- `users 1:N payments`
- `users 1:N exercises` для адміністратора, який створив вправу.
- `users N:M roles` через `user_roles`.
- `users N:M users` для зв'язку тренера з клієнтами через `trainer_clients`.

## 2.1. Таблиці Roles, Permissions, UserRoles, RolePermissions

Призначення: реалізують role-based access control для ролей `user`, `trainer`, `admin`.

| Таблиця | Primary key | Foreign keys | Опис |
| --- | --- | --- | --- |
| `roles` | `id` | немає | Довідник ролей: `user`, `trainer`, `admin` |
| `permissions` | `id` | немає | Довідник прав доступу, наприклад `users:manage`, `payments:read` |
| `user_roles` | `(user_id, role_id)` | `user_id -> users.id`, `role_id -> roles.id` | Призначення ролей користувачам |
| `role_permissions` | `(role_id, permission_id)` | `role_id -> roles.id`, `permission_id -> permissions.id` | Призначення permissions ролям |
| `trainer_clients` | `(trainer_id, client_id)` | `trainer_id -> users.id`, `client_id -> users.id` | Зв'язок тренера з клієнтами |

## 2.2. Таблиці RefreshTokens та EmailVerificationTokens

| Таблиця | Primary key | Foreign keys | Опис |
| --- | --- | --- | --- |
| `refresh_tokens` | `id` | `user_id -> users.id` | Зберігає HMAC/SHA-256 digest refresh token, expiry, revoke time, device/user-agent/IP |
| `email_verification_tokens` | `id` | `user_id -> users.id` | Зберігає digest email verification token, expiry та consumed time |

Plain refresh token та email verification token не зберігаються у базі. У БД лежить тільки digest.

Кардинальність:

- `users N:M roles`;
- `roles N:M permissions`;
- `users N:M users` для зв'язку Trainer -> Client.

## 3. Таблиця Profiles

Призначення: зберігає персональні фітнес-дані користувача.

| Поле | Тип даних | Обмеження | Опис |
| --- | --- | --- | --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Унікальний ідентифікатор профілю |
| `user_id` | `UUID` | `NOT NULL`, `UNIQUE`, `FK -> users.id` | Користувач, якому належить профіль |
| `full_name` | `VARCHAR(120)` | `NOT NULL` | Ім'я користувача |
| `age` | `INTEGER` | `CHECK 10..100` | Вік |
| `gender` | `fittrack_gender` | nullable | Стать |
| `height_cm` | `NUMERIC(5,2)` | `CHECK 80..250` | Зріст у сантиметрах |
| `weight_kg` | `NUMERIC(5,2)` | `CHECK 25..300` | Поточна вага |
| `training_goal` | `fittrack_training_goal` | nullable | Ціль тренувань |
| `avatar_url` | `TEXT` | nullable | URL аватара |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата створення |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата оновлення |

Primary key: `profiles.id`

Foreign key: `profiles.user_id -> users.id`

Зв'язок: один користувач має один профіль. `UNIQUE(user_id)` гарантує зв'язок `1:1`.

## 4. Таблиця MuscleGroups

Призначення: довідник груп м'язів.

| Поле | Тип даних | Обмеження | Опис |
| --- | --- | --- | --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Унікальний ідентифікатор групи |
| `code` | `VARCHAR(40)` | `NOT NULL`, `UNIQUE` | Системний код: chest, back, legs |
| `name` | `VARCHAR(80)` | `NOT NULL`, `UNIQUE` | Назва групи м'язів |
| `description` | `TEXT` | nullable | Опис |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата створення |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата оновлення |

Primary key: `muscle_groups.id`

Foreign keys: немає.

Зв'язок: `muscle_groups 1:N exercises`.

## 5. Таблиця Exercises

Призначення: бібліотека вправ з фото/GIF, технікою, обладнанням і складністю.

| Поле | Тип даних | Обмеження | Опис |
| --- | --- | --- | --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Унікальний ідентифікатор вправи |
| `muscle_group_id` | `UUID` | `NOT NULL`, `FK -> muscle_groups.id` | Група м'язів |
| `created_by_user_id` | `UUID` | `FK -> users.id` | Адміністратор, який додав вправу |
| `name` | `VARCHAR(160)` | `NOT NULL` | Назва вправи |
| `media_url` | `TEXT` | nullable | URL фото або GIF |
| `media_type` | `fittrack_media_type` | nullable | Тип медіа: photo або gif |
| `description` | `TEXT` | `NOT NULL` | Опис вправи |
| `technique` | `TEXT` | `NOT NULL` | Техніка виконання |
| `common_mistakes` | `TEXT` | nullable | Типові помилки |
| `equipment` | `VARCHAR(160)` | nullable | Необхідне обладнання |
| `difficulty` | `fittrack_difficulty_level` | `NOT NULL` | Рівень складності |
| `is_active` | `BOOLEAN` | `NOT NULL`, `DEFAULT TRUE` | Активність вправи |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата створення |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата оновлення |

Primary key: `exercises.id`

Foreign keys:

- `exercises.muscle_group_id -> muscle_groups.id`
- `exercises.created_by_user_id -> users.id`

Зв'язки:

- одна група м'язів має багато вправ;
- один admin-користувач може створити багато вправ;
- одна вправа може входити в багато тренувань через `workout_exercises`.

## 6. Таблиця Workouts

Призначення: зберігає тренування користувача.

| Поле | Тип даних | Обмеження | Опис |
| --- | --- | --- | --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Унікальний ідентифікатор тренування |
| `user_id` | `UUID` | `NOT NULL`, `FK -> users.id` | Автор тренування |
| `title` | `VARCHAR(160)` | `NOT NULL` | Назва тренування |
| `description` | `TEXT` | nullable | Опис |
| `training_goal` | `fittrack_training_goal` | nullable | Ціль тренування |
| `scheduled_for` | `DATE` | nullable | Запланована дата |
| `estimated_duration_minutes` | `INTEGER` | `CHECK > 0` | Орієнтовна тривалість |
| `is_completed` | `BOOLEAN` | `NOT NULL`, `DEFAULT FALSE` | Чи виконане тренування |
| `completed_at` | `TIMESTAMPTZ` | nullable | Час завершення |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата створення |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата оновлення |

Primary key: `workouts.id`

Foreign key: `workouts.user_id -> users.id`

Зв'язки:

- один користувач має багато тренувань;
- одне тренування має багато вправ через `workout_exercises`;
- тренування може мати записи прогресу.

## 7. Таблиця WorkoutExercises

Призначення: проміжна таблиця між тренуваннями і вправами. Зберігає параметри вправи у конкретному тренуванні.

| Поле | Тип даних | Обмеження | Опис |
| --- | --- | --- | --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Унікальний ідентифікатор запису |
| `workout_id` | `UUID` | `NOT NULL`, `FK -> workouts.id` | Тренування |
| `exercise_id` | `UUID` | `NOT NULL`, `FK -> exercises.id` | Вправа |
| `order_index` | `INTEGER` | `NOT NULL`, `DEFAULT 0` | Порядок вправи у тренуванні |
| `sets_count` | `INTEGER` | `NOT NULL`, `CHECK > 0` | Кількість підходів |
| `reps_count` | `INTEGER` | `NOT NULL`, `CHECK > 0` | Кількість повторень |
| `weight_kg` | `NUMERIC(6,2)` | `CHECK >= 0` | Робоча вага |
| `rest_seconds` | `INTEGER` | `CHECK >= 0` | Відпочинок між підходами |
| `notes` | `TEXT` | nullable | Нотатки |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата створення |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата оновлення |

Primary key: `workout_exercises.id`

Foreign keys:

- `workout_exercises.workout_id -> workouts.id`
- `workout_exercises.exercise_id -> exercises.id`

Зв'язок: реалізує `workouts N:M exercises`.

Додаткове обмеження: `UNIQUE(workout_id, order_index)` не дозволяє двом вправам мати однаковий порядок в одному тренуванні.

## 8. Таблиця Progress

Призначення: зберігає записи прогресу користувача: вагу, обсяг тренування, тривалість, спалені калорії.

| Поле | Тип даних | Обмеження | Опис |
| --- | --- | --- | --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Унікальний ідентифікатор запису |
| `user_id` | `UUID` | `NOT NULL`, `FK -> users.id` | Користувач |
| `workout_id` | `UUID` | `FK -> workouts.id` | Пов'язане тренування, якщо є |
| `progress_date` | `DATE` | `NOT NULL` | Дата запису |
| `weight_kg` | `NUMERIC(5,2)` | `CHECK 25..300` | Вага користувача |
| `body_fat_percent` | `NUMERIC(5,2)` | `CHECK 0..100` | Відсоток жиру |
| `total_volume_kg` | `NUMERIC(10,2)` | `CHECK >= 0` | Сумарний тренувальний обсяг |
| `workout_duration_minutes` | `INTEGER` | `CHECK >= 0` | Тривалість тренування |
| `calories_burned` | `INTEGER` | `CHECK >= 0` | Спалені калорії |
| `notes` | `TEXT` | nullable | Нотатки |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата створення |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата оновлення |

Primary key: `progress.id`

Foreign keys:

- `progress.user_id -> users.id`
- `progress.workout_id -> workouts.id`

Зв'язки:

- один користувач має багато записів прогресу;
- один запис прогресу може бути пов'язаний з одним тренуванням.

## 9. Таблиця Meals

Призначення: щоденник харчування користувача.

| Поле | Тип даних | Обмеження | Опис |
| --- | --- | --- | --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Унікальний ідентифікатор прийому їжі |
| `user_id` | `UUID` | `NOT NULL`, `FK -> users.id` | Користувач |
| `meal_date` | `DATE` | `NOT NULL` | Дата |
| `meal_type` | `fittrack_meal_type` | `NOT NULL` | Тип: breakfast, lunch, dinner, snack |
| `name` | `VARCHAR(160)` | `NOT NULL` | Назва страви або продукту |
| `serving_size` | `VARCHAR(80)` | nullable | Розмір порції |
| `calories` | `INTEGER` | `NOT NULL`, `CHECK >= 0` | Калорії |
| `protein_g` | `NUMERIC(6,2)` | `NOT NULL`, `DEFAULT 0` | Білки |
| `fat_g` | `NUMERIC(6,2)` | `NOT NULL`, `DEFAULT 0` | Жири |
| `carbs_g` | `NUMERIC(6,2)` | `NOT NULL`, `DEFAULT 0` | Вуглеводи |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата створення |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата оновлення |

Primary key: `meals.id`

Foreign key: `meals.user_id -> users.id`

Зв'язок: один користувач має багато записів харчування.

## 10. Таблиця Subscriptions

Призначення: зберігає тариф користувача та статус Premium-підписки.

| Поле | Тип даних | Обмеження | Опис |
| --- | --- | --- | --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Унікальний ідентифікатор підписки |
| `user_id` | `UUID` | `NOT NULL`, `FK -> users.id` | Користувач |
| `plan` | `fittrack_subscription_plan` | `NOT NULL`, `DEFAULT 'free'` | Тариф: free або premium |
| `status` | `fittrack_subscription_status` | `NOT NULL`, `DEFAULT 'active'` | Статус підписки |
| `price_cents` | `INTEGER` | `NOT NULL`, `DEFAULT 0`, `CHECK >= 0` | Вартість у центах |
| `currency` | `CHAR(3)` | `NOT NULL`, `DEFAULT 'USD'` | Валюта |
| `stripe_customer_id` | `VARCHAR(255)` | nullable | Stripe Customer ID |
| `stripe_subscription_id` | `VARCHAR(255)` | nullable | Stripe Subscription ID |
| `started_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Початок підписки |
| `expires_at` | `TIMESTAMPTZ` | nullable | Дата завершення |
| `cancelled_at` | `TIMESTAMPTZ` | nullable | Дата скасування |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата створення |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата оновлення |

Primary key: `subscriptions.id`

Foreign key: `subscriptions.user_id -> users.id`

Зв'язки:

- один користувач може мати багато записів підписок;
- одна підписка може мати багато платежів.

## 11. Таблиця Payments

Призначення: історія оплат через Stripe API у тестовому режимі.

| Поле | Тип даних | Обмеження | Опис |
| --- | --- | --- | --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Унікальний ідентифікатор платежу |
| `user_id` | `UUID` | `NOT NULL`, `FK -> users.id` | Користувач |
| `subscription_id` | `UUID` | `FK -> subscriptions.id` | Підписка |
| `amount_cents` | `INTEGER` | `NOT NULL`, `CHECK >= 0` | Сума у центах |
| `currency` | `CHAR(3)` | `NOT NULL`, `DEFAULT 'USD'` | Валюта |
| `status` | `fittrack_payment_status` | `NOT NULL`, `DEFAULT 'pending'` | Статус платежу |
| `stripe_payment_intent_id` | `VARCHAR(255)` | nullable | Stripe PaymentIntent ID |
| `stripe_checkout_session_id` | `VARCHAR(255)` | nullable | Stripe Checkout Session ID |
| `paid_at` | `TIMESTAMPTZ` | nullable | Час успішної оплати |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата створення |

Primary key: `payments.id`

Foreign keys:

- `payments.user_id -> users.id`
- `payments.subscription_id -> subscriptions.id`

Зв'язки:

- один користувач має багато платежів;
- одна підписка має багато платежів.

## 11.1. PaymentHistory

`payment_history` зберігає аудит зміни статусів платежів:

| Поле | Тип даних | Обмеження | Опис |
| --- | --- | --- | --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Ідентифікатор запису |
| `payment_id` | `UUID` | `NOT NULL`, `FK -> payments.id` | Платіж |
| `user_id` | `UUID` | `NOT NULL`, `FK -> users.id` | Користувач |
| `old_status` | `fittrack_payment_status` | nullable | Попередній статус |
| `new_status` | `fittrack_payment_status` | `NOT NULL` | Новий статус |
| `event_type` | `VARCHAR(80)` | `NOT NULL` | Тип події |
| `provider` | `VARCHAR(40)` | `NOT NULL`, `DEFAULT 'stripe'` | Платіжний провайдер |
| `mode` | `VARCHAR(10)` | `NOT NULL`, `DEFAULT 'test'` | Тільки тестовий режим |
| `stripe_event_id` | `VARCHAR(255)` | nullable | ID події Stripe webhook |
| `message` | `TEXT` | nullable | Додатковий опис |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Дата створення |

FitTrack не зберігає номери карток або CVV. У `payments` зберігаються тільки Stripe IDs, checkout URL, сума, статус і часові мітки.

## 12. ER-діаграма у текстовому вигляді

```text
USERS
  id PK
  firebase_uid UNIQUE
  email UNIQUE
  is_active
    |
    | 1 : 1
    v
PROFILES
  id PK
  user_id FK -> USERS.id UNIQUE
  full_name
  age
  gender
  height_cm
  weight_kg
  training_goal

USERS 1 : N WORKOUTS
WORKOUTS 1 : N WORKOUT_EXERCISES
EXERCISES 1 : N WORKOUT_EXERCISES
MUSCLE_GROUPS 1 : N EXERCISES

USERS 1 : N PROGRESS
WORKOUTS 1 : N PROGRESS

USERS 1 : N MEALS

USERS 1 : N SUBSCRIPTIONS
SUBSCRIPTIONS 1 : N PAYMENTS
USERS 1 : N PAYMENTS
PAYMENTS 1 : N PAYMENT_HISTORY

USERS N : M ROLES через USER_ROLES
ROLES N : M PERMISSIONS через ROLE_PERMISSIONS
USERS N : M USERS через TRAINER_CLIENTS
```

Детальніша ER-діаграма:

```text
+----------------+        +----------------+
|     USERS      | 1    1 |    PROFILES    |
|----------------|--------|----------------|
| id PK          |        | id PK          |
| firebase_uid   |        | user_id FK     |
| email          |        | full_name      |
| is_active      |        | age            |
+----------------+        +----------------+
        |
        | 1
        | N
+----------------+        +-----------------------+        +----------------+
|    WORKOUTS    | 1    N |   WORKOUT_EXERCISES   | N    1 |   EXERCISES    |
|----------------|--------|-----------------------|--------|----------------|
| id PK          |        | id PK                 |        | id PK          |
| user_id FK     |        | workout_id FK         |        | muscle_group_id|
| title          |        | exercise_id FK        |        | name           |
| is_completed   |        | sets_count            |        | difficulty     |
+----------------+        | reps_count            |        +----------------+
        |                 | weight_kg             |                |
        |                 | rest_seconds          |                | N
        |                 +-----------------------+                | 1
        |                                                  +----------------+
        |                                                  | MUSCLE_GROUPS  |
        |                                                  |----------------|
        |                                                  | id PK          |
        |                                                  | code UNIQUE    |
        |                                                  | name UNIQUE    |
        |                                                  +----------------+
        |
        | 1
        | N
+----------------+
|    PROGRESS    |
|----------------|
| id PK          |
| user_id FK     |
| workout_id FK  |
| progress_date  |
| weight_kg      |
+----------------+

+----------------+        +----------------+        +----------------+
|     USERS      | 1    N | SUBSCRIPTIONS  | 1    N |    PAYMENTS    |
|----------------|--------|----------------|--------|----------------|
| id PK          |        | id PK          |        | id PK          |
| email          |        | user_id FK     |        | user_id FK     |
| is_active      |        | plan           |        | subscription_id|
+----------------+        | status         |        | amount_cents   |
        |                 +----------------+        | status         |
        | 1                                       +----------------+
        | N
+----------------+
|     MEALS      |
|----------------|
| id PK          |
| user_id FK     |
| meal_date      |
| meal_type      |
| calories       |
| protein_g      |
| fat_g          |
| carbs_g        |
+----------------+
```

RBAC-зв'язки:

```text
+----------------+        +----------------+        +----------------+
|     USERS      | N    M |     ROLES      | N    M |  PERMISSIONS   |
|----------------|--------|----------------|--------|----------------|
| id PK          |        | id PK          |        | id PK          |
| firebase_uid   |        | code UNIQUE    |        | code UNIQUE    |
| email          |        | name           |        | resource       |
+----------------+        +----------------+        | action         |
        |                                          +----------------+
        | 1
        | N
+----------------+
| TRAINER_CLIENTS|
|----------------|
| trainer_id FK  |
| client_id FK   |
| status         |
+----------------+
```

## 13. Кардинальність зв'язків

| Зв'язок | Тип | Пояснення |
| --- | --- | --- |
| `users -> profiles` | `1:1` | Один акаунт має один профіль |
| `users -> workouts` | `1:N` | Один користувач створює багато тренувань |
| `muscle_groups -> exercises` | `1:N` | Одна група м'язів має багато вправ |
| `workouts -> workout_exercises` | `1:N` | Одне тренування містить багато вправ |
| `exercises -> workout_exercises` | `1:N` | Одна вправа може бути у багатьох тренуваннях |
| `workouts <-> exercises` | `N:M` | Реалізовано через `workout_exercises` |
| `users -> progress` | `1:N` | Один користувач має багато записів прогресу |
| `workouts -> progress` | `1:N` | Одне тренування може мати записи статистики |
| `users -> meals` | `1:N` | Один користувач має багато записів харчування |
| `users -> subscriptions` | `1:N` | Користувач може мати історію підписок |
| `subscriptions -> payments` | `1:N` | Одна підписка може мати багато платежів |
| `users -> payments` | `1:N` | Один користувач має історію платежів |
| `payments -> payment_history` | `1:N` | Один платіж має історію зміни статусів |
| `users <-> roles` | `N:M` | Користувач може мати кілька ролей, реалізовано через `user_roles` |
| `roles <-> permissions` | `N:M` | Роль містить набір permissions, реалізовано через `role_permissions` |
| `trainers <-> clients` | `N:M` | Тренер може мати багато клієнтів, клієнт може працювати з кількома тренерами |
