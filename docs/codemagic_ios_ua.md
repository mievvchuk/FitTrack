# FitTrack - Codemagic iOS build

Цей документ пояснює, як зібрати FitTrack для iPhone через Codemagic.

## Важливе правило для AI key

`ZAI_API_KEY` не можна додавати в Flutter або iOS build.

Правильний flow:

```text
iPhone app -> FitTrack Backend -> Z.AI API
```

У мобільний застосунок передається тільки URL backend:

```text
API_BASE_URL=https://your-backend-domain.com/api/v1
```

AI key має бути тільки на backend server у змінних середовища:

```env
ZAI_API_KEY=replace-with-real-secret
ZAI_BASE_URL=https://api.z.ai/api/paas/v4
ZAI_CHAT_MODEL=glm-5.2
```

## Codemagic variables

У Codemagic відкрий:

```text
App settings -> Environment variables
```

Створи group:

```text
fittrack_mobile
```

Додай змінні:

| Name | Example | Secret |
| --- | --- | --- |
| `API_BASE_URL` | `https://fittrack-api.example.com/api/v1` | No |
| `REQUIRE_HTTPS` | `true` | No |
| `BUNDLE_ID` | `com.fittrack.mobile` | No |
| `FIREBASE_OPTIONS_DART_BASE64` | base64 content of `firebase_options.dart` | Yes |

`FIREBASE_OPTIONS_DART_BASE64` опціональна, але рекомендована для реального Firebase project.

## Як підготувати Firebase options

Локально після `flutterfire configure` можна закодувати файл:

```bash
base64 -i mobile/lib/firebase_options.dart
```

У Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("mobile/lib/firebase_options.dart"))
```

Скопіюй результат у Codemagic variable `FIREBASE_OPTIONS_DART_BASE64` і познач її як `Secret`.

## iOS signing

Для signed `.ipa` потрібен Apple Developer Program.

У Codemagic потрібно налаштувати:

- App Store Connect integration;
- iOS certificate;
- provisioning profile;
- bundle id `BUNDLE_ID`.

Workflow `ios-release` використовує:

```yaml
ios_signing:
  distribution_type: app_store
  bundle_identifier: $BUNDLE_ID
```

і команду:

```bash
xcode-project use-profiles
```

## Workflows

У root файлі `codemagic.yaml` є два workflows:

| Workflow | Призначення |
| --- | --- |
| `ios-simulator-check` | Перевірка Flutter analyze/test і debug build для iOS simulator |
| `ios-release` | Signed release `.ipa` для TestFlight/App Store |

## Чому `flutter create` запускається в CI

У репозиторії поки не зберігаються native папки:

```text
mobile/ios
mobile/android
```

Тому Codemagic виконує:

```bash
cd mobile
flutter create --platforms=ios,android --org com.fittrack .
```

Це генерує native wrappers на build machine перед `flutter pub get` і `flutter build ipa`.

Після генерації workflow замінює `PRODUCT_BUNDLE_IDENTIFIER` у Xcode project на значення з `BUNDLE_ID`, щоб iOS signing profile збігався з application id.

## Запуск build

1. Підключи GitHub repo до Codemagic.
2. Переконайся, що Codemagic бачить `codemagic.yaml`.
3. Додай group `fittrack_mobile`.
4. Для першої перевірки запусти `ios-simulator-check`.
5. Після налаштування Apple signing запусти `ios-release`.

## Типові проблеми

### Немає Apple signing

Симптом:

```text
No profiles for bundle id were found
```

Рішення:

- перевірити `BUNDLE_ID`;
- додати certificate і provisioning profile;
- або налаштувати automatic signing через App Store Connect integration.

### Firebase не працює

Симптом:

```text
FirebaseOptions values are placeholders
```

Рішення:

- згенерувати реальний `firebase_options.dart`;
- додати його в `FIREBASE_OPTIONS_DART_BASE64`;
- не комітити приватні service account keys.

### AI Assistant повертає помилку

Симптом:

```text
ZAI_API_KEY is not configured
```

Рішення:

- додати `ZAI_API_KEY` на backend server;
- не додавати `ZAI_API_KEY` у Codemagic mobile workflow.
