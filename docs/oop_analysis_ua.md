# FitTrack - аналіз з точки зору ООП

## 1. Мета

Цей документ показує, як у FitTrack можна застосувати основні принципи об'єктно-орієнтованого програмування:

- інкапсуляція;
- наслідування;
- поліморфізм;
- абстракція.

Приклади створені для двох частин проєкту:

- Flutter/Dart mobile app;
- Python FastAPI backend.

Повні файли з прикладами:

- [Dart OOP example](code_examples/oop_dart_example.dart)
- [Python OOP example](code_examples/oop_python_example.py)

## 2. Архітектурна ремарка

Для демонстрації ООП за вимогою курсової використано ієрархію:

```text
User -> Trainer -> Admin
```

Це добре показує наслідування: `Trainer` розширює можливості `User`, а `Admin` розширює можливості `Trainer`.

У production-архітектурі FitTrack краще використовувати RBAC-композицію:

```text
User has many Roles
Role has many Permissions
```

Саме така модель уже описана у backend/database частині проєкту, бо вона гнучкіша: один користувач може мати кілька ролей без жорсткої класової ієрархії.

## 3. Інкапсуляція

### Ідея

Інкапсуляція означає, що внутрішній стан об'єкта прихований, а доступ до нього відбувається через контрольовані методи, getters/setters або properties.

У FitTrack це важливо для:

- email;
- віку;
- ваги;
- training goal;
- списку клієнтів тренера;
- токенів;
- payment status.

### Dart: private fields і getters/setters

У Dart приватність реалізується через `_` на початку назви поля.

```dart
class User {
  final String id;
  String _email;
  int _age;
  double _weightKg;

  User({
    required this.id,
    required String email,
    required int age,
    required double weightKg,
  })  : _email = '',
        _age = 0,
        _weightKg = 0 {
    this.email = email;
    this.age = age;
    this.weightKg = weightKg;
  }

  String get email => _email;

  set email(String value) {
    final normalized = value.trim().toLowerCase();
    if (!normalized.contains('@')) {
      throw ArgumentError('Email must contain @.');
    }
    _email = normalized;
  }

  int get age => _age;

  set age(int value) {
    if (value < 10 || value > 100) {
      throw ArgumentError('Age must be between 10 and 100.');
    }
    _age = value;
  }

  double get weightKg => _weightKg;

  set weightKg(double value) {
    if (value < 25 || value > 300) {
      throw ArgumentError('Weight must be between 25 and 300 kg.');
    }
    _weightKg = value;
  }
}
```

### Python: protected fields і `@property`

У Python приватність є домовленістю. Поля з `_email` вважаються внутрішніми, а контроль доступу виконується через `@property`.

```python
from decimal import Decimal


class User:
    def __init__(self, email: str, age: int, weight_kg: Decimal) -> None:
        self._email = ""
        self._age = 0
        self._weight_kg = Decimal("0")
        self.email = email
        self.age = age
        self.weight_kg = weight_kg

    @property
    def email(self) -> str:
        return self._email

    @email.setter
    def email(self, value: str) -> None:
        normalized = value.strip().lower()
        if "@" not in normalized:
            raise ValueError("Email must contain @.")
        self._email = normalized

    @property
    def weight_kg(self) -> Decimal:
        return self._weight_kg

    @weight_kg.setter
    def weight_kg(self, value: Decimal) -> None:
        if value < Decimal("25") or value > Decimal("300"):
            raise ValueError("Weight must be between 25 and 300 kg.")
        self._weight_kg = value
```

## 4. Наслідування

### Ідея

Наслідування дозволяє створити базовий клас із загальною поведінкою, а дочірні класи розширюють її.

У FitTrack:

- `User` - базовий користувач;
- `Trainer` - користувач, який може створювати програми та переглядати клієнтів;
- `Admin` - користувач із правами керування системою.

### Dart: `User -> Trainer -> Admin`

```dart
class User {
  final String id;
  final String fullName;

  User({required this.id, required this.fullName});

  List<String> get permissions => const [
        'exercises:read',
        'workouts:complete',
        'progress:manage',
        'premium:pay',
      ];

  String get roleCode => 'user';

  String dashboardTitle() => 'Athlete: $fullName';
}

class Trainer extends User {
  Trainer({required super.id, required super.fullName});

  @override
  List<String> get permissions => [
        ...super.permissions,
        'programs:create',
        'clients:read',
        'exercises:create',
      ];

  @override
  String get roleCode => 'trainer';

  @override
  String dashboardTitle() => 'Trainer: $fullName';
}

class Admin extends Trainer {
  Admin({required super.id, required super.fullName});

  @override
  List<String> get permissions => [
        ...super.permissions,
        'users:manage',
        'exercises:update',
        'payments:read',
      ];

  @override
  String get roleCode => 'admin';

  @override
  String dashboardTitle() => 'Admin: $fullName';
}
```

### Python: `User -> Trainer -> Admin`

