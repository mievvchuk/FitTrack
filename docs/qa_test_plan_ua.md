# FitTrack - план тестування

## 1. Мета тестування

Мета тестування FitTrack - перевірити коректність, стабільність і безпеку мобільного застосунку, backend API, PostgreSQL бази даних, role-based access control та Stripe test payment flow.

План охоплює:

- Unit tests;
- Integration tests;
- UI tests;
- тест-кейси;
- очікувані результати;
- приклади тестів.

## 2. Об'єкт тестування

Система FitTrack складається з:

- Flutter mobile app;
- FastAPI backend;
- PostgreSQL database;
- Firebase Authentication;
- FitTrack JWT security layer;
- Stripe test API;
- RBAC ролей `User`, `Trainer`, `Admin`.

## 3. Поточний стан тестів

На момент підготовки QA-плану:

- `mobile/test/widget_test.dart` містить placeholder test;
- `backend/tests` створена як папка, але тестів ще немає;
- backend має модулі, які можна покривати `pytest`;
- Flutter має структуру, яку можна покривати `flutter_test` та `integration_test`.

## 4. Рекомендовані бібліотеки

### Backend

| Призначення | Бібліотека |
| --- | --- |
| Unit/integration tests | `pytest` |
| Coverage | `pytest-cov` |
| FastAPI API tests | `fastapi.testclient.TestClient` або `httpx` |
| Async tests | `pytest-asyncio` |
| PostgreSQL integration | `testcontainers[postgresql]` або `pytest-postgresql` |
| Test factories | `factory_boy` |
| Time-based tests | `freezegun` |
| Mocking Stripe/Firebase | `pytest monkeypatch`, `unittest.mock` |

Рекомендовано додати в `backend/requirements-dev.txt`:

```text
pytest>=8.0.0
pytest-cov>=5.0.0
pytest-asyncio>=0.23.0
httpx>=0.27.0
testcontainers[postgresql]>=4.8.0
factory_boy>=3.3.0
freezegun>=1.5.0
```

### Flutter

| Призначення | Бібліотека |
| --- | --- |
| Unit/widget tests | `flutter_test` |
| Integration tests | `integration_test` |
| Mocking | `mocktail` |
| Golden tests | `golden_toolkit` |
| Advanced app flows | `patrol` |

Рекомендовано додати в `mobile/pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^1.0.4
  golden_toolkit: ^0.15.0
```

## 5. Тестове середовище

### Local

- Flutter SDK;
- Android Emulator або iOS Simulator;
- FastAPI backend на `http://127.0.0.1:8000`;
- PostgreSQL local database;
- Stripe test keys;
- Firebase test project.

### CI

Рекомендовано:

- GitHub Actions;
- PostgreSQL service container;
- backend: `pytest --cov`;
- Flutter: `flutter test`;
- static analysis: `flutter analyze`, Python linting.

## 6. Тестові дані

| Назва | Значення |
| --- | --- |
| Test user email | `user@test.fittrack.local` |
| Test trainer email | `trainer@test.fittrack.local` |
| Test admin email | `admin@test.fittrack.local` |
| Test password | `TestPassword123!` |
| Stripe mode | `test` |
| Premium price | `999` cents |
| Test exercise | `Bench Press` |
| Test workout | `Push Day` |

## 7. Unit Tests

### 7.1. Authentication

| ID | Тест-кейс | Передумови | Кроки | Очікуваний результат | Пріоритет |
| --- | --- | --- | --- | --- | --- |
| AUTH-U01 | Password hash не дорівнює plain password | Є пароль `TestPassword123!` | Викликати `hash_password` | Hash створено, hash != plain password | High |
| AUTH-U02 | Правильний пароль проходить перевірку | Є hash пароля | Викликати `verify_password(correct)` | Повертає `true` | High |
| AUTH-U03 | Неправильний пароль відхиляється | Є hash пароля | Викликати `verify_password(wrong)` | Повертає `false` | High |
| AUTH-U04 | JWT містить correct claims | Є активний користувач | Створити access token | Є `sub`, `email`, `roles`, `permissions`, `exp`, `iss`, `aud` | High |
| AUTH-U05 | Expired JWT відхиляється | Є expired token | Викликати decode | Виникає auth error | High |
| AUTH-U06 | Refresh token зберігається як digest | Є refresh token | Викликати `token_digest` і записати в DB | У DB немає plaintext token | High |
| AUTH-U07 | Email verification token підтверджує email | Є verification token | Викликати `verify_email_token` | `email_verified_at` заповнено | High |
| AUTH-U08 | Expired verification token відхиляється | Token expired | Викликати verify | 400 error | Medium |
| AUTH-U09 | Account lockout після невдалих спроб | User має 5 failed attempts | Виконати login | `locked_until` встановлено | High |

