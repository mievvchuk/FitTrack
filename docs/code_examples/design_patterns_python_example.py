from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from functools import lru_cache


@dataclass(frozen=True)
class Exercise:
    id: str
    name: str
    muscle_group: str
    difficulty: str


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

    @abstractmethod
    def delete_by_id(self, exercise_id: str) -> None:
        raise NotImplementedError


class InMemoryExerciseRepository(ExerciseRepository):
    def __init__(self) -> None:
        self._storage: dict[str, Exercise] = {}

    def find_all(self, muscle_group: str | None = None) -> list[Exercise]:
        exercises = list(self._storage.values())
        if muscle_group is None:
            return exercises
        return [
            exercise
            for exercise in exercises
            if exercise.muscle_group == muscle_group
        ]

    def find_by_id(self, exercise_id: str) -> Exercise | None:
        return self._storage.get(exercise_id)

    def save(self, exercise: Exercise) -> Exercise:
        self._storage[exercise.id] = exercise
        return exercise

    def delete_by_id(self, exercise_id: str) -> None:
        self._storage.pop(exercise_id, None)


@dataclass(frozen=True)
class Settings:
    app_name: str = "FitTrack API"
    api_prefix: str = "/api/v1"
    stripe_mode: str = "test"


@lru_cache
def get_settings() -> Settings:
    return Settings()


@dataclass(frozen=True)
class PaymentRequest:
    user_id: str
    plan: str
    amount_cents: int
    currency: str


@dataclass(frozen=True)
class PaymentResult:
    payment_id: str
    status: str
    provider: str


class PaymentStrategy(ABC):
    @abstractmethod
    def pay(self, request: PaymentRequest) -> PaymentResult:
        raise NotImplementedError


class FreePlanPaymentStrategy(PaymentStrategy):
    def pay(self, request: PaymentRequest) -> PaymentResult:
        return PaymentResult(
            payment_id="free-plan",
            status="succeeded",
            provider="internal",
        )


class StripeTestPaymentStrategy(PaymentStrategy):
    def pay(self, request: PaymentRequest) -> PaymentResult:
        if request.amount_cents <= 0:
            raise ValueError("Premium amount must be positive.")
        return PaymentResult(
            payment_id="stripe-test-payment",
            status="pending",
            provider="stripe_test",
        )


class PaymentStrategyFactory:
    @staticmethod
    def create(plan: str) -> PaymentStrategy:
        if plan == "free":
            return FreePlanPaymentStrategy()
        if plan == "premium":
            return StripeTestPaymentStrategy()
        raise ValueError(f"Unsupported plan: {plan}")


class PaymentProcessor:
    def __init__(self, strategy: PaymentStrategy) -> None:
        self._strategy = strategy

    def checkout(self, request: PaymentRequest) -> PaymentResult:
        return self._strategy.pay(request)


@dataclass(frozen=True)
class NotificationMessage:
    title: str
    body: str


class NotificationChannel(ABC):
    @abstractmethod
    def send(self, user_id: str, message: NotificationMessage) -> None:
        raise NotImplementedError


class PushNotificationChannel(NotificationChannel):
    def send(self, user_id: str, message: NotificationMessage) -> None:
        print(f"Push to {user_id}: {message.title}")


class EmailNotificationChannel(NotificationChannel):
    def send(self, user_id: str, message: NotificationMessage) -> None:
        print(f"Email to {user_id}: {message.title}")


class NotificationChannelFactory:
    @staticmethod
    def create(channel_type: str) -> NotificationChannel:
        if channel_type == "push":
            return PushNotificationChannel()
        if channel_type == "email":
            return EmailNotificationChannel()
        raise ValueError(f"Unsupported notification channel: {channel_type}")


@dataclass(frozen=True)
class WorkoutCompletedEvent:
    user_id: str
    workout_id: str
    total_volume_kg: float


class WorkoutObserver(ABC):
    @abstractmethod
    def on_workout_completed(self, event: WorkoutCompletedEvent) -> None:
        raise NotImplementedError


class DashboardObserver(WorkoutObserver):
    def on_workout_completed(self, event: WorkoutCompletedEvent) -> None:
        print(f"Dashboard updated for {event.user_id}")


class ProgressChartObserver(WorkoutObserver):
    def on_workout_completed(self, event: WorkoutCompletedEvent) -> None:
        print(f"Progress chart volume: {event.total_volume_kg}")


class WorkoutProgressSubject:
    def __init__(self) -> None:
        self._observers: list[WorkoutObserver] = []

    def attach(self, observer: WorkoutObserver) -> None:
        if observer not in self._observers:
            self._observers.append(observer)

    def detach(self, observer: WorkoutObserver) -> None:
        if observer in self._observers:
            self._observers.remove(observer)

    def complete_workout(self, event: WorkoutCompletedEvent) -> None:
        for observer in list(self._observers):
            observer.on_workout_completed(event)


def demo() -> None:
    repository = InMemoryExerciseRepository()
    repository.save(
        Exercise(
            id="exercise-1",
            name="Bench Press",
            muscle_group="chest",
            difficulty="intermediate",
        )
    )
    print(f"Repository found: {len(repository.find_all(muscle_group='chest'))}")

    settings_a = get_settings()
    settings_b = get_settings()
    print(f"Singleton same instance: {settings_a is settings_b}")

    strategy = PaymentStrategyFactory.create("premium")
    processor = PaymentProcessor(strategy)
    payment = processor.checkout(
        PaymentRequest(
            user_id="user-1",
            plan="premium",
            amount_cents=999,
            currency="USD",
        )
    )
    print(f"Payment provider: {payment.provider}")

    notification = NotificationChannelFactory.create("push")
    notification.send(
        "user-1",
        NotificationMessage(
            title="Workout completed",
            body="Great job!",
        ),
    )

    subject = WorkoutProgressSubject()
    subject.attach(DashboardObserver())
    subject.attach(ProgressChartObserver())
    subject.complete_workout(
        WorkoutCompletedEvent(
            user_id="user-1",
            workout_id="workout-1",
            total_volume_kg=5820,
        )
    )


if __name__ == "__main__":
    demo()
