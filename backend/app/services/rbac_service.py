from app.models.rbac import User


def role_codes(user: User) -> list[str]:
    return sorted({role.code for role in user.roles})


def permission_codes(user: User) -> list[str]:
    return sorted(
        {
            permission.code
            for role in user.roles
            for permission in role.permissions
        }
    )


def current_user_payload(user: User) -> dict[str, object]:
    return {
        "id": user.id,
        "firebase_uid": user.firebase_uid,
        "email": user.email,
        "email_verified": user.email_verified_at is not None,
        "roles": role_codes(user),
        "permissions": permission_codes(user),
    }