```python
class User:
    @property
    def permissions(self) -> set[str]:
        return {"exercises:read", "workouts:complete", "progress:manage", "premium:pay"}

    @property
    def role_code(self) -> str:
        return "user"


class Trainer(User):
    @property
    def permissions(self) -> set[str]:
        return super().permissions | {"programs:create", "clients:read", "exercises:create"}

    @property
    def role_code(self) -> str:
        return "trainer"


class Admin(Trainer):
    @property
    def permissions(self) -> set[str]:
        return super().permissions | {"users:manage", "exercises:update", "payments:read"}

    @property
    def role_code(self) -> str:
        return "admin"
```

## 5. Поліморфізм

### Ідея

Поліморфізм дозволяє працювати з різними об'єктами через спільний інтерфейс. Код не знає конкретний клас, але викликає однаковий метод.

У FitTrack це зручно для:

- notification system;
- payment methods;
- storage providers;
- authentication providers.

## 6. Поліморфізм: Notification system

### Dart

```dart
abstract interface class NotificationChannel {
  Future<void> send(User receiver, NotificationMessage message);
}

class PushNotificationChannel implements NotificationChannel {
  @override
  Future<void> send(User receiver, NotificationMessage message) async {
    print('Push to ${receiver.email}: ${message.title}');
  }
}

class EmailNotificationChannel implements NotificationChannel {
  @override
  Future<void> send(User receiver, NotificationMessage message) async {
    print('Email to ${receiver.email}: ${message.title}');
  }
}

class NotificationService {
  final List<NotificationChannel> _channels;

  NotificationService(this._channels);

  Future<void> notify(User receiver, NotificationMessage message) async {
    for (final channel in _channels) {
      await channel.send(receiver, message);
    }
  }
}
```

`NotificationService` не знає, чи це push, email або SMS. Він викликає `send()` для будь-якого `NotificationChannel`.

### Python

```python
from abc import ABC, abstractmethod


class NotificationChannel(ABC):
    @abstractmethod
    def send(self, receiver: User, message: NotificationMessage) -> None:
        raise NotImplementedError


class PushNotificationChannel(NotificationChannel):
    def send(self, receiver: User, message: NotificationMessage) -> None:
        print(f"Push to {receiver.email}: {message.title}")


class EmailNotificationChannel(NotificationChannel):
    def send(self, receiver: User, message: NotificationMessage) -> None:
        print(f"Email to {receiver.email}: {message.title}")
```

## 7. Поліморфізм: Payment methods

### Dart

```dart
abstract interface class PaymentMethod {
  Future<PaymentResult> pay(PaymentRequest request);
}

class StripeTestPaymentMethod implements PaymentMethod {
  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    return const PaymentResult(
      paymentId: 'pay_test_001',
      status: 'pending',
      provider: 'stripe_test',
    );
  }
}

class FreePlanPaymentMethod implements PaymentMethod {
  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    return const PaymentResult(
      paymentId: 'free_plan',
      status: 'succeeded',
      provider: 'internal',
    );
  }
}
```

### Python

```python
class PaymentMethod(ABC):
    @abstractmethod
    def pay(self, request: PaymentRequest) -> PaymentResult:
        raise NotImplementedError


class StripeTestPaymentMethod(PaymentMethod):
    def pay(self, request: PaymentRequest) -> PaymentResult:
        return PaymentResult(
            payment_id="pay_test_001",
            status="pending",
            provider="stripe_test",
        )


class FreePlanPaymentMethod(PaymentMethod):
    def pay(self, request: PaymentRequest) -> PaymentResult:
        return PaymentResult(
            payment_id="free_plan",
            status="succeeded",
            provider="internal",
        )
```

Код, який створює оплату, може працювати з `PaymentMethod`, не знаючи конкретної реалізації:

```python
def process_payment(method: PaymentMethod, request: PaymentRequest) -> PaymentResult:
    return method.pay(request)
```

## 8. Як це застосовується у FitTrack

| ООП принцип | Реалізація у FitTrack |
| --- | --- |
| Інкапсуляція | Private/protected fields для email, age, weight, tokens, payment status |
| Getters/setters | Валідація email, віку, ваги, training goal перед зміною |
| Наслідування | `User -> Trainer -> Admin` як навчальний приклад |
| Поліморфізм | `NotificationChannel.send()`, `PaymentMethod.pay()` |
| Абстракція | Interfaces/abstract classes для payment, notifications, repositories |
| Композиція | Production RBAC: `User` має `Role`, `Role` має `Permission` |

## 9. Висновок

FitTrack можна пояснити з точки зору ООП як систему, де:

- доменні сутності інкапсулюють стан і валідацію;
- ролі можуть бути продемонстровані через наслідування `User -> Trainer -> Admin`;
- notification system і payment system використовують поліморфізм;
- у production-архітектурі roles/permissions краще реалізовувати композицією, а не глибокою ієрархією класів.
