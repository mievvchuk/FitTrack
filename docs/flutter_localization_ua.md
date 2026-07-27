# FitTrack - мультимовність Flutter

## 1. Призначення

Мультимовність дозволяє користувачу працювати з FitTrack трьома мовами:

- українська;
- англійська;
- німецька.

Локалізація реалізована стандартним Flutter `gen-l10n` workflow через ARB-файли.

## 2. Структура файлів

```text
mobile/
  l10n.yaml
  lib/
    l10n/
      app_uk.arb
      app_en.arb
      app_de.arb
    core/
      localization/
        locale_controller.dart
```

`l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
preferred-supported-locales:
  - uk
  - en
  - de
nullable-getter: false
```

## 3. ARB files

ARB - це JSON-подібний формат для перекладів Flutter.

Приклад:

```json
{
  "@@locale": "uk",
  "loginTitle": "Вхід у FitTrack",
  "signIn": "Увійти",
  "language": "Мова"
}
```

Англійський файл `app_en.arb` є template-файлом. Кожен ключ із `app_en.arb` має бути присутній у `app_uk.arb` та `app_de.arb`.

## 4. Підключення в Flutter

У `pubspec.yaml` додано:

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2

flutter:
  generate: true
```

У `FitTrackApp` підключено:

```dart
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
locale: ref.watch(localeControllerProvider),
onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
```

## 5. Language switching

Перемикач мови знаходиться на екрані `Profile`.

Доступні варіанти:

- System language;
- Українська;
- English;
- Deutsch.

Вибрана мова зберігається у `Flutter Secure Storage` за ключем:

```text
fittrack.locale
```

Якщо користувач вибирає `System language`, локальний override видаляється, і Flutter використовує мову пристрою.

## 6. Translation system

Код отримує переклади так:

```dart
final l10n = AppLocalizations.of(context);
Text(l10n.loginTitle);
```

Переклади вже підключені до:

- Home Dashboard;
- Login;
- Register;
- Forgot Password;
- Profile;
- Progress;
- Analytics Dashboard;
- Analytics charts.

## 7. Генерація локалізацій

Після додавання або зміни ARB-файлів потрібно виконати:

```bash
cd mobile
flutter gen-l10n
```

Або достатньо:

```bash
flutter pub get
flutter run
```

За наявності `flutter: generate: true` Flutter генерує `AppLocalizations` автоматично під час build/run.

## 8. Як додати новий текст

1. Додати ключ у `app_en.arb`.
2. Додати той самий ключ у `app_uk.arb`.
3. Додати той самий ключ у `app_de.arb`.
4. Виконати `flutter gen-l10n`.
5. Використати `AppLocalizations.of(context).newKey` у Flutter UI.