### 7.2. Calculations

| ID | Тест-кейс | Вхідні дані | Очікуваний результат | Пріоритет |
| --- | --- | --- | --- | --- |
| CALC-U01 | Розрахунок workout volume | 4 sets, 10 reps, 60 kg | `2400 kg` | High |
| CALC-U02 | Сума calories за день | 420 + 700 + 580 | `1700` | Medium |
| CALC-U03 | Сума білків/жирів/вуглеводів | meals list | Коректний total P/F/C | Medium |
| CALC-U04 | Progress delta ваги | 80.0 -> 78.5 | `-1.5 kg` | Medium |
| CALC-U05 | Premium price label | `999`, `USD` | `USD 9.99` | Low |
| CALC-U06 | Валідація rest seconds | `-30` | Validation error | Medium |

### 7.3. Business Logic

| ID | Тест-кейс | Передумови | Кроки | Очікуваний результат | Пріоритет |
| --- | --- | --- | --- | --- | --- |
| BL-U01 | User має базові permissions | Роль `user` | Отримати permissions | Є `workouts:complete`, `exercises:read`, `progress:manage`, `premium:pay` | High |
| BL-U02 | Trainer має trainer permissions | Роль `trainer` | Отримати permissions | Є `programs:create`, `clients:read` | High |
| BL-U03 | Admin має payments permission | Роль `admin` | Отримати permissions | Є `payments:read` | High |
| BL-U04 | Non-admin не може переглядати платежі | User token | Запит `/admin/payments` | 403 Forbidden | High |
| BL-U05 | Premium activation після succeeded payment | Payment `pending` | Mark succeeded | Subscription `premium`, status `active` | High |
| BL-U06 | Non-test Stripe key відхиляється | `sk_live_...` | Create checkout | 400 error | High |
| BL-U07 | Workout exercise має валідні sets/reps | sets=0 | Validate input | Validation error | Medium |
| BL-U08 | Trainer бачить тільки своїх clients | Є trainer_clients | GET clients | Повертаються тільки assigned clients | High |

## 8. Integration Tests

### 8.1. API Integration

| ID | Тест-кейс | Endpoint | Кроки | Очікуваний результат | Пріоритет |
| --- | --- | --- | --- | --- | --- |
| API-I01 | Register user | `POST /auth/register` | Надіслати email/password | 201, повертається verification token demo | High |
| API-I02 | Verify email | `POST /auth/verify-email` | Надіслати token | 200, `email_verified=true` | High |
| API-I03 | Login | `POST /auth/login` | Надіслати email/password | 200, access + refresh token | High |
| API-I04 | Refresh token | `POST /auth/refresh` | Надіслати refresh token | 200, нова token pair | High |
| API-I05 | Logout | `POST /auth/logout` | Надіслати refresh token | 204, token revoked | Medium |
| API-I06 | Authenticated me | `GET /auth/me` | Bearer access token | 200, user data | High |
| API-I07 | Validation error | invalid payload | Надіслати короткий password | 422 | Medium |
| API-I08 | Permission denied | `/admin/payments` | Bearer user token | 403 | High |
| API-I09 | Admin payments | `/admin/payments` | Bearer admin token | 200, payment list | High |

### 8.2. Database Integration

| ID | Тест-кейс | Кроки | Очікуваний результат | Пріоритет |
| --- | --- | --- | --- | --- |
| DB-I01 | Schema creates successfully | Виконати `course_schema.sql` | Таблиці створені без помилок | High |
| DB-I02 | Users email unique | Insert same email twice | Другий insert rejected | High |
| DB-I03 | User profile cascade delete | Delete user | Profile видалено cascade | Medium |
| DB-I04 | Role permissions relation | Insert role permission | Permission доступний через роль | High |
| DB-I05 | Refresh token digest unique | Insert duplicate hash | Duplicate rejected | High |
| DB-I06 | Payment history cascade | Delete payment | History видалено cascade | Medium |
| DB-I07 | Workout FK integrity | Insert workout_exercise with missing exercise | FK error | Medium |

