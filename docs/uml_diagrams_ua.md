# FitTrack - UML документація

## 1. Призначення UML документації

Цей документ описує ключові UML-діаграми для курсового проєкту FitTrack. Діаграми показують функціональні можливості системи, основні класи предметної області, взаємодію мобільного застосунку з backend, процес тренування, життєвий цикл Premium-підписки, компоненти системи та deployment-структуру.

Технологічний стек:

- Flutter mobile app для Android та iOS.
- Python FastAPI backend.
- PostgreSQL database.
- Firebase Authentication.
- Stripe Test API.

## 2. Use Case Diagram

### Пояснення

Use Case Diagram показує, які ролі взаємодіють із системою FitTrack та які функції вони можуть виконувати. У системі є три основні актори: User, Trainer та Admin.

### Діаграма

```mermaid
flowchart LR
    User["User"]
    Trainer["Trainer"]
    Admin["Admin"]

    UCAuth(("Register / Login"))
    UCPassword(("Reset / Change Password"))
    UCBio(("Face ID / Touch ID"))
    UCProfile(("Manage Profile"))
    UCExercises(("View Exercise Library"))
    UCWorkoutCreate(("Create Workout"))
    UCWorkoutRun(("Complete Workout"))
    UCProgress(("Track Progress"))
    UCNutrition(("Track Nutrition"))
    UCPremium(("Buy Premium"))
    UCPayHistory(("View Payment History"))
    UCPrograms(("Create Training Programs"))
    UCClients(("View Clients"))
    UCManageExercises(("Manage Exercises"))
    UCManageUsers(("Manage Users"))
    UCManagePayments(("View Payments"))

    User --> UCAuth
    User --> UCPassword
    User --> UCBio
    User --> UCProfile
    User --> UCExercises
    User --> UCWorkoutCreate
    User --> UCWorkoutRun
    User --> UCProgress
    User --> UCNutrition
    User --> UCPremium
    User --> UCPayHistory

    Trainer --> UCAuth
    Trainer --> UCExercises
    Trainer --> UCPrograms
    Trainer --> UCClients
    Trainer --> UCManageExercises

    Admin --> UCAuth
    Admin --> UCManageUsers
    Admin --> UCManageExercises
    Admin --> UCManagePayments
```

### Основні сутності

| Сутність | Опис |
| --- | --- |
| `User` | Звичайний користувач, який тренується, веде прогрес, харчування та купує Premium |
| `Trainer` | Тренер, який створює програми тренувань і працює з клієнтами |
| `Admin` | Адміністратор, який керує користувачами, вправами та платежами |
| `FitTrack System` | Мобільний застосунок і backend API |

### Зв'язки

- `User` має доступ до персональних сценаріїв: профіль, вправи, тренування, прогрес, харчування, Premium.
- `Trainer` має доступ до тренерських сценаріїв: програми, клієнти, додавання вправ.
- `Admin` має доступ до адміністративних сценаріїв: користувачі, вправи, платежі.
- Усі ролі проходять автентифікацію перед використанням захищених функцій.

## 3. Class Diagram

### Пояснення

Class Diagram показує основні сутності предметної області FitTrack та зв'язки між ними. Діаграма відповідає структурі PostgreSQL бази даних і backend ORM-моделей.

### Діаграма

