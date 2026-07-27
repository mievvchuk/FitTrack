# FitTrack - патерни проєктування

## 1. Мета

Цей документ описує використання патернів проєктування у FitTrack. Патерни допомагають зробити код більш зрозумілим, тестованим і розширюваним.

Мінімальний набір патернів:

1. Repository Pattern.
2. Factory Pattern.
3. Singleton.
4. Strategy Pattern.
5. Observer Pattern.

Повні приклади коду:

- [Dart design patterns example](code_examples/design_patterns_dart_example.dart)
- [Python design patterns example](code_examples/design_patterns_python_example.py)

## 2. Repository Pattern

### Де використовується

У FitTrack Repository Pattern використовується для доступу до даних:

- Flutter: `AuthRepository`, майбутні `ExerciseRepository`, `WorkoutRepository`, `PaymentRepository`.
- Backend: repository layer між services і SQLAlchemy models.
- Тести: production repository можна замінити fake/in-memory repository.

Приклад із поточного Flutter-коду:

```text
mobile/lib/features/auth/domain/repositories/auth_repository.dart
```

### Чому вибраний

Repository Pattern відокремлює бізнес-логіку від конкретного джерела даних. UI або service не повинні знати, звідки прийшли дані: з REST API, Firebase, SQLite cache або mock-об'єкта у тестах.

Переваги:

- легше тестувати use cases;
- можна замінити backend/Firebase/mock без зміни UI;
- data access має єдиний контракт;
- код стає ближчим до Clean Architecture.

### Код прикладу Dart

```dart
abstract interface class ExerciseRepository {
  Future<List<Exercise>> findAll({String? muscleGroup});
  Future<Exercise?> findById(String id);
  Future<Exercise> save(Exercise exercise);
  Future<void> deleteById(String id);
}

class InMemoryExerciseRepository implements ExerciseRepository {
  final Map<String, Exercise> _storage = {};

  @override
  Future<List<Exercise>> findAll({String? muscleGroup}) async {
    final exercises = _storage.values.toList();
    if (muscleGroup == null) {
      return exercises;
    }
    return exercises
        .where((exercise) => exercise.muscleGroup == muscleGroup)
        .toList();
  }

  @override
  Future<Exercise?> findById(String id) async => _storage[id];

  @override
  Future<Exercise> save(Exercise exercise) async {
    _storage[exercise.id] = exercise;
    return exercise;
  }

  @override
  Future<void> deleteById(String id) async {
    _storage.remove(id);
  }
}
```

### Код прикладу Python

```python
class ExerciseRepository(ABC):
    @abstractmethod
    def find_all(self, muscle_group: str | None = None) -> list[Exercise]:
        raise NotImplementedError

    @abstractmethod
    def find_by_id(self, exercise_id: str) -> Exercise | None:
        raise NotImplementedError

    @abstractmethod
    def save(self, exercise: Exercise) -> Exercise:
        raise NotImplementedError


class InMemoryExerciseRepository(ExerciseRepository):
    def __init__(self) -> None:
        self._storage: dict[str, Exercise] = {}

    def find_all(self, muscle_group: str | None = None) -> list[Exercise]:
        exercises = list(self._storage.values())
        if muscle_group is None:
            return exercises
        return [item for item in exercises if item.muscle_group == muscle_group]

    def save(self, exercise: Exercise) -> Exercise:
        self._storage[exercise.id] = exercise
        return exercise
```

## 3. Factory Pattern

### Де використовується

Factory Pattern використовується там, де потрібно створити правильний об'єкт за типом або конфігурацією:

- створення notification channel: push, email;
- створення payment strategy: free plan, Stripe test Premium;
- створення user role object для demo OOP examples;
- створення API clients для різних середовищ.

### Чому вибраний

Factory Pattern прибирає `if/else` створення об'єктів із бізнес-коду. Наприклад, `PaymentProcessor` не повинен знати, який клас створити для Premium. Це робить код відкритим для розширення: можна додати Apple Pay test або Google Pay test без переписування основного flow.

### Код прикладу Dart

```dart
class PaymentStrategyFactory {
  static PaymentStrategy create(String plan) {
    return switch (plan) {
      'free' => FreePlanPaymentStrategy(),
      'premium' => StripeTestPaymentStrategy(),
      _ => throw ArgumentError('Unsupported plan: $plan'),
    };
  }
}

class NotificationChannelFactory {
  static NotificationChannel create(NotificationType type) {
    return switch (type) {
      NotificationType.push => PushNotificationChannel(),
      NotificationType.email => EmailNotificationChannel(),
    };
  }
}
```

### Код прикладу Python

```python
class PaymentStrategyFactory:
    @staticmethod
    def create(plan: str) -> PaymentStrategy:
        if plan == "free":
            return FreePlanPaymentStrategy()
        if plan == "premium":
            return StripeTestPaymentStrategy()
        raise ValueError(f"Unsupported plan: {plan}")


class NotificationChannelFactory:
    @staticmethod
    def create(channel_type: str) -> NotificationChannel:
        if channel_type == "push":
            return PushNotificationChannel()
        if channel_type == "email":
            return EmailNotificationChannel()
        raise ValueError(f"Unsupported notification channel: {channel_type}")
```

## 4. Singleton

### Де використовується

Singleton використовується для об'єктів, які мають бути єдиними в межах runtime:

- backend settings: `backend/app/core/config.py` використовує `@lru_cache` для `get_settings()`;
- Flutter API config;
- shared API client configuration;
- Firebase initialization guard.

### Чому вибраний

Конфігурацію не треба створювати повторно для кожного request або widget. Singleton гарантує єдине джерело налаштувань: `DATABASE_URL`, `API_BASE_URL`, Stripe mode, security flags.

