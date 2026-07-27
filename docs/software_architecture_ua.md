# FitTrack - програмна архітектура системи

## 1. Призначення документа

Цей документ описує програмну архітектуру FitTrack як мобільної client-server системи на базі Flutter, FastAPI та PostgreSQL. Архітектура побудована як модульний моноліт backend-частини з чітким поділом на шари: Client Layer, API Layer, Business Logic Layer, Data Access Layer та Database Layer.

Основний потік взаємодії:

```text
Mobile App -> API Gateway -> FastAPI Backend -> PostgreSQL Database
                                  |
                                  +-> Firebase Authentication
                                  +-> Stripe Test API
                                  +-> Media/Object Storage
```

## 2. Архітектурний стиль

FitTrack використовує такі архітектурні підходи:

- Client-server architecture: мобільний застосунок є клієнтом, backend відповідає за API, бізнес-правила та інтеграції.
- Clean Architecture у Flutter: `presentation`, `domain`, `data` всередині feature-модулів.
- Layered Architecture у backend: API routers, services, repositories, ORM models.
- Modular Monolith: backend розділений на модулі auth, profile, exercises, workouts, progress, nutrition, payments, admin, але деплоїться як один FastAPI service.
- REST API: взаємодія mobile/backend через HTTPS JSON endpoints.
- RBAC: ролі `User`, `Trainer`, `Admin` та permission-based access checks.
- Externalized authentication: Firebase Authentication виконує email/password, Google Sign-In, password reset/change.
- Test payment integration: Stripe використовується тільки в test mode.

## 3. Layered Architecture

```mermaid
flowchart TB
    Client["Client Layer\nFlutter Android/iOS"]
    API["API Layer\nAPI Gateway + FastAPI Routers"]
    Business["Business Logic Layer\nServices + Use Cases + Policies"]
    DataAccess["Data Access Layer\nRepositories + SQLAlchemy Sessions"]
    Database["Database Layer\nPostgreSQL Schema + Constraints + Indexes"]
    External["External Services\nFirebase Auth, Stripe Test API, Media Storage"]

    Client -->|HTTPS REST + Bearer Token| API
    API -->|Validated DTOs| Business
    Business -->|Repository calls| DataAccess
    DataAccess -->|SQL queries / transactions| Database
    Business -->|Token verification / payments / media| External
```

## 4. Client Layer

Client Layer - це Flutter mobile app для Android та iOS.

### Відповідальність

- Відображення UI: login, dashboard, exercise library, workout builder, progress, profile, premium, admin/trainer screens.
- Управління станом через Riverpod providers.
- Навігація через GoRouter.
- Виклик backend REST API через Dio.
- Авторизація користувача через Firebase SDK.
- Локальне біометричне розблокування через Face ID / Touch ID.
- Безпечне збереження токенів через Flutter Secure Storage.
- Валідація форм на клієнті для кращого UX.
- Відображення помилок API у зрозумілій для користувача формі.

### Основні компоненти

| Компонент | Призначення |
| --- | --- |
| `Presentation Screens` | Екрани та widgets |
| `Riverpod Providers` | State management |
| `Use Cases` | Клієнтські сценарії feature-модулів |
| `Repositories` | Абстракція над Firebase/Auth/API джерелами |
| `Dio ApiClient` | HTTP-клієнт для backend |
| `Firebase Auth SDK` | Email/password, Google Sign-In, password reset/change |
| `Local Auth` | Face ID / Touch ID |
| `Secure Storage` | Access/refresh tokens, biometric flag |

### Clean Architecture у Flutter

```text
lib/
  core/
    config/
    network/
    storage/
    navigation/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    exercises/
    workouts/
    progress/
    payments/
    profile/
```

Client Layer не містить критичних бізнес-правил доступу. Навіть якщо Flutter приховує admin screens, остаточна перевірка прав завжди виконується на backend.

## 5. API Layer

API Layer складається з API Gateway/reverse proxy та FastAPI routers.

### API Gateway