```mermaid
classDiagram
    class User {
      UUID id
      string firebaseUid
      string email
      string authProvider
      string passwordHash
      bool isActive
      datetime emailVerifiedAt
      datetime createdAt
    }

    class Profile {
      UUID id
      UUID userId
      string fullName
      int age
      string gender
      decimal heightCm
      decimal weightKg
      string trainingGoal
    }

    class Role {
      UUID id
      string code
      string name
      bool isSystem
    }

    class Permission {
      UUID id
      string code
      string resource
      string action
    }

    class MuscleGroup {
      UUID id
      string code
      string name
      string description
    }

    class Exercise {
      UUID id
      UUID muscleGroupId
      UUID createdByUserId
      string name
      string mediaUrl
      string mediaType
      string description
      string technique
      string commonMistakes
      string equipment
      string difficulty
    }

    class Workout {
      UUID id
      UUID userId
      string title
      string description
      date scheduledFor
      bool isCompleted
      datetime completedAt
    }

    class WorkoutExercise {
      UUID id
      UUID workoutId
      UUID exerciseId
      int orderIndex
      int setsCount
      int repsCount
      decimal weightKg
      int restSeconds
    }

    class Progress {
      UUID id
      UUID userId
      UUID workoutId
      date progressDate
      decimal weightKg
      decimal bodyFatPercent
      decimal totalVolumeKg
      int caloriesBurned
    }

    class Meal {
      UUID id
      UUID userId
      date mealDate
      string mealType
      string name
      int calories
      decimal proteinG
      decimal fatG
      decimal carbsG
    }

    class Subscription {
      UUID id
      UUID userId
      string plan
      string status
      int priceCents
      string currency
      datetime startedAt
      datetime expiresAt
    }

    class Payment {
      UUID id
      UUID userId
      UUID subscriptionId
      string plan
      int amountCents
      string currency
      string status
      string provider
      string mode
      string stripeCheckoutSessionId
      datetime paidAt
    }

    class PaymentHistory {
      UUID id
      UUID paymentId
      UUID userId
      string oldStatus
      string newStatus
      string eventType
      datetime createdAt
    }

    class RefreshToken {
      UUID id
      UUID userId
      string tokenHash
      datetime expiresAt
      datetime revokedAt
    }

    User "1" --> "1" Profile : has
    User "1" --> "*" RefreshToken : owns
    User "*" --> "*" Role : assigned
    Role "*" --> "*" Permission : grants
    User "1" --> "*" Exercise : creates
    MuscleGroup "1" --> "*" Exercise : categorizes
    User "1" --> "*" Workout : owns
    Workout "1" --> "*" WorkoutExercise : contains
    Exercise "1" --> "*" WorkoutExercise : usedIn
    User "1" --> "*" Progress : tracks
    Workout "0..1" --> "*" Progress : produces
    User "1" --> "*" Meal : logs
    User "1" --> "*" Subscription : has
    Subscription "0..1" --> "*" Payment : paidBy
    User "1" --> "*" Payment : makes
    Payment "1" --> "*" PaymentHistory : auditedBy
```

### Основні сутності

| Сутність | Опис |
| --- | --- |
| `User` | Обліковий запис користувача |
| `Profile` | Анкетні та фізичні параметри користувача |
| `Role`, `Permission` | RBAC-модель доступу |
| `Exercise`, `MuscleGroup` | Бібліотека вправ і категорії м'язів |
| `Workout`, `WorkoutExercise` | Тренування та вправи всередині тренування |
| `Progress` | Дані прогресу користувача |
| `Meal` | Харчування та макронутрієнти |
| `Subscription`, `Payment`, `PaymentHistory` | Premium-підписка, платежі та аудит |
| `RefreshToken` | Backend refresh token у hashed form |

### Зв'язки

- `User` має один `Profile`.
- `User` може мати багато `Workout`, `Progress`, `Meal`, `Payment`.
- `Workout` складається з багатьох `WorkoutExercise`.
- `Exercise` належить до одного `MuscleGroup`.
- `User` має багато ролей, а `Role` має багато permissions.
- `Subscription` пов'язана з платежами, а кожен `Payment` має audit records у `PaymentHistory`.

## 4. Sequence Diagram - Login

### Пояснення

Sequence Diagram Login показує процес входу користувача через backend JWT flow. Користувач вводить email/password у Flutter, backend перевіряє пароль, створює access token і refresh token, після чого Flutter зберігає токени у secure storage.

### Діаграма

```mermaid
sequenceDiagram
    actor U as User
    participant M as Flutter App
    participant A as Auth API
    participant S as AuthSecurityService
    participant DB as PostgreSQL
    participant SS as Secure Storage

    U->>M: Enter email and password
    M->>A: POST /api/v1/auth/login
    A->>S: authenticatePasswordUser(email, password)
    S->>DB: SELECT user by email
    DB-->>S: User + passwordHash + roles
    S->>S: Verify Argon2id password hash
    S->>S: Check email verification and lockout
    S->>S: Create JWT access token
    S->>DB: INSERT refresh token hash
    S-->>A: Token pair + user permissions
    A-->>M: accessToken, refreshToken, user
    M->>SS: Save tokens securely
    M-->>U: Open Home Dashboard
```

