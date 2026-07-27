from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from decimal import Decimal


class User:
    def __init__(
        self,
        user_id: str,
        email: str,
        full_name: str,
        age: int,
        weight_kg: Decimal,
        training_goal: str,
    ) -> None:
        self.id = user_id
        self._email = ""
        self._full_name = ""
        self._age = 0
        self._weight_kg = Decimal("0")
        self._training_goal = training_goal

        self.email = email
        self.full_name = full_name
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
    def full_name(self) -> str:
        return self._full_name

    @full_name.setter
    def full_name(self, value: str) -> None:
        trimmed = value.strip()
        if len(trimmed) < 2:
            raise ValueError("Full name is too short.")
        self._full_name = trimmed

    @property
    def age(self) -> int:
        return self._age

    @age.setter
    def age(self, value: int) -> None:
        if value < 10 or value > 100:
            raise ValueError("Age must be between 10 and 100.")
        self._age = value

    @property
    def weight_kg(self) -> Decimal:
        return self._weight_kg

    @weight_kg.setter
    def weight_kg(self, value: Decimal) -> None:
        if value < Decimal("25") or value > Decimal("300"):
            raise ValueError("Weight must be between 25 and 300 kg.")
        self._weight_kg = value

    @property
    def training_goal(self) -> str:
        return self._training_goal

    @training_goal.setter
    def training_goal(self, value: str) -> None:
        allowed = {"weight_loss", "muscle_gain", "strength", "endurance", "general_fitness"}
        if value not in allowed:
            raise ValueError("Unsupported training goal.")
        self._training_goal = value

    @property
    def permissions(self) -> set[str]:
        return {
            "exercises:read",
            "workouts:complete",
            "progress:manage",
            "premium:pay",
        }

    @property
    def role_code(self) -> str:
        return "user"

    def dashboard_title(self) -> str:
        return f"Athlete: {self.full_name}"


class Trainer(User):
    def __init__(
        self,
        user_id: str,
        email: str,
        full_name: str,
        age: int,
        weight_kg: Decimal,
        training_goal: str,
    ) -> None:
        super().__init__(user_id, email, full_name, age, weight_kg, training_goal)
        self._client_ids: list[str] = []

    @property
    def client_ids(self) -> tuple[str, ...]:
        return tuple(self._client_ids)

    @property
    def permissions(self) -> set[str]:
        return super().permissions | {
            "programs:create",
            "clients:read",
            "exercises:create",
        }

    @property
    def role_code(self) -> str:
        return "trainer"

    def assign_client(self, client_id: str) -> None:
        if not client_id.strip():
            raise ValueError("Client id cannot be empty.")
        if client_id not in self._client_ids:
            self._client_ids.append(client_id)

    def dashboard_title(self) -> str:
        return f"Trainer: {self.full_name}, clients: {len(self._client_ids)}"


class Admin(Trainer):
    @property
    def permissions(self) -> set[str]:
        return super().permissions | {
            "users:manage",
            "exercises:update",
            "payments:read",
        }

    @property
    def role_code(self) -> str:
        return "admin"

    def deactivate_user(self, user: User) -> None:
        # Demo action. In production this would call a repository/service method.
        if user.id == self.id:
            raise ValueError("Admin cannot deactivate own account.")

    def dashboard_title(self) -> str:
        return f"Admin: {self.full_name}"


@dataclass(frozen=True)
class NotificationMessage:
    title: str
    body: str


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


class NotificationService:
    def __init__(self, channels: list[NotificationChannel]) -> None:
        self._channels = channels

    def notify(self, receiver: User, message: NotificationMessage) -> None:
        for channel in self._channels:
            channel.send(receiver, message)


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


class PaymentMethod(ABC):
    @abstractmethod
    def pay(self, request: PaymentRequest) -> PaymentResult:
        raise NotImplementedError


class StripeTestPaymentMethod(PaymentMethod):
    def pay(self, request: PaymentRequest) -> PaymentResult:
        if request.amount_cents <= 0:
            raise ValueError("Premium payment amount must be positive.")
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


def demo() -> None:
    user = User(
        user_id="user-1",
        email="ivan@example.com",
        full_name="Ivan Petrenko",
        age=22,
        weight_kg=Decimal("78.5"),
        training_goal="muscle_gain",
    )
    trainer = Trainer(
        user_id="trainer-1",
        email="coach@example.com",
        full_name="Coach Fit",
        age=31,
        weight_kg=Decimal("82"),
        training_goal="strength",
    )
    trainer.assign_client(user.id)
    admin = Admin(
        user_id="admin-1",
        email="admin@example.com",
        full_name="System Admin",
        age=35,
        weight_kg=Decimal("76"),
        training_goal="general_fitness",
    )

    for account in [user, trainer, admin]:
        print(f"{account.role_code}: {account.dashboard_title()}")

    notifications = NotificationService(
        channels=[PushNotificationChannel(), EmailNotificationChannel()]
    )
    notifications.notify(
        user,
        NotificationMessage(
            title="Workout reminder",
            body="Push Day starts in 30 minutes.",
        ),
    )

    methods: list[PaymentMethod] = [
        FreePlanPaymentMethod(),
        StripeTestPaymentMethod(),
    ]
    for method in methods:
        result = method.pay(
            PaymentRequest(
                user_id=user.id,
                plan="premium",
                amount_cents=999,
                currency="USD",
            )
        )
        print(f"{result.provider}: {result.status}")


if __name__ == "__main__":
    demo()