### 8.3. Payments Integration

| ID | Тест-кейс | Кроки | Очікуваний результат | Пріоритет |
| --- | --- | --- | --- | --- |
| PAY-I01 | Create checkout session | POST `/subscription/checkout-session` | Payment `pending`, є `checkout_url` | High |
| PAY-I02 | Confirm test payment | POST `/payments/{id}/confirm-test` | Payment `succeeded`, subscription `premium` | High |
| PAY-I03 | Payment status | GET `/payments/{id}` | Повертається актуальний status | High |
| PAY-I04 | Payment history | GET `/payments/{id}/history` | Є події `checkout_created`, `manual_test_confirmation` | High |
| PAY-I05 | Stripe webhook completed | Send signed webhook | Payment `succeeded` | High |
| PAY-I06 | Stripe webhook invalid signature | Send invalid signature | 400 error | High |
| PAY-I07 | Live Stripe key rejected | Set `sk_live_...` | 400 error | High |

## 9. UI Tests

### 9.1. Login

| ID | Тест-кейс | Кроки | Очікуваний результат | Пріоритет |
| --- | --- | --- | --- | --- |
| UI-LOGIN-01 | Login screen renders | Відкрити app | Є поля email/password і кнопка login | High |
| UI-LOGIN-02 | Empty form validation | Натиснути login без даних | Показано validation messages | High |
| UI-LOGIN-03 | Invalid password | Ввести wrong password | Показано error state | High |
| UI-LOGIN-04 | Successful login | Ввести valid credentials | Перехід на Home Dashboard | High |
| UI-LOGIN-05 | Forgot password navigation | Tap forgot password | Відкрито Forgot Password screen | Medium |
| UI-LOGIN-06 | Google Sign-In button | Tap Google | Запускається Google auth flow | Medium |

### 9.2. Workout Creation

| ID | Тест-кейс | Кроки | Очікуваний результат | Пріоритет |
| --- | --- | --- | --- | --- |
| UI-WORKOUT-01 | Open workout builder | Home -> Workouts | Workouts screen відкрито | High |
| UI-WORKOUT-02 | Create workout | Ввести title, goal | Workout draft створено | High |
| UI-WORKOUT-03 | Add exercise | Select Bench Press | Exercise додано у workout | High |
| UI-WORKOUT-04 | Set exercise params | weight=60, sets=4, reps=10, rest=90 | Значення збережено | High |
| UI-WORKOUT-05 | Invalid params | sets=0 | Показано validation error | Medium |
| UI-WORKOUT-06 | Complete workout | Tap complete | Workout status completed, progress оновлено | High |

### 9.3. Subscription Purchase

| ID | Тест-кейс | Кроки | Очікуваний результат | Пріоритет |
| --- | --- | --- | --- | --- |
| UI-SUB-01 | Premium screen renders | Open Premium | Є Free і Premium plans | High |
| UI-SUB-02 | Start checkout | Tap Start test checkout | Checkout screen відкрито | High |
| UI-SUB-03 | Create payment | Tap Create test payment | Payment ID і status `pending` показані | High |
| UI-SUB-04 | Open Stripe Checkout | Tap Open Stripe Checkout | Відкрито external Stripe URL | Medium |
| UI-SUB-05 | Confirm test payment | Tap Confirm test payment | Перехід на Payment Success | High |
| UI-SUB-06 | View payment history | Open Payment History | Є payment з status `succeeded` | High |

## 10. Приклади тестів

### 10.1. Backend unit test: password hashing

```python
from app.services.auth_security_service import hash_password, verify_password


def test_password_hash_is_not_plain_text():
    password = "TestPassword123!"

    password_hash = hash_password(password)

    assert password_hash != password
    assert verify_password(password, password_hash) is True
    assert verify_password("WrongPassword123!", password_hash) is False
```

### 10.2. Backend unit test: JWT claims

```python
from app.services.auth_security_service import create_access_token, decode_access_token


def test_access_token_contains_expected_claims(settings, user):
    token = create_access_token(user, settings)

    claims = decode_access_token(token, settings)

    assert claims["sub"] == str(user.id)
    assert claims["email"] == user.email
    assert claims["type"] == "access"
    assert "exp" in claims
```