### Основні сутності

| Сутність | Опис |
| --- | --- |
| `Flutter App` | UI та client-side auth flow |
| `Auth API` | FastAPI endpoint для входу |
| `AuthSecurityService` | Перевірка пароля, JWT, refresh token |
| `PostgreSQL` | Збереження users і refresh_tokens |
| `Secure Storage` | Безпечне збереження токенів на пристрої |

### Зв'язки

- Flutter надсилає credentials до Auth API.
- Auth API делегує перевірку сервісу безпеки.
- Service читає користувача з PostgreSQL.
- Refresh token зберігається у БД тільки як hash.
- Access/refresh tokens зберігаються у Flutter Secure Storage.

## 5. Sequence Diagram - Creating Workout

### Пояснення

Ця діаграма показує створення власного тренування користувачем. Користувач обирає вправи з бібліотеки, вказує кількість підходів, повторень, вагу та час відпочинку. Backend перевіряє авторизацію, валідує дані та зберігає тренування у PostgreSQL.

### Діаграма

```mermaid
sequenceDiagram
    actor U as User
    participant M as Flutter App
    participant G as API Gateway
    participant A as Workout API
    participant Auth as Auth Dependency
    participant W as WorkoutService
    participant R as WorkoutRepository
    participant DB as PostgreSQL

    U->>M: Tap Create Workout
    M->>A: GET /api/v1/exercises
    A-->>M: Exercise library
    U->>M: Select exercises and set params
    M->>G: POST /api/v1/workouts with Bearer token
    G->>A: Proxy request
    A->>Auth: Verify JWT and permission
    Auth-->>A: Current user
    A->>W: createWorkout(userId, workoutDto)
    W->>W: Validate exercises, sets, reps, rest time
    W->>R: Save workout aggregate
    R->>DB: INSERT workouts
    R->>DB: INSERT workout_exercises
    DB-->>R: Created rows
    R-->>W: Workout entity
    W-->>A: Workout response
    A-->>G: 201 Created
    G-->>M: Created workout
    M-->>U: Show workout detail
```

### Основні сутності

| Сутність | Опис |
| --- | --- |
| `Workout API` | Endpoint створення тренування |
| `Auth Dependency` | Перевірка JWT та permissions |
| `WorkoutService` | Бізнес-логіка тренування |
| `WorkoutRepository` | Запис у таблиці `workouts` та `workout_exercises` |
| `Exercise Library` | Джерело вправ для workout builder |

### Зв'язки

- Flutter отримує вправи з API.
- Користувач формує workout payload.
- API Gateway передає запит у FastAPI.
- Backend перевіряє користувача та права.
- `WorkoutService` гарантує коректність параметрів.
- `WorkoutRepository` зберігає workout aggregate у транзакції.

## 6. Sequence Diagram - Payment

### Пояснення

Payment sequence показує тестову оплату Premium через Stripe. FitTrack не зберігає реальні банківські картки. Backend створює Stripe Checkout Session у test mode, зберігає локальний запис платежу, а успішний статус підтверджується webhook або test-confirm endpoint.

### Діаграма

```mermaid
sequenceDiagram
    actor U as User
    participant M as Flutter App
    participant A as Subscription API
    participant Auth as Auth Dependency
    participant P as PaymentService
    participant DB as PostgreSQL
    participant ST as Stripe Test API

    U->>M: Tap Buy Premium
    M->>A: GET /api/v1/subscription/plans
    A-->>M: Free and Premium plans
    U->>M: Select Premium
    M->>A: POST /api/v1/subscription/checkout-session
    A->>Auth: Verify user and premium:pay permission
    Auth-->>A: Current user
    A->>P: createCheckoutSession(user)
    P->>P: Validate Stripe test key
    P->>DB: INSERT payment status=pending
    P->>ST: Create Checkout Session
    ST-->>P: sessionId + checkoutUrl
    P->>DB: UPDATE payment with sessionId and URL
    P-->>A: checkoutUrl + paymentId
    A-->>M: Checkout session response
    M->>ST: Open hosted Stripe Checkout
    ST-->>A: POST /webhook/stripe payment succeeded
    A->>P: verifyWebhookAndApplyEvent()
    P->>DB: UPDATE payment status=succeeded
    P->>DB: INSERT payment_history
    P->>DB: UPSERT subscription plan=premium
    M->>A: GET /api/v1/subscription/me
    A-->>M: Premium active
    M-->>U: Show Payment Success
```