У production API Gateway може бути реалізований через Nginx, Traefik або cloud load balancer.

Відповідальність:

- прийом HTTPS traffic;
- TLS termination;
- маршрутизація запитів до FastAPI container;
- базові limits на розмір request body;
- proxy headers;
- health checks;
- можливе centralized access logging.

### FastAPI API Layer

Відповідальність:

- REST endpoints;
- request/response validation через Pydantic schemas;
- OpenAPI documentation;
- CORS policy;
- TrustedHost middleware;
- security headers;
- rate limiting;
- JWT/Firebase Bearer token parsing;
- dependency-based permission checks;
- передача валідованих DTO у Business Logic Layer.

### API modules

| API module | Приклади endpoints |
| --- | --- |
| Auth API | `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/me` |
| Roles API | `/roles`, `/permissions`, `/users/{id}/roles` |
| Exercises API | `/exercises`, `/muscle-groups` |
| Workouts API | `/workouts`, `/workouts/{id}/exercises` |
| Progress API | `/progress`, `/progress/stats` |
| Nutrition API | `/meals`, `/meals/daily-summary` |
| Subscription API | `/subscription/plans`, `/subscription/checkout-session`, `/subscription/payments` |
| Admin API | `/admin/users`, `/admin/payments`, `/admin/exercises` |

## 6. Business Logic Layer

Business Logic Layer містить application services, use cases та domain policies.

### Відповідальність

- Перевірка бізнес-правил.
- RBAC та permission-based доступ.
- Створення та завершення тренувань.
- Розрахунок статистики прогресу.
- Розрахунок training volume: `sets * reps * weight`.
- Ведення nutrition totals: calories, proteins, fats, carbohydrates.
- Premium subscription lifecycle.
- Створення Stripe test checkout session.
- Обробка Stripe webhook.
- Синхронізація Firebase user з локальним `users`.
- Audit trail для payment history.
- Transaction boundaries для критичних операцій.

### Основні services

| Service | Призначення |
| --- | --- |
| `AuthSecurityService` | Password hash, JWT, refresh tokens, email verification |
| `RBACService` | Roles, permissions, trainer-client access |
| `ProfileService` | CRUD профілю користувача |
| `ExerciseService` | Exercise library та admin exercise management |
| `WorkoutService` | Workout builder, exercises у тренуванні, completion |
| `ProgressService` | Weight chart, history, statistics |
| `NutritionService` | Meals та daily macro totals |
| `PaymentService` | Stripe test payments, subscriptions, payment history |
| `AdminService` | User management, payment review |

### Приклад business flow: Premium

```text
User opens Premium screen
Flutter calls POST /subscription/checkout-session
API validates JWT and permission premium:pay
PaymentService creates local pending payment
PaymentService creates Stripe Checkout Session in test mode
Flutter opens Stripe Checkout URL
Stripe webhook confirms payment
PaymentService marks payment succeeded
PaymentService activates Premium subscription
Flutter reads updated subscription status
```

## 7. Data Access Layer

Data Access Layer ізолює Business Logic Layer від конкретної реалізації PostgreSQL.

### Відповідальність

- SQLAlchemy ORM sessions.
- Repository methods для CRUD.
- Управління transactions.
- Query composition.
- Pagination та filtering.
- Mapping ORM models до DTO/entities.
- Alembic migrations.
- Захист від SQL injection через параметризовані SQLAlchemy queries.

### Основні repository groups

| Repository | Дані |
| --- | --- |
| `UserRepository` | `users`, `profiles`, `user_roles` |
| `RoleRepository` | `roles`, `permissions`, `role_permissions` |
| `ExerciseRepository` | `exercises`, `muscle_groups` |
| `WorkoutRepository` | `workouts`, `workout_exercises` |
| `ProgressRepository` | `progress` |
| `MealRepository` | `meals` |
| `SubscriptionRepository` | `subscriptions` |
| `PaymentRepository` | `payments`, `payment_history` |
| `TokenRepository` | `refresh_tokens`, `email_verification_tokens` |

