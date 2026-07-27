# FitTrack - система ролей і прав доступу

## 1. Ролі

| Роль | Призначення | Основні можливості |
| --- | --- | --- |
| `user` | Звичайний користувач застосунку | проходить тренування, переглядає вправи, веде прогрес, оплачує Premium |
| `trainer` | Тренер | створює програми тренувань, додає вправи, переглядає клієнтів |
| `admin` | Адміністратор системи | керує користувачами, додає та редагує вправи, переглядає платежі |

## 2. Permissions

| Permission | User | Trainer | Admin |
| --- | --- | --- | --- |
| `workouts:complete` | + |  | + |
| `exercises:read` | + | + | + |
| `progress:manage` | + |  | + |
| `premium:pay` | + |  | + |
| `programs:create` |  | + | + |
| `exercises:create` |  | + | + |
| `clients:read` |  | + | + |
| `users:manage` |  |  | + |
| `exercises:update` |  |  | + |
| `payments:read` |  |  | + |

## 3. Таблиці бази даних

RBAC винесено в окремі нормалізовані таблиці:

```text
users
  id PK
  firebase_uid UNIQUE
  email UNIQUE

roles
  id PK
  code UNIQUE
  name

permissions
  id PK
  code UNIQUE
  resource
  action

user_roles
  user_id FK -> users.id
  role_id FK -> roles.id
  PK(user_id, role_id)

role_permissions
  role_id FK -> roles.id
  permission_id FK -> permissions.id
  PK(role_id, permission_id)

trainer_clients
  trainer_id FK -> users.id
  client_id FK -> users.id
  PK(trainer_id, client_id)
```

## 4. Backend middleware

У FastAPI доступ перевіряється через dependency-функції:

```python
@router.get("/admin/payments")
def admin_payments(
    _: User = Depends(require_permission("payments:read")),
):
    ...
```

Алгоритм:

1. Flutter надсилає `Authorization: Bearer <firebase_id_token>`.
2. Backend перевіряє токен через Firebase Admin SDK.
3. Backend знаходить локального користувача за `firebase_uid`.
4. Backend збирає permissions через `users -> user_roles -> roles -> role_permissions -> permissions`.
5. Якщо потрібного permission немає, повертається `403 Forbidden`.

## 5. API endpoints

| Method | Endpoint | Permission | Опис |
| --- | --- | --- | --- |
| POST | `/api/v1/auth/sync-user` | Firebase token | Створити локального користувача і видати роль `user` |
| GET | `/api/v1/auth/me` | authenticated | Поточний користувач, ролі та permissions |
| GET | `/api/v1/roles` | `users:manage` | Список ролей |
| GET | `/api/v1/permissions` | `users:manage` | Список permissions |
| GET | `/api/v1/users/{user_id}/roles` | `users:manage` | Ролі конкретного користувача |
| POST | `/api/v1/users/{user_id}/roles` | `users:manage` | Додати роль користувачу |
| DELETE | `/api/v1/users/{user_id}/roles/{role_code}` | `users:manage` | Забрати роль у користувача |
| GET | `/api/v1/trainer/clients` | `clients:read` | Клієнти тренера |
| POST | `/api/v1/trainer/programs` | `programs:create` | Створення тренерської програми |
| GET | `/api/v1/admin/payments` | `payments:read` | Перегляд платежів адміністратором |

## 6. Flutter navigation

У Flutter користувач після `/auth/sync-user` отримує:

```json
{
  "roles": ["trainer"],
  "permissions": ["exercises:read", "programs:create", "clients:read"]
}
```

Ці дані зберігаються в `AuthUser`. `GoRouter` блокує прямий перехід:

- `/trainer/*` доступний, якщо є `programs:create` або `clients:read`;
- `/admin/*` доступний тільки для ролі `admin`;
- базові екрани `Home`, `Exercises`, `Workouts`, `Progress`, `Premium` будуються через `RoleBasedNavigation.itemsFor(user)`.

Важливо: Flutter-навігація відповідає лише за UX. Реальна безпека завжди виконується на backend через `require_permission(...)`.