### Основні сутності

| Сутність | Опис |
| --- | --- |
| `Subscription API` | Endpoints Premium, Checkout, Payment History |
| `PaymentService` | Створення checkout, webhook, статус платежу |
| `Stripe Test API` | Тестовий платіжний провайдер |
| `payments` | Локальний запис платежу |
| `payment_history` | Аудит зміни статусів |
| `subscriptions` | Поточний Premium-статус користувача |

### Зв'язки

- Flutter ініціює Premium purchase.
- Backend створює локальний `pending` payment.
- Stripe повертає hosted checkout URL.
- Після успішної оплати Stripe надсилає webhook.
- Backend оновлює payment, payment history і subscription.
- Дані банківської картки не проходять через FitTrack backend.

## 7. Activity Diagram - Training Process

### Пояснення

Activity Diagram описує процес проходження тренування: користувач відкриває тренування, виконує вправи, фіксує підходи, після завершення система зберігає історію та оновлює прогрес.

### Діаграма

```mermaid
flowchart TD
    Start([Start])
    Auth{User authenticated?}
    Login["Login or biometric unlock"]
    OpenWorkout["Open today's workout"]
    HasWorkout{Workout exists?}
    CreateWorkout["Create workout"]
    SelectExercise["Select exercise"]
    SetParams["Set sets, reps, weight, rest"]
    StartSession["Start workout session"]
    DoSet["Perform set"]
    RecordSet["Record actual reps and weight"]
    Rest["Rest timer"]
    MoreSets{More sets?}
    MoreExercises{More exercises?}
    CompleteWorkout["Complete workout"]
    SaveProgress["Save history and progress"]
    UpdateStats["Update statistics"]
    Finish([Finish])

    Start --> Auth
    Auth -- No --> Login
    Login --> OpenWorkout
    Auth -- Yes --> OpenWorkout
    OpenWorkout --> HasWorkout
    HasWorkout -- No --> CreateWorkout
    CreateWorkout --> SelectExercise
    SelectExercise --> SetParams
    SetParams --> StartSession
    HasWorkout -- Yes --> StartSession
    StartSession --> DoSet
    DoSet --> RecordSet
    RecordSet --> MoreSets
    MoreSets -- Yes --> Rest
    Rest --> DoSet
    MoreSets -- No --> MoreExercises
    MoreExercises -- Yes --> SelectExercise
    MoreExercises -- No --> CompleteWorkout
    CompleteWorkout --> SaveProgress
    SaveProgress --> UpdateStats
    UpdateStats --> Finish
```

### Основні сутності

| Сутність | Опис |
| --- | --- |
| `Workout` | План тренування |
| `WorkoutExercise` | Вправа з параметрами виконання |
| `Training Session` | Фактичне проходження тренування |
| `Progress` | Результат тренування та статистика |
| `Rest Timer` | Час відпочинку між підходами |

### Зв'язки

- Якщо тренування не існує, користувач створює його.
- Під час тренування користувач проходить вправи й підходи.
- Після кожного підходу система може запускати таймер відпочинку.
- Після завершення тренування зберігається історія та оновлюється прогрес.

## 8. State Diagram - Subscription Status

### Пояснення

State Diagram показує життєвий цикл підписки користувача. Користувач починає з Free plan, може перейти у Premium після успішного тестового платежу, а також може втратити Premium через помилку платежу, завершення строку або скасування.

### Діаграма

