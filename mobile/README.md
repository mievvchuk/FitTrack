# FitTrack Mobile

Flutter mobile application scaffold for FitTrack.

## Architecture

The project uses Clean Architecture with feature-first folders:

```text
lib/
  app/
  core/
  features/
    auth/
      data/
      domain/
      presentation/
    profile/
    exercises/
    workouts/
    progress/
    analytics/
    payments/
    ai_assistant/
  models/
  services/
```

## State Management

Riverpod is used for dependency injection and UI state.

## Localization

FitTrack uses Flutter `gen-l10n` with ARB files:

```text
lib/l10n/app_uk.arb
lib/l10n/app_en.arb
lib/l10n/app_de.arb
```

Generate localization sources after changing translations:

```bash
flutter gen-l10n
```

Language switching is available on the Profile screen and persists the selected locale in secure storage.

## Firebase Setup

If Flutter SDK was not available when this scaffold was created, generate the
native Android/iOS wrappers first:

```bash
cd mobile
flutter create --platforms=android,ios .
```

Replace `lib/firebase_options.dart` with real generated options:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --out=lib/firebase_options.dart
```

Enable these Firebase Authentication providers in Firebase Console:

- Email/Password
- Google

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Production API communication should use HTTPS:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.fittrack.example/api/v1 \
  --dart-define=REQUIRE_HTTPS=true
```

JWT access and refresh tokens are stored through `flutter_secure_storage` in `SecureStorageService`.

For iOS simulator, use:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Codemagic iOS build

The root `codemagic.yaml` contains iOS workflows for simulator checks and signed release IPA builds.

Required Codemagic variable group:

```text
fittrack_mobile
```

Required variables:

- `API_BASE_URL`
- `REQUIRE_HTTPS`
- `BUNDLE_ID`
- `FIREBASE_OPTIONS_DART_BASE64` for real Firebase options, optional for coursework scaffolding

Do not pass AI provider keys to Flutter builds. `ZAI_API_KEY` must stay on the backend server only.
