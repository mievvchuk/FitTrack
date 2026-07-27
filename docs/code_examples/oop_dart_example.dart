enum Gender { male, female, other }

enum TrainingGoal { weightLoss, muscleGain, strength, endurance, generalFitness }

class User {
  final String id;
  String _email;
  String _fullName;
  int _age;
  double _weightKg;
  TrainingGoal _trainingGoal;

  User({
    required this.id,
    required String email,
    required String fullName,
    required int age,
    required double weightKg,
    required TrainingGoal trainingGoal,
  })  : _email = '',
        _fullName = '',
        _age = 0,
        _weightKg = 0,
        _trainingGoal = trainingGoal {
    this.email = email;
    this.fullName = fullName;
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

  String get fullName => _fullName;

  set fullName(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      throw ArgumentError('Full name is too short.');
    }
    _fullName = trimmed;
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

  TrainingGoal get trainingGoal => _trainingGoal;

  set trainingGoal(TrainingGoal value) {
    _trainingGoal = value;
  }

  List<String> get permissions => const [
        'exercises:read',
        'workouts:complete',
        'progress:manage',
        'premium:pay',
      ];

  String get roleCode => 'user';

  String dashboardTitle() => 'Athlete: $_fullName';
}

class Trainer extends User {
  final List<String> _clientIds = [];

  Trainer({
    required super.id,
    required super.email,
    required super.fullName,
    required super.age,
    required super.weightKg,
    required super.trainingGoal,
  });

  List<String> get clientIds => List.unmodifiable(_clientIds);

  @override
  List<String> get permissions => [
        ...super.permissions,
        'programs:create',
        'clients:read',
        'exercises:create',
      ];

  @override
  String get roleCode => 'trainer';

  void assignClient(String clientId) {
    if (clientId.trim().isEmpty) {
      throw ArgumentError('Client id cannot be empty.');
    }
    if (!_clientIds.contains(clientId)) {
      _clientIds.add(clientId);
    }
  }

  @override
  String dashboardTitle() => 'Trainer: $fullName, clients: ${_clientIds.length}';
}

class Admin extends Trainer {
  Admin({
    required super.id,
    required super.email,
    required super.fullName,
    required super.age,
    required super.weightKg,
    required super.trainingGoal,
  });

  @override
  List<String> get permissions => [
        ...super.permissions,
        'users:manage',
        'exercises:update',
        'payments:read',
      ];

  @override
  String get roleCode => 'admin';

  void deactivateUser(User user) {
    // Demo action. In production this would call Admin API.
    if (user.id == id) {
      throw StateError('Admin cannot deactivate own account.');
    }
  }

  @override
  String dashboardTitle() => 'Admin: $fullName';
}

class NotificationMessage {
  final String title;
  final String body;

  const NotificationMessage({
    required this.title,
    required this.body,
  });
}

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

class PaymentRequest {
  final String userId;
  final String plan;
  final int amountCents;
  final String currency;

  const PaymentRequest({
    required this.userId,
    required this.plan,
    required this.amountCents,
    required this.currency,
  });
}

class PaymentResult {
  final String paymentId;
  final String status;
  final String provider;

  const PaymentResult({
    required this.paymentId,
    required this.status,
    required this.provider,
  });
}

abstract interface class PaymentMethod {
  Future<PaymentResult> pay(PaymentRequest request);
}

class StripeTestPaymentMethod implements PaymentMethod {
  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    if (request.amountCents <= 0) {
      throw ArgumentError('Premium payment amount must be positive.');
    }
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

Future<void> main() async {
  final user = User(
    id: 'user-1',
    email: 'ivan@example.com',
    fullName: 'Ivan Petrenko',
    age: 22,
    weightKg: 78.5,
    trainingGoal: TrainingGoal.muscleGain,
  );

  final trainer = Trainer(
    id: 'trainer-1',
    email: 'coach@example.com',
    fullName: 'Coach Fit',
    age: 31,
    weightKg: 82,
    trainingGoal: TrainingGoal.strength,
  )..assignClient(user.id);

  final admin = Admin(
    id: 'admin-1',
    email: 'admin@example.com',
    fullName: 'System Admin',
    age: 35,
    weightKg: 76,
    trainingGoal: TrainingGoal.generalFitness,
  );

  final users = <User>[user, trainer, admin];
  for (final account in users) {
    print('${account.roleCode}: ${account.dashboardTitle()}');
  }

  final notifications = NotificationService([
    PushNotificationChannel(),
    EmailNotificationChannel(),
  ]);
  await notifications.notify(
    user,
    const NotificationMessage(
      title: 'Workout reminder',
      body: 'Push Day starts in 30 minutes.',
    ),
  );

  final paymentMethods = <PaymentMethod>[
    FreePlanPaymentMethod(),
    StripeTestPaymentMethod(),
  ];

  for (final method in paymentMethods) {
    final result = await method.pay(
      PaymentRequest(
        userId: user.id,
        plan: 'premium',
        amountCents: 999,
        currency: 'USD',
      ),
    );
    print('${result.provider}: ${result.status}');
  }
}