## 8. Database Layer

Database Layer - PostgreSQL database з нормалізованою схемою.

### Відповідальність

- Надійне збереження даних.
- Primary keys на UUID.
- Foreign keys між сутностями.
- Constraints для коректності даних.
- Indexes для пошуку та історичних вибірок.
- Enum types для стабільних статусів.
- Audit records для payments.
- Alembic migration history.

### Основні таблиці

| Domain | Tables |
| --- | --- |
| Users/Auth | `users`, `profiles`, `refresh_tokens`, `email_verification_tokens` |
| RBAC | `roles`, `permissions`, `role_permissions`, `user_roles`, `trainer_clients` |
| Exercises | `muscle_groups`, `exercises` |
| Workouts | `workouts`, `workout_exercises` |
| Progress | `progress` |
| Nutrition | `meals` |
| Premium | `subscriptions`, `payments`, `payment_history` |

### Database principles

- Backend зберігає лише hash пароля, якщо використовується локальний FitTrack JWT login flow.
- Stripe card data не зберігається.
- Payment records зберігають тільки status, amount, provider id та audit history.
- Exercise media зберігається як URL, самі файли можуть бути в object storage.
- Видалення користувача каскадно видаляє персональні дані через `ON DELETE CASCADE`.

## 9. External Services

| Service | Використання |
| --- | --- |
| Firebase Authentication | Email/password, Google Sign-In, password reset, password change |
| Firebase Admin SDK | Backend verification of Firebase ID Tokens |
| Stripe Test API | Premium checkout, payment intent/session, webhook |
| Media/Object Storage | Фото або GIF вправ |
| Device Biometrics | Face ID / Touch ID локально на пристрої |

External services викликаються з Business Logic Layer або Client Layer залежно від сценарію:

- Flutter напряму працює з Firebase Auth SDK.
- FastAPI перевіряє Firebase ID token через Firebase Admin SDK.
- FastAPI створює Stripe checkout sessions та обробляє webhooks.
- Flutter виконує локальну біометрію без передачі біометричних даних на backend.

## 10. C4 Model Level 1 - System Context

```mermaid
C4Context
    title FitTrack - C4 Level 1 System Context

    Person(user, "User", "Тренується, веде прогрес, харчування та Premium")
    Person(trainer, "Trainer", "Створює програми тренувань і переглядає клієнтів")
    Person(admin, "Admin", "Керує користувачами, вправами та платежами")

    System(fittrack, "FitTrack", "Мобільний застосунок для персональних тренувань")

    System_Ext(firebase, "Firebase Authentication", "Email/password, Google Sign-In, password reset/change")
    System_Ext(stripe, "Stripe Test API", "Тестові Premium платежі")
    System_Ext(storage, "Media/Object Storage", "Фото та GIF вправ")

    Rel(user, fittrack, "Користується мобільним застосунком")
    Rel(trainer, fittrack, "Працює з програмами та клієнтами")
    Rel(admin, fittrack, "Адмініструє систему")
    Rel(fittrack, firebase, "Автентифікація та перевірка ID token")
    Rel(fittrack, stripe, "Створення checkout session і webhook обробка")
    Rel(fittrack, storage, "Завантаження медіа вправ")
```

## 11. C4 Model Level 2 - Container Diagram

