from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr


class SyncUserRequest(BaseModel):
    email: EmailStr | None = None
    display_name: str | None = None
    photo_url: str | None = None


class PermissionRead(BaseModel):
    code: str
    name: str
    description: str | None = None
    resource: str
    action: str

    model_config = ConfigDict(from_attributes=True)


class RoleRead(BaseModel):
    code: str
    name: str
    description: str | None = None
    permissions: list[PermissionRead] = []

    model_config = ConfigDict(from_attributes=True)


class CurrentUserRead(BaseModel):
    id: UUID
    firebase_uid: str
    email: EmailStr
    email_verified: bool = False
    roles: list[str]
    permissions: list[str]


class AssignRoleRequest(BaseModel):
    role_code: str
