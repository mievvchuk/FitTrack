# FitTrack - production security layer

## 1. Бібліотеки

| Блок | Бібліотека | Де підключена | Для чого |
| --- | --- | --- | --- |
| JWT access tokens | `PyJWT[crypto]` | `backend/requirements.txt`, `backend/app/services/auth_security_service.py` | Підпис і перевірка access JWT |
| Password hashing | `pwdlib[argon2]` | `backend/requirements.txt`, `backend/app/services/auth_security_service.py` | Argon2id hashing для паролів |
| Rate limiting | `slowapi` | `backend/app/core/rate_limit.py`, `backend/app/main.py`, `backend/app/api/v1/auth.py` | Обмеження частоти login/register/refresh |
| API validation | FastAPI + Pydantic | `backend/app/schemas/*.py`, `backend/app/main.py` | Типізована валідація request body/query/path |
| Permission checking | FastAPI dependencies | `backend/app/core/security.py` | `require_permission(...)`, `require_role(...)` |
| Firebase token verification | `firebase-admin` | `backend/app/core/security.py` | Перевірка Firebase ID token для Google/Firebase auth |
| Encrypted mobile storage | `flutter_secure_storage` | `mobile/lib/core/storage/secure_storage_service.dart` | Зберігання access/refresh tokens у Keychain/Keystore |
| Secure API communication | HTTPS + security headers | `backend/app/main.py`, `backend/app/core/security_headers.py`, `mobile/lib/core/network/api_client.dart` | HTTPS redirect, HSTS, TrustedHost, CORS, HTTPS-only production client |

## 2. Authentication flow

FitTrack підтримує два production-safe варіанти:

1. Firebase Authentication:
   - Flutter отримує Firebase ID token.
   - Backend перевіряє його через Firebase Admin SDK.
   - `/auth/sync-user` синхронізує користувача у PostgreSQL.

2. Backend JWT Authentication:
   - `/auth/register` створює користувача з Argon2id password hash.
   - `/auth/verify-email` підтверджує email.
   - `/auth/login` видає короткий access JWT і довгий refresh token.
   - `/auth/refresh` ротує refresh token.
   - `/auth/logout` відкликає refresh token.

Access token короткоживучий: `JWT_ACCESS_TOKEN_MINUTES=15`.
Refresh token довший: `JWT_REFRESH_TOKEN_DAYS=30`, але в БД зберігається тільки digest.

## 3. Database security fields

У `users` додано:

- `password_hash`;
- `email_verified_at`;
- `failed_login_attempts`;
- `locked_until`;
- `last_password_changed_at`;
- `token_version`.

Окремі таблиці:

- `refresh_tokens`: HMAC/SHA-256 digest refresh token, expiry, revoke time, device/user-agent/IP.
- `email_verification_tokens`: digest email verification token, expiry, consumed time.

## 4. Приклади реалізації

### Password hashing

```python
from pwdlib import PasswordHash

password_hasher = PasswordHash.recommended()

password_hash = password_hasher.hash(password)
is_valid = password_hasher.verify(password, password_hash)
```

### JWT access token

```python
payload = {
    "iss": settings.jwt_issuer,
    "aud": settings.jwt_audience,
    "sub": str(user.id),
    "type": "access",
    "exp": expires_at,
}

token = jwt.encode(payload, settings.jwt_secret_key, algorithm="HS256")
```

### Refresh token storage

```python
refresh_token = secrets.token_urlsafe(64)
token_hash = hmac.new(
    settings.jwt_secret_key.encode("utf-8"),
    refresh_token.encode("utf-8"),
    hashlib.sha256,
).hexdigest()
```

Plain refresh token повертається клієнту один раз. У PostgreSQL зберігається тільки `token_hash`.

### Permission checking

```python
@router.get("/admin/payments")
def admin_payments(
    _: User = Depends(require_permission("payments:read")),
):
    ...
```

Flutter може приховувати екрани, але реальна перевірка доступу завжди виконується на backend.

### Rate limiting

```python
@router.post("/auth/login")
@limiter.limit("5/minute")
def login(request: Request, payload: LoginRequest):
    ...
```

Для production потрібно замінити `RATE_LIMIT_STORAGE_URI=memory://` на Redis, наприклад `redis://redis:6379/0`.

### API validation

```python
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=12, max_length=128)
```

FastAPI автоматично повертає `422`, якщо payload не проходить Pydantic validation.

### Encrypted mobile storage

```dart
await secureStorage.saveAuthTokens(
  accessToken: accessToken,
  refreshToken: refreshToken,
);
```

`flutter_secure_storage` використовує iOS Keychain/macOS Keychain та Android Keystore-backed encrypted storage.

### Secure API communication

Production запуск Flutter:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.fittrack.example/api/v1 \
  --dart-define=REQUIRE_HTTPS=true
```

Production backend:

```env
ENFORCE_HTTPS=true
ALLOWED_HOSTS=["api.fittrack.example"]
ALLOWED_ORIGINS=["https://fittrack.example"]
JWT_SECRET_KEY=<long-random-secret>
RATE_LIMIT_STORAGE_URI=redis://redis:6379/0
```

## 5. Production checklist

- Use long random `JWT_SECRET_KEY`.
- Never commit `.env`.
- Use HTTPS/TLS at load balancer or reverse proxy.
- Enable `ENFORCE_HTTPS=true` behind a proxy that forwards HTTPS correctly.
- Use Redis for distributed rate limiting.
- Rotate refresh tokens on every refresh.
- Store only token hashes, never plaintext refresh tokens.
- Send email verification tokens via email provider in production; `verification_token_demo` is only for coursework/demo.
- Keep Firebase Admin credentials outside source code.
- Log security events without logging passwords, tokens, cards, or raw Authorization headers.