### 10.3. Backend business logic test: permission denied

```python
from fastapi import HTTPException

from app.core.security import require_permission


def test_user_without_permission_gets_403(user_without_admin_permissions):
    dependency = require_permission("payments:read")

    try:
        dependency(user_without_admin_permissions)
        assert False, "Expected HTTPException"
    except HTTPException as exc:
        assert exc.status_code == 403
```

### 10.4. Backend integration test: auth API

```python
def test_register_verify_login_flow(client):
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "user@test.fittrack.local",
            "password": "TestPassword123!",
        },
    )
    assert register_response.status_code == 201

    verification_token = register_response.json()["verification_token_demo"]

    verify_response = client.post(
        "/api/v1/auth/verify-email",
        json={"token": verification_token},
    )
    assert verify_response.status_code == 200
    assert verify_response.json()["email_verified"] is True

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "user@test.fittrack.local",
            "password": "TestPassword123!",
        },
    )
    assert login_response.status_code == 200
    assert login_response.json()["access_token"]
    assert login_response.json()["refresh_token"]
```

### 10.5. Backend integration test: payment confirmation

```python
def test_confirm_test_payment_activates_premium(client, user_access_token, payment_id):
    response = client.post(
        f"/api/v1/subscription/payments/{payment_id}/confirm-test",
        headers={"Authorization": f"Bearer {user_access_token}"},
    )

    assert response.status_code == 200
    assert response.json()["status"] == "succeeded"
    assert response.json()["mode"] == "test"
```

### 10.6. Flutter unit test: price label

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/features/payments/data/models/subscription_plan_model.dart';

void main() {
  test('premium price label is formatted from cents', () {
    final plan = SubscriptionPlanModel(
      code: 'premium',
      name: 'Premium',
      priceCents: 999,
      currency: 'USD',
      features: const <String>[],
    );

    expect(plan.priceLabel, 'USD 9.99');
  });
}
```

### 10.7. Flutter widget test: login screen renders

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('login screen renders email and password fields', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    expect(find.textContaining('Google'), findsOneWidget);
  });
}
```

### 10.8. Flutter UI/integration test: subscription purchase

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can start premium checkout flow', (tester) async {
    // app.main() should be started here after test dependency setup.
    // await app.main();
    // await tester.pumpAndSettle();

    await tester.tap(find.text('Premium'));
    await tester.pumpAndSettle();

    expect(find.text('FitTrack Premium'), findsOneWidget);

    await tester.tap(find.text('Start test checkout'));
    await tester.pumpAndSettle();

    expect(find.text('Stripe test payment'), findsOneWidget);
  });
}
```

## 11. Entry Criteria

Тестування починається, коли:

- backend встановлюється без помилок;
- PostgreSQL schema застосовується без помилок;
- Flutter dependencies встановлюються через `flutter pub get`;
- Firebase test project налаштований;
- Stripe test key доступний;
- базові env-змінні заповнені.

## 12. Exit Criteria

Тестування вважається успішним, якщо:

- 100% High priority тестів passed;
- немає critical/high bugs;
- auth, RBAC і payments мають integration coverage;
- UI smoke сценарії проходять на Android emulator;
- database integrity tests проходять;
- `flutter analyze` і `pytest` проходять у CI.

## 13. Ризики

| Ризик | Вплив | Як зменшити |
| --- | --- | --- |
| Firebase config placeholder | Login tests не проходять | Використати test Firebase project |
| Stripe webhook локально складний | Payment webhook tests flaky | Використати manual `confirm-test` і окремо Stripe CLI |
| Flutter SDK не встановлений | UI tests не запускаються | Додати Flutter SDK у PATH/CI |
| PostgreSQL test DB не ізольована | Тести впливають на dev data | Використовувати testcontainers |
| Rate limiting блокує API tests | Flaky auth tests | Окремий test config або reset limiter storage |

## 14. Пріоритет реалізації тестів

1. Auth unit tests.
2. RBAC permission tests.
3. Payment business logic tests.
4. API integration tests для auth і payments.
5. DB integrity tests.
6. Flutter unit/widget tests для login і Premium.
7. UI integration tests для workout creation.
8. CI pipeline з coverage.