Важливо: для тестованості краще не зловживати global singleton. У FitTrack production-коді бажано поєднувати Singleton для immutable settings з dependency injection через Riverpod/FastAPI dependencies.

### Код прикладу Dart

```dart
class ApiConfig {
  static final ApiConfig instance = ApiConfig._internal();

  final String baseUrl;
  final bool requireHttps;

  ApiConfig._internal()
      : baseUrl = const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://127.0.0.1:8000/api/v1',
        ),
        requireHttps = const bool.fromEnvironment(
          'REQUIRE_HTTPS',
          defaultValue: false,
        );

  factory ApiConfig() => instance;
}
```

### Код прикладу Python

```python
@dataclass(frozen=True)
class Settings:
    app_name: str = "FitTrack API"
    api_prefix: str = "/api/v1"
    stripe_mode: str = "test"


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

## 5. Strategy Pattern

### Де використовується

Strategy Pattern використовується для алгоритмів, які мають спільний інтерфейс, але різну реалізацію:

- payment methods: Free plan, Stripe test Premium;
- nutrition calculations: weight loss, muscle gain, maintenance;
- progress statistics: weekly, monthly, yearly aggregation;
- notification delivery: push, email, future SMS.

### Чому вибраний

Payment flow не має залежати від конкретного провайдера. `PaymentProcessor` викликає `pay()`, а конкретна strategy вирішує, що робити: активувати Free plan або створити Stripe Checkout Session.

Це спрощує тестування платежів: у тестах можна підставити fake strategy.

### Код прикладу Dart

```dart
abstract interface class PaymentStrategy {
  Future<PaymentResult> pay(PaymentRequest request);
}

class FreePlanPaymentStrategy implements PaymentStrategy {
  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    return const PaymentResult(
      paymentId: 'free-plan',
      status: 'succeeded',
      provider: 'internal',
    );
  }
}

class StripeTestPaymentStrategy implements PaymentStrategy {
  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    return const PaymentResult(
      paymentId: 'stripe-test-payment',
      status: 'pending',
      provider: 'stripe_test',
    );
  }
}
```

### Код прикладу Python

```python
class PaymentStrategy(ABC):
    @abstractmethod
    def pay(self, request: PaymentRequest) -> PaymentResult:
        raise NotImplementedError


class FreePlanPaymentStrategy(PaymentStrategy):
    def pay(self, request: PaymentRequest) -> PaymentResult:
        return PaymentResult("free-plan", "succeeded", "internal")


class StripeTestPaymentStrategy(PaymentStrategy):
    def pay(self, request: PaymentRequest) -> PaymentResult:
        return PaymentResult("stripe-test-payment", "pending", "stripe_test")
```

## 6. Observer Pattern

### Де використовується

Observer Pattern використовується там, де зміна одного об'єкта має оновити кілька залежних частин системи:

- після завершення тренування оновлюється dashboard;
- progress chart отримує нову точку;
- notification system може показати повідомлення;
- payment status screen реагує на зміну payment status.

У Flutter цей патерн природно проявляється через streams, `ChangeNotifier`, Riverpod providers і state subscriptions.

### Чому вибраний

Training process впливає на кілька екранів: Home Dashboard, Progress, Workout History. Observer Pattern дозволяє не зв'язувати ці екрани напряму з workout service. Subject повідомляє observers про подію, а кожен observer реагує по-своєму.

### Код прикладу Dart

```dart
abstract interface class WorkoutObserver {
  void onWorkoutCompleted(WorkoutCompletedEvent event);
}

class WorkoutProgressSubject {
  final List<WorkoutObserver> _observers = [];

  void attach(WorkoutObserver observer) {
    if (!_observers.contains(observer)) {
      _observers.add(observer);
    }
  }

  void completeWorkout(WorkoutCompletedEvent event) {
    for (final observer in List<WorkoutObserver>.from(_observers)) {
      observer.onWorkoutCompleted(event);
    }
  }
}
```

### Код прикладу Python

```python
class WorkoutObserver(ABC):
    @abstractmethod
    def on_workout_completed(self, event: WorkoutCompletedEvent) -> None:
        raise NotImplementedError


class WorkoutProgressSubject:
    def __init__(self) -> None:
        self._observers: list[WorkoutObserver] = []

    def attach(self, observer: WorkoutObserver) -> None:
        if observer not in self._observers:
            self._observers.append(observer)

    def complete_workout(self, event: WorkoutCompletedEvent) -> None:
        for observer in list(self._observers):
            observer.on_workout_completed(event)
```

## 7. Підсумкова таблиця

| Pattern | Де у FitTrack | Навіщо |
| --- | --- | --- |
| Repository | Auth, exercises, workouts, payments data access | Відокремити domain/API/UI від джерела даних |
| Factory | Payment strategy, notification channel, API clients | Централізувати створення об'єктів |
| Singleton | Settings, API config, Firebase init guard | Єдине джерело конфігурації |
| Strategy | Payment methods, nutrition/progress calculations | Замінювати алгоритми без зміни caller code |
| Observer | Workout progress, dashboard updates, payment status | Реакція багатьох компонентів на одну подію |

## 8. Висновок

Патерни проєктування у FitTrack допомагають показати зрілу архітектуру курсового проєкту:

- Repository підтримує Clean Architecture.
- Factory зменшує залежність бізнес-коду від конкретних класів.
- Singleton централізує конфігурацію.
- Strategy робить платежі та розрахунки розширюваними.
- Observer дозволяє UI та сервісам реагувати на події без жорстких залежностей.