```mermaid
C4Container
    title FitTrack - C4 Level 2 Container Diagram

    Person(user, "User", "Mobile app user")
    Person(trainer, "Trainer", "Coach role")
    Person(admin, "Admin", "Administrator role")

    System_Boundary(fittrack, "FitTrack") {
        Container(mobile, "Flutter Mobile App", "Flutter, Riverpod, Dio", "Android/iOS client")
        Container(gateway, "API Gateway", "Nginx/Cloud Load Balancer", "HTTPS termination, routing, health checks")
        Container(api, "FastAPI Backend", "Python FastAPI, SQLAlchemy", "REST API, business logic, RBAC, integrations")
        ContainerDb(db, "PostgreSQL Database", "PostgreSQL", "Users, profiles, exercises, workouts, progress, nutrition, payments")
    }

    System_Ext(firebase, "Firebase Authentication", "Authentication provider")
    System_Ext(stripe, "Stripe Test API", "Payment provider test mode")
    System_Ext(storage, "Media/Object Storage", "Exercise media")

    Rel(user, mobile, "Uses")
    Rel(trainer, mobile, "Uses")
    Rel(admin, mobile, "Uses")
    Rel(mobile, gateway, "HTTPS REST + Bearer token", "JSON")
    Rel(gateway, api, "Proxies requests", "HTTP")
    Rel(api, db, "Reads/writes", "SQLAlchemy / psycopg")
    Rel(mobile, firebase, "Signs in", "Firebase SDK")
    Rel(api, firebase, "Verifies ID token", "Firebase Admin SDK")
    Rel(api, stripe, "Creates checkout, receives webhook", "Stripe API")
    Rel(mobile, storage, "Loads exercise media", "HTTPS")
```

## 12. Component Diagram

```mermaid
flowchart TB
    subgraph Client["Client Layer - Flutter App"]
        Screens["Presentation Screens"]
        Providers["Riverpod Providers"]
        UseCases["Domain Use Cases"]
        ClientRepos["Client Repositories"]
        DioClient["Dio ApiClient"]
        SecureStorage["Secure Storage"]
        FirebaseSdk["Firebase Auth SDK"]
        Biometrics["Local Auth"]
    end

    subgraph Gateway["API Gateway"]
        TLS["TLS Termination"]
        Routing["Reverse Proxy Routing"]
        GatewayLogs["Access Logs"]
    end

    subgraph Backend["FastAPI Backend"]
        Routers["API Routers"]
        Schemas["Pydantic Schemas"]
        AuthDeps["Auth Dependencies"]
        RateLimit["Rate Limiting"]
        AuthService["AuthSecurityService"]
        RBACService["RBACService"]
        WorkoutService["WorkoutService"]
        ProgressService["ProgressService"]
        NutritionService["NutritionService"]
        PaymentService["PaymentService"]
        Repositories["Repositories"]
        DBSession["SQLAlchemy Session"]
    end

    subgraph DB["Database Layer"]
        Users["users / profiles"]
        Roles["roles / permissions"]
        Training["exercises / workouts / progress"]
        Meals["meals"]
        Payments["subscriptions / payments / payment_history"]
    end

    Firebase["Firebase Authentication"]
    Stripe["Stripe Test API"]
    Media["Media/Object Storage"]

    Screens --> Providers
    Providers --> UseCases
    UseCases --> ClientRepos
    ClientRepos --> DioClient
    ClientRepos --> FirebaseSdk
    Screens --> Biometrics
    DioClient --> SecureStorage
    DioClient --> TLS
    TLS --> Routing
    Routing --> GatewayLogs
    Routing --> Routers

    Routers --> Schemas
    Routers --> AuthDeps
    Routers --> RateLimit
    Routers --> AuthService
    Routers --> RBACService
    Routers --> WorkoutService
    Routers --> ProgressService
    Routers --> NutritionService
    Routers --> PaymentService

    AuthDeps --> AuthService
    AuthService --> Firebase
    PaymentService --> Stripe
    WorkoutService --> Repositories
    ProgressService --> Repositories
    NutritionService --> Repositories
    PaymentService --> Repositories
    RBACService --> Repositories
    Repositories --> DBSession
    DBSession --> Users
    DBSession --> Roles
    DBSession --> Training
    DBSession --> Meals
    DBSession --> Payments
    Screens --> Media
```

## 13. Deployment Diagram

