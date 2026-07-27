from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import delete, select
from sqlalchemy.orm import Session, selectinload

from app.core.security import require_permission
from app.db.session import get_db
from app.models.payments import Payment
from app.models.rbac import Role, TrainerClient, User, UserRole
from app.schemas.rbac import AssignRoleRequest, CurrentUserRead, PermissionRead, RoleRead
from app.schemas.payments import PaymentRead
from app.services.rbac_service import current_user_payload

router = APIRouter(tags=["RBAC"])


@router.get("/roles", response_model=list[RoleRead])
def list_roles(
    _: User = Depends(require_permission("users:manage")),
    db: Session = Depends(get_db),
) -> list[Role]:
    return list(
        db.scalars(
            select(Role)
            .options(selectinload(Role.permissions))
            .order_by(Role.code)
        )
    )


@router.get("/permissions", response_model=list[PermissionRead])
def list_permissions(
    _: User = Depends(require_permission("users:manage")),
    db: Session = Depends(get_db),
):
    from app.models.rbac import Permission

    return list(db.scalars(select(Permission).order_by(Permission.resource, Permission.action)))


@router.get("/users/{user_id}/roles", response_model=CurrentUserRead)
def get_user_roles(
    user_id: UUID,
    _: User = Depends(require_permission("users:manage")),
    db: Session = Depends(get_db),
) -> dict[str, object]:
    user = db.scalar(
        select(User)
        .options(selectinload(User.roles).selectinload(Role.permissions))
        .where(User.id == user_id)
    )
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return current_user_payload(user)


@router.post("/users/{user_id}/roles", response_model=CurrentUserRead)
def assign_role(
    user_id: UUID,
    payload: AssignRoleRequest,
    _: User = Depends(require_permission("users:manage")),
    db: Session = Depends(get_db),
) -> dict[str, object]:
    user = db.scalar(
        select(User)
        .options(selectinload(User.roles).selectinload(Role.permissions))
        .where(User.id == user_id)
    )
    role = db.scalar(select(Role).where(Role.code == payload.role_code))

    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    if role is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")

    if role.code not in {user_role.code for user_role in user.roles}:
        user.roles.append(role)
        db.commit()
        db.refresh(user)

    return current_user_payload(user)


@router.delete("/users/{user_id}/roles/{role_code}", response_model=CurrentUserRead)
def remove_role(
    user_id: UUID,
    role_code: str,
    _: User = Depends(require_permission("users:manage")),
    db: Session = Depends(get_db),
) -> dict[str, object]:
    role = db.scalar(select(Role).where(Role.code == role_code))
    if role is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")

    db.execute(delete(UserRole).where(UserRole.user_id == user_id, UserRole.role_id == role.id))
    db.commit()

    user = db.scalar(
        select(User)
        .options(selectinload(User.roles).selectinload(Role.permissions))
        .where(User.id == user_id)
    )
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return current_user_payload(user)


@router.get("/trainer/clients", response_model=list[CurrentUserRead])
def trainer_clients(
    current_user: User = Depends(require_permission("clients:read")),
    db: Session = Depends(get_db),
) -> list[dict[str, object]]:
    client_ids = select(TrainerClient.client_id).where(
        TrainerClient.trainer_id == current_user.id,
        TrainerClient.status == "active",
    )
    clients = db.scalars(
        select(User)
        .options(selectinload(User.roles).selectinload(Role.permissions))
        .where(User.id.in_(client_ids))
        .order_by(User.email)
    )
    return [current_user_payload(client) for client in clients]


@router.post("/workouts/{workout_id}/complete")
def complete_workout(
    workout_id: UUID,
    _: User = Depends(require_permission("workouts:complete")),
) -> dict[str, str]:
    return {"status": "allowed", "workout_id": str(workout_id)}


@router.post("/trainer/programs")
def create_training_program(
    _: User = Depends(require_permission("programs:create")),
) -> dict[str, str]:
    return {"status": "allowed", "scope": "trainer_programs"}


@router.get("/admin/payments", response_model=list[PaymentRead])
def admin_payments(
    _: User = Depends(require_permission("payments:read")),
    db: Session = Depends(get_db),
) -> list[Payment]:
    return list(db.scalars(select(Payment).order_by(Payment.created_at.desc()).limit(100)))
