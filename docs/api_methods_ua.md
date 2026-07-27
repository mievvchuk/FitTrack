# FitTrack - REST API документація

## 1. Загальні правила API

Базовий URL:

```text
https://api.fittrack.example/api/v1
```

Для локального запуску:

```text
http://127.0.0.1:8000/api/v1
```

У документації нижче URL наведені без базового префікса `/api/v1`.

Захищені endpoints приймають access token:

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

Стандартний формат помилки:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request payload",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    }
  }
}
```

Типові HTTP-коди:

| Code | Значення |
| --- | --- |
| `200 OK` | Успішний GET/PUT/POST без створення нового ресурсу |
| `201 Created` | Ресурс створено |
| `204 No Content` | Ресурс видалено |
| `400 Bad Request` | Некоректний запит або бізнес-помилка |
| `401 Unauthorized` | Немає або невалідний токен |
| `403 Forbidden` | Недостатньо прав |
| `404 Not Found` | Ресурс не знайдено |
| `409 Conflict` | Конфлікт стану, наприклад email вже існує |
| `422 Unprocessable Entity` | Помилка валідації полів |
| `429 Too Many Requests` | Rate limit |
| `500 Internal Server Error` | Неочікувана помилка backend |

## 2. Authentication

### 2.1 POST `/register`

Реєструє нового користувача через email/password.

**Method:** `POST`

**URL:** `/register`

**Auth:** Public

**Request body:**

```json
{
  "email": "ivan@example.com",
  "password": "StrongPassword123!",
  "full_name": "Іван Петренко",
  "age": 22,
  "gender": "male",
  "height_cm": 180,
  "weight_kg": 78.5,
  "training_goal": "muscle_gain"
}
```

**Response `201 Created`:**

```json
{
  "id": "0f8fad5b-d9cb-469f-a165-70867728950e",
  "email": "ivan@example.com",
  "email_verified": false,
  "roles": ["user"],
  "profile": {
    "full_name": "Іван Петренко",
    "age": 22,
    "gender": "male",
    "height_cm": 180,
    "weight_kg": 78.5,
    "training_goal": "muscle_gain"
  },
  "message": "User registered. Please verify email."
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `400` | Пароль не відповідає security policy |
| `409` | Користувач з таким email вже існує |
| `422` | Некоректний email, вік, стать, зріст або вага |
| `429` | Забагато спроб реєстрації |

### 2.2 POST `/login`

Авторизує користувача та повертає access/refresh tokens.

**Method:** `POST`

**URL:** `/login`

**Auth:** Public

**Request body:**

```json
{
  "email": "ivan@example.com",
  "password": "StrongPassword123!",
  "device_id": "ios-iphone-15-pro"
}
```

**Response `200 OK`:**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "fittrack_refresh_token_value",
  "token_type": "bearer",
  "expires_in": 900,
  "user": {
    "id": "0f8fad5b-d9cb-469f-a165-70867728950e",
    "email": "ivan@example.com",
    "email_verified": true,
    "roles": ["user"],
    "permissions": [
      "exercises:read",
      "workouts:complete",
      "progress:manage",
      "premium:pay"
    ]
  }
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `400` | Email не підтверджено |
| `401` | Невірний email або пароль |
| `403` | Користувача заблоковано або деактивовано |
| `429` | Забагато спроб входу |

### 2.3 POST `/forgot-password`

Надсилає email для відновлення паролю.

**Method:** `POST`

**URL:** `/forgot-password`

**Auth:** Public

**Request body:**

```json
{
  "email": "ivan@example.com"
}
```

**Response `200 OK`:**

```json
{
  "message": "If an account with this email exists, password reset instructions were sent."
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `422` | Некоректний формат email |
| `429` | Забагато запитів на відновлення паролю |
| `500` | Помилка email provider або Firebase Auth |

## 3. Users

### 3.1 GET `/profile`

Повертає профіль поточного користувача.

**Method:** `GET`

**URL:** `/profile`

**Auth:** User

**Request body:** не потрібен.

**Response `200 OK`:**

```json
{
  "id": "54d4a95b-a7c2-471d-b0f2-4325479196d1",
  "user_id": "0f8fad5b-d9cb-469f-a165-70867728950e",
  "email": "ivan@example.com",
  "full_name": "Іван Петренко",
  "age": 22,
  "gender": "male",
  "height_cm": 180,
  "weight_kg": 78.5,
  "training_goal": "muscle_gain",
  "avatar_url": "https://cdn.fittrack.example/avatars/ivan.png",
  "updated_at": "2026-07-27T10:30:00Z"
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `404` | Профіль ще не створено |

### 3.2 PUT `/profile`

Повністю оновлює профіль поточного користувача.

**Method:** `PUT`

**URL:** `/profile`

**Auth:** User

**Request body:**

```json
{
  "full_name": "Іван Петренко",
  "age": 23,
  "gender": "male",
  "height_cm": 180,
  "weight_kg": 80.2,
  "training_goal": "strength",
  "avatar_url": "https://cdn.fittrack.example/avatars/ivan-new.png"
}
```

**Response `200 OK`:**

```json
{
  "id": "54d4a95b-a7c2-471d-b0f2-4325479196d1",
  "user_id": "0f8fad5b-d9cb-469f-a165-70867728950e",
  "full_name": "Іван Петренко",
  "age": 23,
  "gender": "male",
  "height_cm": 180,
  "weight_kg": 80.2,
  "training_goal": "strength",
  "avatar_url": "https://cdn.fittrack.example/avatars/ivan-new.png",
  "updated_at": "2026-07-27T11:00:00Z"
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `422` | Некоректний вік, стать, зріст, вага або training goal |

## 4. Exercises

### 4.1 GET `/exercises`

Повертає список вправ із фільтрами.

**Method:** `GET`

**URL:** `/exercises`

**Auth:** User

**Query parameters:**

```text
muscle_group=chest|back|legs|shoulders|arms|abs
difficulty=beginner|intermediate|advanced
equipment=barbell
search=bench
limit=20
offset=0
```

**Request body:** не потрібен.

**Response `200 OK`:**

```json
{
  "items": [
    {
      "id": "c34a94cb-9b11-47cf-9854-8acba1c4c442",
      "name": "Bench Press",
      "media_url": "https://cdn.fittrack.example/exercises/bench-press.gif",
      "media_type": "gif",
      "description": "Classic chest compound exercise.",
      "technique": "Lower the bar to the chest and press upward with stable shoulder position.",
      "common_mistakes": "Arching excessively, bouncing the bar, unstable wrists.",
      "muscle_group": "chest",
      "equipment": "Barbell, bench",
      "difficulty": "intermediate"
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `422` | Некоректний query parameter |

### 4.2 POST `/exercise`

Створює нову вправу. Доступно для `Trainer` або `Admin`.

**Method:** `POST`

**URL:** `/exercise`

**Auth:** Trainer/Admin

**Request body:**

```json
{
  "name": "Squat",
  "media_url": "https://cdn.fittrack.example/exercises/squat.gif",
  "media_type": "gif",
  "description": "Compound lower-body exercise.",
  "technique": "Keep chest up, knees aligned with toes, descend under control and stand up.",
  "common_mistakes": "Knees collapse inward, rounded back, heels lifting.",
  "muscle_group": "legs",
  "equipment": "Barbell",
  "difficulty": "intermediate"
}
```

**Response `201 Created`:**

```json
{
  "id": "78f80be1-0a4c-4a6e-8f57-f4c4d5d02487",
  "name": "Squat",
  "media_url": "https://cdn.fittrack.example/exercises/squat.gif",
  "media_type": "gif",
  "description": "Compound lower-body exercise.",
  "technique": "Keep chest up, knees aligned with toes, descend under control and stand up.",
  "common_mistakes": "Knees collapse inward, rounded back, heels lifting.",
  "muscle_group": "legs",
  "equipment": "Barbell",
  "difficulty": "intermediate",
  "is_active": true,
  "created_at": "2026-07-27T11:20:00Z"
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `403` | Немає permission `exercises:create` |
| `409` | Вправа з такою назвою вже існує |
| `422` | Некоректний muscle group, difficulty або media type |

### 4.3 PUT `/exercise`

Оновлює вправу за `exercise_id`. Доступно для `Trainer` або `Admin`.

**Method:** `PUT`

**URL:** `/exercise`

**Auth:** Trainer/Admin

**Request body:**

```json
{
  "exercise_id": "78f80be1-0a4c-4a6e-8f57-f4c4d5d02487",
  "name": "Barbell Squat",
  "media_url": "https://cdn.fittrack.example/exercises/barbell-squat.gif",
  "media_type": "gif",
  "description": "Compound squat variation with barbell.",
  "technique": "Brace the core, keep neutral spine and push through the mid-foot.",
  "common_mistakes": "Rounded back, shallow depth, knees collapsing inward.",
  "muscle_group": "legs",
  "equipment": "Barbell",
  "difficulty": "intermediate",
  "is_active": true
}
```

**Response `200 OK`:**

```json
{
  "id": "78f80be1-0a4c-4a6e-8f57-f4c4d5d02487",
  "name": "Barbell Squat",
  "muscle_group": "legs",
  "equipment": "Barbell",
  "difficulty": "intermediate",
  "is_active": true,
  "updated_at": "2026-07-27T11:45:00Z"
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `403` | Немає permission `exercises:update` |
| `404` | Вправу не знайдено |
| `422` | Некоректний request body |

### 4.4 DELETE `/exercise`

Видаляє або деактивує вправу за `exercise_id`. Рекомендовано soft delete через `is_active=false`, щоб не ламати історію тренувань.

**Method:** `DELETE`

**URL:** `/exercise`

**Auth:** Admin

**Request body:**

```json
{
  "exercise_id": "78f80be1-0a4c-4a6e-8f57-f4c4d5d02487"
}
```

**Response `204 No Content`:**

```json
{}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `403` | Немає permission `exercises:update` або роль не `admin` |
| `404` | Вправу не знайдено |
| `409` | Вправу не можна hard-delete, бо вона використовується у тренуваннях |

## 5. Workouts

### 5.1 GET `/workouts`

Повертає список тренувань поточного користувача.

**Method:** `GET`

**URL:** `/workouts`

**Auth:** User

**Query parameters:**

```text
is_completed=true|false
from=2026-07-01
to=2026-07-31
limit=20
offset=0
```

**Request body:** не потрібен.

**Response `200 OK`:**

```json
{
  "items": [
    {
      "id": "7ec7a11a-7e75-48a3-8ec0-b7ea5df16910",
      "title": "Push Day",
      "description": "Chest, shoulders, triceps",
      "training_goal": "muscle_gain",
      "scheduled_for": "2026-07-27",
      "estimated_duration_minutes": 60,
      "is_completed": false,
      "exercises_count": 4
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `422` | Некоректний date range або pagination |

### 5.2 POST `/workouts`

Створює нове тренування з вправами.

**Method:** `POST`

**URL:** `/workouts`

**Auth:** User

**Request body:**

```json
{
  "title": "Push Day",
  "description": "Chest, shoulders, triceps",
  "training_goal": "muscle_gain",
  "scheduled_for": "2026-07-27",
  "estimated_duration_minutes": 60,
  "exercises": [
    {
      "exercise_id": "c34a94cb-9b11-47cf-9854-8acba1c4c442",
      "order_index": 1,
      "sets_count": 4,
      "reps_count": 10,
      "weight_kg": 60,
      "rest_seconds": 90,
      "notes": "Warm up first set"
    }
  ]
}
```

**Response `201 Created`:**

```json
{
  "id": "7ec7a11a-7e75-48a3-8ec0-b7ea5df16910",
  "title": "Push Day",
  "description": "Chest, shoulders, triceps",
  "training_goal": "muscle_gain",
  "scheduled_for": "2026-07-27",
  "estimated_duration_minutes": 60,
  "is_completed": false,
  "exercises": [
    {
      "id": "96c93c43-2a46-46cf-8e73-bd8eb6157420",
      "exercise_id": "c34a94cb-9b11-47cf-9854-8acba1c4c442",
      "name": "Bench Press",
      "order_index": 1,
      "sets_count": 4,
      "reps_count": 10,
      "weight_kg": 60,
      "rest_seconds": 90
    }
  ],
  "created_at": "2026-07-27T12:00:00Z"
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `404` | Exercise ID не знайдено |
| `422` | Некоректні sets, reps, weight або rest seconds |

### 5.3 PUT `/workouts`

Оновлює тренування за `workout_id`.

**Method:** `PUT`

**URL:** `/workouts`

**Auth:** User

**Request body:**

```json
{
  "workout_id": "7ec7a11a-7e75-48a3-8ec0-b7ea5df16910",
  "title": "Updated Push Day",
  "description": "Chest focus",
  "training_goal": "strength",
  "scheduled_for": "2026-07-28",
  "estimated_duration_minutes": 70,
  "exercises": [
    {
      "exercise_id": "c34a94cb-9b11-47cf-9854-8acba1c4c442",
      "order_index": 1,
      "sets_count": 5,
      "reps_count": 5,
      "weight_kg": 80,
      "rest_seconds": 120
    }
  ]
}
```

**Response `200 OK`:**

```json
{
  "id": "7ec7a11a-7e75-48a3-8ec0-b7ea5df16910",
  "title": "Updated Push Day",
  "training_goal": "strength",
  "scheduled_for": "2026-07-28",
  "estimated_duration_minutes": 70,
  "is_completed": false,
  "exercises_count": 1,
  "updated_at": "2026-07-27T12:30:00Z"
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `403` | Користувач не є власником тренування |
| `404` | Тренування або вправа не знайдені |
| `409` | Завершене тренування не можна змінити |
| `422` | Некоректний request body |

### 5.4 DELETE `/workouts`

Видаляє тренування поточного користувача.

**Method:** `DELETE`

**URL:** `/workouts`

**Auth:** User

**Request body:**

```json
{
  "workout_id": "7ec7a11a-7e75-48a3-8ec0-b7ea5df16910"
}
```

**Response `204 No Content`:**

```json
{}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `403` | Користувач не є власником тренування |
| `404` | Тренування не знайдено |
| `409` | Тренування вже використане в історії прогресу |

## 6. Progress

### 6.1 POST `/progress`

Додає запис прогресу після тренування або ручного введення ваги.

**Method:** `POST`

**URL:** `/progress`

**Auth:** User

**Request body:**

```json
{
  "workout_id": "7ec7a11a-7e75-48a3-8ec0-b7ea5df16910",
  "progress_date": "2026-07-27",
  "weight_kg": 79.4,
  "body_fat_percent": 16.8,
  "total_volume_kg": 5820,
  "workout_duration_minutes": 62,
  "calories_burned": 480,
  "notes": "Good strength session"
}
```

**Response `201 Created`:**

```json
{
  "id": "6cbbec61-9c4f-40b7-8ac4-f29f62e676ce",
  "user_id": "0f8fad5b-d9cb-469f-a165-70867728950e",
  "workout_id": "7ec7a11a-7e75-48a3-8ec0-b7ea5df16910",
  "progress_date": "2026-07-27",
  "weight_kg": 79.4,
  "body_fat_percent": 16.8,
  "total_volume_kg": 5820,
  "workout_duration_minutes": 62,
  "calories_burned": 480,
  "created_at": "2026-07-27T13:00:00Z"
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `403` | Workout належить іншому користувачу |
| `404` | Workout не знайдено |
| `422` | Некоректна дата, вага, body fat або volume |

### 6.2 GET `/progress`

Повертає історію прогресу та агреговану статистику.

**Method:** `GET`

**URL:** `/progress`

**Auth:** User

**Query parameters:**

```text
from=2026-07-01
to=2026-07-31
limit=30
offset=0
```

**Request body:** не потрібен.

**Response `200 OK`:**

```json
{
  "items": [
    {
      "id": "6cbbec61-9c4f-40b7-8ac4-f29f62e676ce",
      "progress_date": "2026-07-27",
      "weight_kg": 79.4,
      "body_fat_percent": 16.8,
      "total_volume_kg": 5820,
      "workout_duration_minutes": 62,
      "calories_burned": 480
    }
  ],
  "stats": {
    "period": {
      "from": "2026-07-01",
      "to": "2026-07-31"
    },
    "total_workouts": 12,
    "total_volume_kg": 58200,
    "average_weight_kg": 79.8,
    "weight_change_kg": -1.2,
    "total_calories_burned": 5200
  },
  "total": 1,
  "limit": 30,
  "offset": 0
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `422` | Некоректний date range або pagination |

## 7. Payments

### 7.1 POST `/payment`

Створює тестовий платіж Premium через Stripe Checkout.

**Method:** `POST`

**URL:** `/payment`

**Auth:** User

**Request body:**

```json
{
  "plan": "premium",
  "success_url": "fittrack://payment-success",
  "cancel_url": "fittrack://payment-cancel"
}
```

**Response `201 Created`:**

```json
{
  "payment_id": "4d55dd81-4982-4f18-a996-ec9f110df9f4",
  "plan": "premium",
  "amount_cents": 999,
  "currency": "USD",
  "status": "pending",
  "provider": "stripe",
  "mode": "test",
  "stripe_checkout_session_id": "cs_test_a1B2c3",
  "checkout_url": "https://checkout.stripe.com/c/pay/cs_test_a1B2c3"
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `400` | Stripe key не test-mode або plan не підтримується |
| `401` | Access token відсутній або невалідний |
| `403` | Немає permission `premium:pay` |
| `422` | Некоректний success_url або cancel_url |
| `500` | Помилка Stripe API |

### 7.2 GET `/payments`

Повертає історію платежів поточного користувача.

**Method:** `GET`

**URL:** `/payments`

**Auth:** User

**Query parameters:**

```text
status=pending|succeeded|failed|cancelled|refunded
limit=20
offset=0
```

**Request body:** не потрібен.

**Response `200 OK`:**

```json
{
  "items": [
    {
      "id": "4d55dd81-4982-4f18-a996-ec9f110df9f4",
      "plan": "premium",
      "amount_cents": 999,
      "currency": "USD",
      "status": "succeeded",
      "provider": "stripe",
      "mode": "test",
      "stripe_checkout_session_id": "cs_test_a1B2c3",
      "paid_at": "2026-07-27T13:30:00Z",
      "created_at": "2026-07-27T13:20:00Z"
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `422` | Некоректний status або pagination |

## 8. Analytics

### 8.1 GET `/analytics/dashboard`

Returns a personal analytics dashboard for workouts, average weight, progress, calories, and activity.

**Method:** `GET`

**URL:** `/analytics/dashboard?days=30`

**Auth:** User with permission `analytics:read`

**Query parameters:**

```text
days=7|30|90
```

Backend accepts `days` from `7` to `365`.

**Response `200 OK`:**

```json
{
  "period": {
    "from_date": "2026-06-28",
    "to_date": "2026-07-27",
    "days": 30
  },
  "summary": {
    "workout_count": 12,
    "completed_workout_count": 10,
    "active_days": 18,
    "average_weight_kg": 78.4,
    "latest_weight_kg": 77.8,
    "weight_change_kg": -1.2,
    "progress_percent": -1.52,
    "total_volume_kg": 58200,
    "calories_burned": 5200,
    "calories_consumed": 64200,
    "average_daily_calories": 2140,
    "activity_score": 60
  },
  "weight_chart": [],
  "workout_activity_chart": [],
  "volume_chart": [],
  "calorie_chart": [],
  "activity": []
}
```

**Errors:**

| Code | Reason |
| --- | --- |
| `401` | Missing or invalid Bearer token |
| `403` | Missing permission `analytics:read` |
| `422` | Invalid `days` query parameter |

## 9. AI Fitness Assistant

### 9.1 POST `/ai-assistant/plans`

Generates a personal workout plan and nutrition recommendations through Z.AI.

**Method:** `POST`

**URL:** `/ai-assistant/plans`

**Auth:** User with permission `ai:generate`

**Request body:**

```json
{
  "goal": "muscle_gain",
  "weight_kg": 78,
  "height_cm": 178,
  "fitness_level": "beginner"
}
```

**Response `201 Created`:**

```json
{
  "id": "uuid",
  "user_id": "uuid",
  "goal": "muscle_gain",
  "weight_kg": 78,
  "height_cm": 178,
  "fitness_level": "beginner",
  "summary": "Short explanation of the generated plan",
  "workout_plan": {
    "weekly_schedule": [],
    "progression": []
  },
  "nutrition_recommendations": {
    "calories_per_day": 2400,
    "protein_g": 150,
    "fats_g": 75,
    "carbs_g": 280,
    "meals_per_day": 4,
    "hydration_liters": 2.5,
    "recommendations": []
  },
  "safety_notes": [],
  "model": "glm-5.2",
  "status": "generated",
  "created_at": "2026-07-27T12:00:00Z",
  "updated_at": "2026-07-27T12:00:00Z"
}
```

**Errors:**

| Code | Reason |
| --- | --- |
| `401` | Missing or invalid Bearer token |
| `403` | Missing permission `ai:generate` |
| `422` | Invalid goal, level, weight, or height |
| `429` | Too many generation requests |
| `502` | Z.AI API error or invalid AI response |
| `503` | `ZAI_API_KEY` is not configured |
| `504` | Z.AI request timeout |

### 9.2 GET `/ai-assistant/plans`

Returns saved AI plan history for the current user.

### 9.3 GET `/ai-assistant/plans/{plan_id}`

Returns one AI plan if it belongs to the current user.

## 10. Notifications

### 10.1 POST `/notifications/device-tokens`

Реєструє FCM token пристрою поточного користувача.

**Request body:**

```json
{
  "fcm_token": "fcm_registration_token",
  "platform": "android",
  "device_id": "optional-device-id",
  "app_version": "0.1.0"
}
```

**Response `201 Created`:**

```json
{
  "id": "uuid",
  "user_id": "uuid",
  "platform": "android",
  "device_id": "optional-device-id",
  "app_version": "0.1.0",
  "is_active": true,
  "last_seen_at": "2026-07-27T12:00:00Z",
  "created_at": "2026-07-27T12:00:00Z",
  "updated_at": "2026-07-27T12:00:00Z"
}
```

### 10.2 GET `/notifications`

Повертає історію повідомлень користувача.

**Response `200 OK`:**

```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "type": "workout_reminder",
    "title": "Workout reminder",
    "body": "Today planned workout: Push Day",
    "data": {
      "workout_id": "uuid"
    },
    "status": "sent",
    "sent_at": "2026-07-27T12:00:00Z",
    "read_at": null,
    "created_at": "2026-07-27T12:00:00Z",
    "updated_at": "2026-07-27T12:00:00Z"
  }
]
```

### 10.3 PUT `/notifications/preferences`

Оновлює налаштування повідомлень.

**Request body:**

```json
{
  "workout_reminders_enabled": true,
  "workout_reminder_time": "09:00:00",
  "payment_notifications_enabled": true,
  "premium_expiration_enabled": true,
  "premium_expiration_days_before": 3
}
```

**Помилки:**

| Code | Причина |
| --- | --- |
| `401` | Access token відсутній або невалідний |
| `422` | Некоректний FCM token, platform або preferences |

## 11. Коротка таблиця endpoints

| Group | Method | URL | Auth |
| --- | --- | --- | --- |
| Authentication | `POST` | `/register` | Public |
| Authentication | `POST` | `/login` | Public |
| Authentication | `POST` | `/forgot-password` | Public |
| Users | `GET` | `/profile` | User |
| Users | `PUT` | `/profile` | User |
| Exercises | `GET` | `/exercises` | User |
| Exercises | `POST` | `/exercise` | Trainer/Admin |
| Exercises | `PUT` | `/exercise` | Trainer/Admin |
| Exercises | `DELETE` | `/exercise` | Admin |
| Workouts | `GET` | `/workouts` | User |
| Workouts | `POST` | `/workouts` | User |
| Workouts | `PUT` | `/workouts` | User |
| Workouts | `DELETE` | `/workouts` | User |
| Progress | `POST` | `/progress` | User |
| Progress | `GET` | `/progress` | User |
| Payments | `POST` | `/payment` | User |
| Payments | `GET` | `/payments` | User |
| Analytics | `GET` | `/analytics/dashboard` | User |
| AI Assistant | `POST` | `/ai-assistant/plans` | User |
| AI Assistant | `GET` | `/ai-assistant/plans` | User |
| AI Assistant | `GET` | `/ai-assistant/plans/{plan_id}` | User |
| Notifications | `POST` | `/notifications/device-tokens` | User |
| Notifications | `GET` | `/notifications` | User |
| Notifications | `PUT` | `/notifications/preferences` | User |

## 12. Примітки для реалізації

- Для production REST стилю можна розширити `PUT /exercise` до `PUT /exercises/{exercise_id}` і `DELETE /exercise` до `DELETE /exercises/{exercise_id}`. У цьому документі залишено URL зі списку вимог курсового завдання.
- Для `PUT /workouts` і `DELETE /workouts` ідентифікатор передається в request body як `workout_id`.
- Для платежів використовується тільки Stripe test mode.
- FitTrack backend не зберігає номери карток, CVV або банківські реквізити.
- Усі admin/trainer права перевіряються на backend через roles і permissions.