```mermaid
flowchart TB
    subgraph Device["User Device"]
        FlutterApp["Flutter App\nAndroid / iOS"]
        Keychain["Secure Storage\nKeychain / Android Keystore"]
        LocalBio["Face ID / Touch ID"]
    end

    subgraph Internet["Public Network"]
        HTTPS["HTTPS"]
    end

    subgraph Cloud["Cloud Server / Cloud VM"]
        ReverseProxy["API Gateway / Reverse Proxy\nNginx, Traefik or Cloud LB"]
        subgraph DockerHost["Docker Host"]
            ApiContainer["FastAPI Backend Container\nUvicorn + Alembic startup"]
            PostgresContainer["PostgreSQL Container\nPersistent volume"]
        end
    end

    subgraph External["External Services"]
        Firebase["Firebase Authentication"]
        Stripe["Stripe Test API"]
        Storage["Media/Object Storage"]
    end

    subgraph DevOps["CI/CD"]
        GitHub["GitHub Repository"]
        Actions["GitHub Actions"]
        GHCR["GitHub Container Registry"]
    end

    FlutterApp --> Keychain
    FlutterApp --> LocalBio
    FlutterApp --> HTTPS
    HTTPS --> ReverseProxy
    ReverseProxy --> ApiContainer
    ApiContainer --> PostgresContainer
    FlutterApp --> Firebase
    ApiContainer --> Firebase
    ApiContainer --> Stripe
    FlutterApp --> Storage

    GitHub --> Actions
    Actions --> GHCR
    GHCR --> ApiContainer
```

## 14. End-to-end interaction

```mermaid
sequenceDiagram
    participant M as Mobile App
    participant G as API Gateway
    participant A as FastAPI Backend
    participant B as Business Logic
    participant R as Data Access
    participant DB as PostgreSQL
    participant F as Firebase Auth
    participant S as Stripe Test API

    M->>F: Sign in with email/password or Google
    F-->>M: Firebase ID token
    M->>G: HTTPS request with Bearer token
    G->>A: Proxy REST request
    A->>B: Validate DTO and call use case
    B->>F: Verify Firebase ID token when needed
    B->>R: Load/update domain data
    R->>DB: SQL query/transaction
    DB-->>R: Rows/result
    R-->>B: Domain data
    opt Premium checkout
        B->>S: Create Stripe test checkout session
        S-->>B: Checkout URL/session id
        B->>DB: Save payment status and audit history
    end
    B-->>A: Response model
    A-->>G: JSON response
    G-->>M: JSON response
```

## 15. Security boundaries

| Boundary | Захист |
| --- | --- |
| Mobile device | Secure Storage, Face ID / Touch ID, no raw card storage |
| Mobile -> API Gateway | HTTPS, Bearer token, request validation |
| API Gateway -> Backend | Internal network, trusted proxy headers |
| API Layer | CORS, TrustedHost, rate limiting, security headers |
| Business Logic | RBAC, permission checks, payment mode validation |
| Data Access | SQLAlchemy parameterized queries, transaction control |
| Database | FK constraints, indexes, cascade rules, no card data |
| External Services | Firebase token verification, Stripe webhook signature |

## 16. Основні архітектурні рішення

| Рішення | Обґрунтування |
| --- | --- |
| Flutter для Android/iOS | Один codebase для двох платформ |
| FastAPI backend | Швидка розробка REST API, OpenAPI docs, Pydantic validation |
| PostgreSQL | Реляційна модель добре підходить для users, workouts, payments, RBAC |
| Firebase Auth | Надійна автентифікація, Google Sign-In, password reset/change |
| JWT + refresh tokens | Контроль backend session layer і mobile API access |
| Stripe test mode | Демонстрація Premium без реальних банківських карт |
| Modular monolith | Простий деплой для курсового, але зрозумілі межі модулів |
| Alembic migrations | Контроль версій структури PostgreSQL |
| Docker + GitHub Actions | Повторюваний build/deploy процес |

## 17. Масштабування

Поточна архітектура достатня для курсового проєкту і demo deployment. Для production growth можна додати:

- Redis для distributed rate limiting та caching.
- Managed PostgreSQL замість PostgreSQL container.
- Object storage CDN для exercise media.
- Background worker для email, analytics, exports.
- Observability: metrics, structured logs, tracing.
- Separate admin web panel, якщо адміністративна частина стане великою.
