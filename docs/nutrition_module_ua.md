# FitTrack - Nutrition Module

## Мета

Nutrition module відповідає за щоденний облік харчування користувача та допомагає оцінювати баланс калорій і макронутрієнтів разом із тренувальним прогресом.

## Основні можливості

- додавання прийомів їжі;
- фіксація калорій;
- фіксація білків, жирів і вуглеводів;
- перегляд харчової історії за датами;
- використання nutrition data в analytics dashboard;
- майбутнє розширення для AI Fitness Assistant.

## Database

Основна таблиця:

```text
meals
```

Ключові поля:

- `id`;
- `user_id`;
- `meal_date`;
- `meal_type`;
- `name`;
- `calories`;
- `protein_g`;
- `fat_g`;
- `carbs_g`;
- `created_at`;
- `updated_at`.

## API

Рекомендовані endpoints:

```http
GET /api/v1/meals
POST /api/v1/meals
PUT /api/v1/meals/{meal_id}
DELETE /api/v1/meals/{meal_id}
```

## Flutter

Рекомендована структура:

```text
mobile/lib/features/nutrition/
  data/
  domain/
  presentation/
```

У поточній версії nutrition дані вже враховуються в analytics module через calorie chart і summary metrics.