```mermaid
stateDiagram-v2
    [*] --> Free

    Free --> CheckoutPending: User selects Premium
    CheckoutPending --> PaymentProcessing: Stripe Checkout opened
    PaymentProcessing --> PremiumActive: Payment succeeded
    PaymentProcessing --> PaymentFailed: Payment failed
    PaymentProcessing --> Cancelled: User cancelled checkout

    PaymentFailed --> Free: Keep free plan
    Cancelled --> Free: Keep free plan

    PremiumActive --> PastDue: Renewal/payment problem
    PremiumActive --> Cancelled: User cancels subscription
    PremiumActive --> Expired: Subscription period ends

    PastDue --> PremiumActive: Payment recovered
    PastDue --> Expired: Grace period ended

    Cancelled --> Free: Access period ended
    Expired --> Free: Downgrade to free

    Free --> [*]: Account deleted
```

### Основні сутності

| Стан | Опис |
| --- | --- |
| `Free` | Безкоштовний тариф |
| `CheckoutPending` | Створено локальний payment і Stripe checkout session |
| `PaymentProcessing` | Користувач проходить Stripe Checkout |
| `PremiumActive` | Premium активний |
| `PaymentFailed` | Платіж неуспішний |
| `PastDue` | Проблема з оплатою або продовженням |
| `Cancelled` | Checkout або підписку скасовано |
| `Expired` | Строк Premium завершився |

### Зв'язки

- `Free` переходить у `CheckoutPending` після вибору Premium.
- `PaymentProcessing` переходить у `PremiumActive` тільки після підтвердження Stripe.
- `PaymentFailed` та `Cancelled` повертають користувача до Free plan.
- `PremiumActive` може стати `PastDue`, `Cancelled` або `Expired`.
- `Expired` завжди повертає користувача до Free plan.

## 9. Component Diagram

### Пояснення

Component Diagram показує внутрішню структуру FitTrack: Flutter client, API Gateway, FastAPI backend, PostgreSQL database та зовнішні сервіси.

### Діаграма

```mermaid
flowchart TB
    subgraph Mobile["Flutter Mobile App"]
        Screens["Presentation Screens"]
        Providers["Riverpod Providers"]
        UseCases["Domain Use Cases"]
        ClientRepos["Client Repositories"]
        ApiClient["Dio ApiClient"]
        SecureStorage["Flutter Secure Storage"]
        FirebaseMobile["Firebase Auth SDK"]
        LocalAuth["Local Auth"]
    end

    subgraph Gateway["API Gateway / Reverse Proxy"]
        TLS["HTTPS / TLS"]
        Proxy["Request Routing"]
        GatewayHealth["Health Checks"]
    end

    subgraph Backend["FastAPI Backend"]
        Routers["API Routers"]
        Schemas["Pydantic Schemas"]
        AuthDeps["Auth Dependencies"]
        RateLimiter["Rate Limiter"]
        AuthService["AuthSecurityService"]
        RBACService["RBACService"]
        WorkoutService["WorkoutService"]
        ProgressService["ProgressService"]
        NutritionService["NutritionService"]
        PaymentService["PaymentService"]
        Repositories["Repositories"]
        DBSession["SQLAlchemy Session"]
    end

    subgraph Database["PostgreSQL"]
        Users["users / profiles"]
        Roles["roles / permissions"]
        Exercises["muscle_groups / exercises"]
        Workouts["workouts / workout_exercises"]
        Progress["progress"]
        Meals["meals"]
        Payments["subscriptions / payments / payment_history"]
    end

    Firebase["Firebase Authentication"]
    Stripe["Stripe Test API"]
    Storage["Media/Object Storage"]

    Screens --> Providers
    Providers --> UseCases
    UseCases --> ClientRepos
    ClientRepos --> ApiClient
    ClientRepos --> FirebaseMobile
    ApiClient --> SecureStorage
    Screens --> LocalAuth

    ApiClient --> TLS
    TLS --> Proxy
    Proxy --> GatewayHealth
    Proxy --> Routers

    Routers --> Schemas
    Routers --> AuthDeps
    Routers --> RateLimiter
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
    DBSession --> Exercises
    DBSession --> Workouts
    DBSession --> Progress
    DBSession --> Meals
    DBSession --> Payments

    Screens --> Storage
```

