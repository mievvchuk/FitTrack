# FitTrack - UI/UX дизайн мобільного застосунку

## 1. Загальна концепція

FitTrack має виглядати як професійний фітнес-застосунок: темна тема, високий контраст, великі спортивні фото, чіткі метрики, швидкий доступ до тренування і мінімум зайвого тексту. Основна емоція інтерфейсу - контроль, прогрес і енергія.

Дизайн будується навколо трьох принципів:

- швидкий старт тренування з головного екрана;
- зрозуміла візуалізація прогресу;
- спортивна преміальна естетика без перевантаження.

## 2. Візуальний стиль

### Колірна палітра

| Роль | Колір | HEX | Використання |
| --- | --- | --- | --- |
| App background | Graphite Black | `#090B10` | Основний фон застосунку |
| Surface | Carbon | `#11151D` | Картки, bottom sheets, поля |
| Elevated surface | Dark Steel | `#1A202B` | Активні блоки, модальні вікна |
| Primary accent | Electric Lime | `#B6FF3B` | Основні CTA, активні стани, прогрес |
| Secondary accent | Pulse Cyan | `#2EE6FF` | Графіки, інформаційні бейджі |
| Warning accent | Heat Orange | `#FF8A2A` | Помилки техніки, попередження |
| Premium accent | Gold | `#FFD166` | Premium, платежі, тарифи |
| Text primary | Snow | `#F7F8FA` | Основний текст |
| Text secondary | Mist Gray | `#A7AFBE` | Допоміжний текст |
| Text muted | Steel Gray | `#6F7888` | Плейсхолдери, неактивні стани |
| Error | Coral Red | `#FF4D5E` | Помилки форм |

Основний акцент - Electric Lime. Він має бути помітним, але не заливати весь інтерфейс. Cyan використовується для даних і графіків, Gold - тільки для Premium-зони.

### Типографіка

Рекомендований шрифт: `Inter`, `SF Pro Display` або `Roboto`.

| Стиль | Розмір | Weight | Використання |
| --- | --- | --- | --- |
| Display | 32 | 800 | Splash, великі цифри прогресу |
| H1 | 28 | 700 | Заголовки ключових екранів |
| H2 | 22 | 700 | Назви секцій |
| H3 | 18 | 600 | Назви карток |
| Body | 16 | 400 | Основний текст |
| Body small | 14 | 400 | Опис, другорядна інформація |
| Caption | 12 | 500 | Бейджі, підписи, одиниці виміру |

### Форма і простір

- Базовий margin екрана: `20 px`.
- Відступ між секціями: `24 px`.
- Відступ між елементами в картці: `12 px`.
- Радіус карток: `8 px`.
- Радіус кнопок: `8 px`.
- Висота primary button: `52 px`.
- Висота input field: `52 px`.
- Мінімальна зона натискання: `44 x 44 px`.

## 3. Основні Flutter-компоненти

### Layout

- `Scaffold` - базова структура екрана.
- `SafeArea` - захист від notch/status bar.
- `CustomScrollView` + `SliverAppBar` - екрани з великим фото або header.
- `SingleChildScrollView` - форми і профіль.
- `GridView.builder` - бібліотека вправ.
- `ListView.separated` - історія платежів, вправи у тренуванні.
- `PageView` - onboarding або premium highlights.
- `BottomNavigationBar` або Material 3 `NavigationBar` - основна навігація.

### Controls

- `ElevatedButton` - головна дія.
- `OutlinedButton` - вторинна дія.
- `IconButton` - назад, фільтр, налаштування, редагування.
- `TextField` / `TextFormField` - форми входу, профілю, тренування.
- `DropdownButtonFormField` - стать, ціль, рівень складності.
- `FilterChip` - фільтри груп м'язів.
- `SegmentedButton` - період статистики: тиждень, місяць, рік.
- `Switch` - біометрія, сповіщення.
- `Slider` / `Stepper` - підходи, повторення, відпочинок.

### Data display

- `Card` або власний `Container` з `BoxDecoration` - картки метрик.
- `LinearProgressIndicator` - прогрес виконання.
- `CircularProgressIndicator` - денна ціль калорій або активність.
- `fl_chart` `LineChart` - графік ваги.
- `fl_chart` `BarChart` - статистика тренувань.
- `CachedNetworkImage` - фото/GIF вправ.

### Navigation and feedback

- `go_router` - маршрутизація.
- `showModalBottomSheet` - фільтри, вибір вправ, підтвердження дії.
- `SnackBar` - успіх/помилка.
- `AlertDialog` - видалення вправи або тренування.
- `Hero` - плавний перехід фото вправи з картки на детальний екран.

## 4. Навігаційна структура

Основна навігація після входу:

```text
Home
Exercises
Workouts
Progress
Profile
```

Глобальні маршрути:

```text
/splash
/login
/register
/forgot-password
/home
/exercises
/exercises/:id
/workouts
/workouts/create
/workouts/:id/edit
/progress
/profile
/premium
/payments
```

Admin-екрани можуть відкриватися з Profile або Settings, якщо роль користувача `admin`.

## 5. Екрани

## 5.1 Splash Screen

### Розташування елементів

Екран повністю темний. У центрі розміщується логотип FitTrack: стилізована літера `F` або знак пульсу/доріжки. Під логотипом - назва `FitTrack`, нижче короткий слоган `Train. Track. Transform.`.

Внизу екрана показується тонкий lime progress indicator або маленький loader.

### Компоненти Flutter

- `Scaffold`
- `Container` з gradient overlay
- `Column`
- `AnimatedOpacity`
- `TweenAnimationBuilder`
- `LinearProgressIndicator`

### UX логіка

1. Перевірити наявність Firebase session.
2. Якщо користувач авторизований і біометрія увімкнена - перейти на Biometric Unlock.
3. Якщо користувач авторизований без біометрії - перейти на Home.
4. Якщо сесії немає - перейти на Login.

## 5.2 Login / Register

### Розташування елементів

Верхня частина: темне спортивне фото або абстрактний фрагмент тренажерної зали з затемненням. Поверх нього - логотип і короткий заголовок.

Нижня частина: форма на dark surface:

- email;
- password;
- primary button `Увійти` або `Створити акаунт`;
- кнопка Google Sign-In;
- посилання `Забули пароль?`;
- перемикач `Немає акаунта? Зареєструватися`.

### Компоненти Flutter

- `Form`
- `TextFormField`
- `ElevatedButton`
- `OutlinedButton.icon`
- `TextButton`
- `Image`
- `SafeArea`

### UX логіка

- Email/password login виконується через Firebase.
- Google Sign-In відкриває provider flow.
- Після успіху застосунок отримує Firebase ID token і викликає backend `/auth/sync-user`.
- Якщо профіль неповний, користувач переходить на Profile Setup.
- Якщо профіль заповнений, користувач переходить на Home.
- Помилки показуються біля поля і дублюються коротким `SnackBar`.

## 5.3 Home Dashboard

### Розташування елементів

Верх:

- привітання: `Привіт, Іване`;
- avatar справа;
- іконка notification/settings;
- короткий статус дня: `Сьогодні Push Day`.

Основний блок:

- велика картка `Today's Workout`;
- назва тренування;
- кількість вправ;
- очікувана тривалість;
- CTA `Почати`.

Метрики нижче у сітці 2x2:

- поточна вага;
- тренувань цього тижня;
- загальний volume;
- calories today.

Нижче:

- міні-графік прогресу ваги;
- блок `Recent Activity`;
- швидкі дії: `Додати вагу`, `Додати їжу`, `Нове тренування`.

### Компоненти Flutter

- `CustomScrollView`
- `SliverToBoxAdapter`
- `Card`
- `GridView`
- `LinearProgressIndicator`
- `LineChart`
- `FloatingActionButton`

### UX логіка

- CTA `Почати` відкриває Active Workout Session.
- Натискання на вагу відкриває Add Weight Log.
- Натискання на міні-графік відкриває Progress.
- Avatar відкриває Profile.

## 5.4 Exercise Library

### Розташування елементів

Верх:

- заголовок `Exercises`;
- search field;
- горизонтальний ряд `FilterChip`: груди, спина, ноги, плечі, руки, прес.

Контент:

- grid з 2 колонками;
- кожна картка має фото вправи зверху;
- поверх фото - бейдж складності;
- нижче назва, група м'язів, обладнання;
- маленька іконка `+` для швидкого додавання у тренування.

### Компоненти Flutter

- `SearchBar` або `TextField`
- `FilterChip`
- `GridView.builder`
- `CachedNetworkImage`
- `InkWell`
- `Hero`
- `IconButton`

### UX логіка

- Пошук фільтрує список із debounce 300 ms.
- FilterChip може працювати як single-select або multi-select.
- Натискання на картку відкриває Exercise Detail.
- Натискання `+` відкриває bottom sheet з вибором тренування.

## 5.5 Exercise Detail

### Розташування елементів

Верх:

- велике фото/GIF вправи на 40-45% висоти екрана;
- кнопка назад;
- бейдж складності;
- кнопка додати у тренування.

Нижче:

- назва вправи;
- група м'язів;
- обладнання;
- tabs або segmented control:
  - `Опис`;
  - `Техніка`;
  - `Помилки`.

Секція `Опис`:

- коротка мета вправи;
- які м'язи працюють.

Секція `Техніка`:

- нумеровані кроки виконання;
- акцент на дихання, траєкторію і контроль.

Секція `Помилки`:

- список типових помилок;
- помилки позначаються Heat Orange.

### Компоненти Flutter

- `SliverAppBar`
- `FlexibleSpaceBar`
- `Hero`
- `CachedNetworkImage`
- `SegmentedButton`
- `ListTile`
- `Chip`
- `ElevatedButton.icon`

### UX логіка

- GIF автоматично програється без звуку.
- Користувач може додати вправу до тренування з detail screen.
- Після додавання показується bottom sheet з параметрами: підходи, повторення, вага, відпочинок.

## 5.6 Workout Builder

### Розташування елементів

Верх:

- заголовок `Create Workout`;
- поле назви тренування;
- optional description;
- goal dropdown.

Середина:

- список доданих вправ;
- кожна вправа як compact card:
  - назва;
  - категорія;
  - sets x reps;
  - weight;
  - rest;
  - drag handle для зміни порядку.

Низ:

- sticky CTA `Зберегти тренування`;
- secondary button `Додати вправу`.

### Компоненти Flutter

- `Form`
- `TextFormField`
- `DropdownButtonFormField`
- `ReorderableListView`
- `Stepper` або custom counter controls
- `showModalBottomSheet`
- `ElevatedButton`
- `OutlinedButton.icon`

### UX логіка

- `Додати вправу` відкриває Exercise Picker bottom sheet.
- Після вибору вправи відкривається форма параметрів.
- Користувач може редагувати sets, reps, weight, rest прямо у картці.
- Save disabled, поки немає назви і хоча б однієї вправи.
- Після збереження користувач переходить на Workout Detail або Workouts List.

## 5.7 Progress

### Розташування елементів

Верх:

- заголовок `Progress`;
- segmented control: `Week`, `Month`, `Year`.

Основні блоки:

- великий line chart зміни ваги;
- bar chart кількості тренувань;
- картки статистики:
  - total workouts;
  - total volume;
  - average duration;
  - most trained muscle group.

Нижче:

- history list останніх тренувань;
- CTA `Додати вагу`.

### Компоненти Flutter

- `SegmentedButton`
- `LineChart`
- `BarChart`
- `Card`
- `ListView.separated`
- `FloatingActionButton.extended`

### UX логіка

- Зміна періоду оновлює графіки без повного reload.
- Натискання на точку графіка показує tooltip з датою і вагою.
- Натискання на тренування в історії відкриває Workout Session Details.

## 5.8 Profile

### Розташування елементів

Верх:

- avatar;
- ім'я;
- email;
- premium/free badge.

Профільні дані:

- вік;
- стать;
- зріст;
- вага;
- ціль тренувань.

Налаштування:

- biometric unlock switch;
- change password;
- premium subscription;
- payment history;
- logout.

Для admin:

- додатковий блок `Admin Panel`;
- `Manage Exercises`;
- `Users`.

### Компоненти Flutter

- `CircleAvatar`
- `ListTile`
- `SwitchListTile`
- `Card`
- `OutlinedButton`
- `TextButton`

### UX логіка

- `Edit Profile` відкриває форму CRUD профілю.
- Biometric switch просить системне підтвердження через `local_auth`.
- `Change Password` відкриває Firebase password update flow.
- `Logout` очищує локальний стан і повертає на Login.

## 5.9 Premium Subscription

### Розташування елементів

Верх:

- premium hero block з Gold accent;
- заголовок `Unlock Premium`;
- короткий підзаголовок про розширену статистику і необмежені тренування.

Плани:

- Free card;
- Premium card;
- Premium card має gold border і бейдж `Best value`.

Feature comparison:

- unlimited workouts;
- advanced charts;
- full workout history;
- premium exercise library.

Низ:

- CTA `Перейти на Premium`;
- текст про test payment mode.

### Компоненти Flutter

- `PageView` або `Column`
- `Card`
- `ListTile`
- `CheckboxListTile` в readonly style або custom feature row
- `ElevatedButton`
- `AnimatedContainer`

### UX логіка

- Користувач обирає Premium plan.
- App викликає backend `/subscription/checkout-session`.
- Backend повертає Stripe Checkout URL або PaymentSheet config.
- Після успішної оплати користувач повертається на `payment-success`.
- Status subscription оновлюється після webhook або refresh endpoint.

## 5.10 Payment History

### Розташування елементів

Верх:

- заголовок `Payment History`;
- поточний статус підписки;
- дата наступного списання або дата завершення.

Контент:

- список платежів;
- кожен item:
  - дата;
  - сума;
  - статус;
  - plan name;
  - payment method або Stripe reference.

Empty state:

- іконка receipt;
- текст `Платежів ще немає`;
- кнопка `Переглянути Premium`.

### Компоненти Flutter

- `ListView.separated`
- `ListTile`
- `Chip`
- `Card`
- `RefreshIndicator`
- `OutlinedButton`

### UX логіка

- Pull-to-refresh оновлює історію.
- Натискання на item відкриває payment details bottom sheet.
- Failed payment має Coral Red status chip.
- Succeeded payment має Electric Lime status chip.

## 6. UX логіка основних переходів

```text
Splash
  -> Login
  -> Biometric Unlock
  -> Home

Login/Register
  -> Profile Setup, якщо профіль неповний
  -> Home, якщо профіль готовий

Home
  -> Active Workout Session
  -> Progress
  -> Add Weight Log
  -> Nutrition Entry
  -> Profile

Exercise Library
  -> Exercise Detail
  -> Add To Workout bottom sheet

Exercise Detail
  -> Add Exercise Parameters bottom sheet
  -> Workout Builder

Workout Builder
  -> Exercise Picker
  -> Save Workout
  -> Workout Detail / Workouts List

Progress
  -> Workout Session Detail
  -> Add Weight Log

Profile
  -> Edit Profile
  -> Premium Subscription
  -> Payment History
  -> Change Password
  -> Admin Panel, якщо role = admin

Premium Subscription
  -> Stripe Checkout
  -> Payment Success / Payment Cancel
  -> Payment History
```

## 7. Стан екранів

Кожен основний екран має підтримувати:

- loading state;
- empty state;
- error state;
- success state після дії;
- offline або retry state для API-помилок.

Приклади:

- Exercise Library empty state: `Вправ за цим фільтром не знайдено`.
- Workout Builder validation: `Додайте хоча б одну вправу`.
- Progress empty state: `Додайте перший запис ваги, щоб побачити графік`.
- Payment History empty state: `Платежів ще немає`.

## 8. Мікровзаємодії

- Primary button має легку scale-анімацію при натисканні.
- Картки вправ мають subtle hover/pressed overlay.
- Графіки анімовано промальовуються при першому відкритті.
- Після завершення тренування показується summary з анімованими метриками.
- Додавання вправи до тренування підтверджується bottom sheet.
- Premium card має слабке gold glow, але без надмірного блиску.

## 9. Адаптивність

### Малий телефон

- grid вправ може перейти з 2 колонок у компактніші картки;
- метрики Home залишаються 2x2;
- CTA на Workout Builder фіксується внизу.

### Великий телефон

- більше простору між секціями;
- фото Exercise Detail може займати до 45% висоти;
- charts отримують більшу висоту.

### Планшет

- Home може мати двоколонковий layout;
- Exercise Library може мати 3-4 колонки;
- Profile і Progress можуть показувати content у master-detail стилі.

## 10. Дизайн Flutter ThemeData

```dart
final fitTrackTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF090B10),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFB6FF3B),
    secondary: Color(0xFF2EE6FF),
    tertiary: Color(0xFFFFD166),
    surface: Color(0xFF11151D),
    error: Color(0xFFFF4D5E),
    onPrimary: Color(0xFF090B10),
    onSurface: Color(0xFFF7F8FA),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF11151D),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
);
```

## 11. Дизайн-система компонентів

### Primary Button

- фон: `#B6FF3B`;
- текст: `#090B10`;
- height: `52 px`;
- radius: `8 px`;
- disabled: `#2A303A` фон, `#6F7888` текст.

### Metric Card

- фон: `#11151D`;
- radius: `8 px`;
- padding: `16 px`;
- label зверху;
- велике значення;
- маленький trend indicator.

### Exercise Card

- aspect ratio: `0.78`;
- фото займає 60%;
- назва і metadata внизу;
- difficulty chip поверх фото;
- quick add icon справа внизу.

### Workout Exercise Row

- drag handle зліва;
- назва вправи;
- компактні параметри `4 x 10`, `60 kg`, `90 sec`;
- edit icon справа.

### Status Chip

- succeeded: lime;
- failed: coral;
- pending: cyan;
- premium: gold.

## 12. UX для курсового захисту

Для демонстрації на захисті найкраще показати такий сценарій:

1. Splash -> Login.
2. Login через Google або email.
3. Home Dashboard з today's workout.
4. Exercise Library з фільтрами.
5. Exercise Detail з технікою і помилками.
6. Workout Builder: створити тренування і додати вправи.
7. Progress: показати графік ваги і статистику.
8. Profile: змінити дані профілю.
9. Premium: перейти до тестової оплати Stripe.
10. Payment History: показати успішний тестовий платіж.

Цей сценарій покриває авторизацію, персоналізацію, бібліотеку вправ, тренування, прогрес, підписку і оплату.
