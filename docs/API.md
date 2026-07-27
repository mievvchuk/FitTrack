# FitTrack API Documentation

FitTrack exposes a REST API for the Flutter mobile application, trainer workflows, admin workflows, analytics, notifications, AI plan generation, and Premium test payments.

## Base URLs

Local development:

```text
http://127.0.0.1:8000/api/v1
```

Android emulator:

```text
http://10.0.2.2:8000/api/v1
```

Production example:

```text
https://api.fittrack.example/api/v1
```

## Authentication

Protected endpoints require a Bearer token:

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

The backend supports Firebase ID token verification and a FitTrack JWT access/refresh token flow.

## Standard Error Shape

```json
{
  "detail": "Human-readable error message"
}
```

Validation errors use the default FastAPI/Pydantic validation response.

## Endpoint Summary

| Area | Method | Endpoint | Access |
| --- | --- | --- | --- |
| Health | `GET` | `/health` | Public |
| Auth | `POST` | `/auth/register` | Public |
| Auth | `POST` | `/auth/login` | Public |
| Auth | `POST` | `/auth/refresh` | Public |
| Auth | `POST` | `/auth/forgot-password` | Public |
| Auth | `POST` | `/auth/change-password` | User |
| Auth | `GET` | `/auth/me` | User |
| Profile | `GET` | `/profile` | User |
| Profile | `PUT` | `/profile` | User |
| Exercises | `GET` | `/exercises` | User |
| Exercises | `POST` | `/exercises` | Trainer/Admin |
| Exercises | `PUT` | `/exercises/{exercise_id}` | Trainer/Admin |
| Exercises | `DELETE` | `/exercises/{exercise_id}` | Admin |
| Workouts | `GET` | `/workouts` | User |
| Workouts | `POST` | `/workouts` | User |
| Workouts | `PUT` | `/workouts/{workout_id}` | User |
| Workouts | `DELETE` | `/workouts/{workout_id}` | User |
| Progress | `GET` | `/progress` | User |
| Progress | `POST` | `/progress` | User |
| Nutrition | `GET` | `/meals` | User |
| Nutrition | `POST` | `/meals` | User |
| Payments | `GET` | `/subscription/payments` | User |
| Payments | `POST` | `/subscription/checkout-session` | User |
| Payments | `POST` | `/subscription/webhook/stripe` | Stripe webhook |
| Analytics | `GET` | `/analytics/dashboard` | User |
| Notifications | `GET` | `/notifications` | User |
| Notifications | `POST` | `/notifications/device-tokens` | User |
| AI Assistant | `POST` | `/ai-assistant/plans` | User |
| AI Assistant | `GET` | `/ai-assistant/plans` | User |
| Admin | `GET` | `/admin/users` | Admin |
| Admin | `GET` | `/admin/payments` | Admin |

## Main Request Examples

### Register

```http
POST /api/v1/auth/register
```

```json
{
  "email": "student@example.com",
  "password": "StrongPassword123!",
  "full_name": "Student User"
}
```

### Login

```http
POST /api/v1/auth/login
```

```json
{
  "email": "student@example.com",
  "password": "StrongPassword123!",
  "device_id": "android-emulator"
}
```

### Create Workout

```http
POST /api/v1/workouts
```

```json
{
  "title": "Push Day",
  "scheduled_for": "2026-07-27",
  "estimated_duration_minutes": 60,
  "exercises": [
    {
      "exercise_id": "00000000-0000-0000-0000-000000000000",
      "sets_count": 4,
      "reps_count": 10,
      "weight_kg": 60,
      "rest_seconds": 90
    }
  ]
}
```

### Create Premium Checkout Session

```http
POST /api/v1/subscription/checkout-session
```

```json
{
  "plan": "premium"
}
```

## Detailed Documentation

Detailed coursework-oriented API documentation is available in:

- `docs/api_methods_ua.md`
- `http://127.0.0.1:8000/docs` after starting the backend
