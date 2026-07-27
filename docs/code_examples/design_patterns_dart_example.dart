class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String difficulty;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.difficulty,
  });
}

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
    if (request.amountCents <= 0) {
      throw ArgumentError('Premium amount must be positive.');
    }
    return const PaymentResult(
      paymentId: 'stripe-test-payment',
      status: 'pending',
      provider: 'stripe_test',
    );
  }
}

class PaymentStrategyFactory {
  static PaymentStrategy create(String plan) {
    return switch (plan) {
      'free' => FreePlanPaymentStrategy(),
      'premium' => StripeTestPaymentStrategy(),
      _ => throw ArgumentError('Unsupported plan: $plan'),
    };
  }
}

class PaymentProcessor {
  final PaymentStrategy _strategy;

  PaymentProcessor(this._strategy);

  Future<PaymentResult> checkout(PaymentRequest request) {
    return _strategy.pay(request);
  }
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
  Future<void> send(String userId, NotificationMessage message);
}

class PushNotificationChannel implements NotificationChannel {
  @override
  Future<void> send(String userId, NotificationMessage message) async {
    print('Push to $userId: ${message.title}');
  }
}

class EmailNotificationChannel implements NotificationChannel {
  @override
  Future<void> send(String userId, NotificationMessage message) async {
    print('Email to $userId: ${message.title}');
  }
}

enum NotificationType { push, email }

class NotificationChannelFactory {
  static NotificationChannel create(NotificationType type) {
    return switch (type) {
      NotificationType.push => PushNotificationChannel(),
      NotificationType.email => EmailNotificationChannel(),
    };
  }
}

class WorkoutCompletedEvent {
  final String userId;
  final String workoutId;
  final double totalVolumeKg;

  const WorkoutCompletedEvent({
    required this.userId,
    required this.workoutId,
    required this.totalVolumeKg,
  });
}

abstract interface class WorkoutObserver {
  void onWorkoutCompleted(WorkoutCompletedEvent event);
}

class DashboardObserver implements WorkoutObserver {
  @override
  void onWorkoutCompleted(WorkoutCompletedEvent event) {
    print('Dashboard updated for ${event.userId}');
  }
}

class ProgressChartObserver implements WorkoutObserver {
  @override
  void onWorkoutCompleted(WorkoutCompletedEvent event) {
    print('Progress chart volume: ${event.totalVolumeKg}');
  }
}

class WorkoutProgressSubject {
  final List<WorkoutObserver> _observers = [];

  void attach(WorkoutObserver observer) {
    if (!_observers.contains(observer)) {
      _observers.add(observer);
    }
  }

  void detach(WorkoutObserver observer) {
    _observers.remove(observer);
  }

  void completeWorkout(WorkoutCompletedEvent event) {
    for (final observer in List<WorkoutObserver>.from(_observers)) {
      observer.onWorkoutCompleted(event);
    }
  }
}

Future<void> main() async {
  final repository = InMemoryExerciseRepository();
  await repository.save(
    const Exercise(
      id: 'exercise-1',
      name: 'Bench Press',
      muscleGroup: 'chest',
      difficulty: 'intermediate',
    ),
  );
  final chestExercises = await repository.findAll(muscleGroup: 'chest');
  print('Repository found: ${chestExercises.length}');

  final configA = ApiConfig();
  final configB = ApiConfig.instance;
  print('Singleton same instance: ${identical(configA, configB)}');

  final strategy = PaymentStrategyFactory.create('premium');
  final processor = PaymentProcessor(strategy);
  final payment = await processor.checkout(
    const PaymentRequest(
      userId: 'user-1',
      plan: 'premium',
      amountCents: 999,
      currency: 'USD',
    ),
  );
  print('Payment provider: ${payment.provider}');

  final notification = NotificationChannelFactory.create(NotificationType.push);
  await notification.send(
    'user-1',
    const NotificationMessage(
      title: 'Workout completed',
      body: 'Great job!',
    ),
  );

  final subject = WorkoutProgressSubject()
    ..attach(DashboardObserver())
    ..attach(ProgressChartObserver());
  subject.completeWorkout(
    const WorkoutCompletedEvent(
      userId: 'user-1',
      workoutId: 'workout-1',
      totalVolumeKg: 5820,
    ),
  );
}