### Основні сутності

| Компонент | Опис |
| --- | --- |
| `Flutter Mobile App` | Client layer |
| `API Gateway` | HTTPS endpoint, routing, health checks |
| `FastAPI Backend` | API, бізнес-логіка, security, integrations |
| `PostgreSQL` | Основне сховище даних |
| `Firebase Authentication` | Автентифікація |
| `Stripe Test API` | Тестові платежі |
| `Media/Object Storage` | Медіа вправ |

### Зв'язки

- Flutter звертається до API Gateway через HTTPS.
- API Gateway проксуює запити до FastAPI.
- FastAPI викликає services і repositories.
- Repositories працюють із PostgreSQL через SQLAlchemy.
- AuthService інтегрується з Firebase.
- PaymentService інтегрується зі Stripe Test API.
- Flutter завантажує media assets через URL.

## 10. Deployment Diagram

### Пояснення

Deployment Diagram показує фізичне розміщення компонентів системи: мобільний пристрій користувача, cloud server з Docker containers, PostgreSQL volume, зовнішні сервіси та CI/CD pipeline.

### Діаграма

```mermaid
flowchart TB
    subgraph Device["User Device"]
        App["Flutter App\nAndroid / iOS"]
        SecureStore["Secure Storage\nKeychain / Android Keystore"]
        Biometrics["Face ID / Touch ID"]
    end

    subgraph Internet["Internet"]
        HTTPS["HTTPS REST API"]
    end

    subgraph Cloud["Cloud Server"]
        Gateway["API Gateway / Reverse Proxy\nNginx or Traefik"]
        subgraph Docker["Docker Host"]
            BackendContainer["FastAPI Backend Container\nUvicorn + Alembic"]
            PostgresContainer["PostgreSQL Container"]
            Volume["Persistent PostgreSQL Volume"]
        end
    end

    subgraph External["External Services"]
        Firebase["Firebase Authentication"]
        Stripe["Stripe Test API"]
        Storage["Media/Object Storage"]
    end

    subgraph DevOps["DevOps"]
        GitHub["GitHub Repository"]
        Actions["GitHub Actions CI/CD"]
        Registry["GitHub Container Registry"]
    end

    App --> SecureStore
    App --> Biometrics
    App --> HTTPS
    HTTPS --> Gateway
    Gateway --> BackendContainer
    BackendContainer --> PostgresContainer
    PostgresContainer --> Volume

    App --> Firebase
    BackendContainer --> Firebase
    BackendContainer --> Stripe
    App --> Storage

    GitHub --> Actions
    Actions --> Registry
    Registry --> BackendContainer
```

### Основні сутності

| Сутність | Опис |
| --- | --- |
| `User Device` | Смартфон з Android або iOS |
| `Cloud Server` | Сервер, на якому працює backend |
| `Docker Host` | Середовище запуску FastAPI та PostgreSQL containers |
| `PostgreSQL Volume` | Persistent storage для бази даних |
| `GitHub Actions` | CI/CD pipeline |
| `GitHub Container Registry` | Registry для backend Docker image |

### Зв'язки

- Мобільний застосунок взаємодіє з backend тільки через HTTPS.
- API Gateway передає запити до backend container.
- Backend container працює з PostgreSQL container.
- PostgreSQL зберігає дані у persistent volume.
- GitHub Actions збирає Docker image та публікує його в registry.
- Cloud server отримує новий image під час deployment.

## 11. Підсумок

UML-документація FitTrack покриває:

- функціональні можливості системи через Use Case Diagram;
- доменну модель через Class Diagram;
- ключові runtime-сценарії через Sequence Diagrams;
- процес тренування через Activity Diagram;
- життєвий цикл Premium через State Diagram;
- програмну структуру через Component Diagram;
- фізичне розгортання через Deployment Diagram.

Ці діаграми підтверджують, що FitTrack має повноцінну архітектуру мобільного застосунку з backend, базою даних, зовнішніми сервісами, авторизацією, ролями, платежами та CI/CD-ready deployment model.
