class AIFitnessPlanModel {
  const AIFitnessPlanModel({
    required this.id,
    required this.userId,
    required this.goal,
    required this.weightKg,
    required this.heightCm,
    required this.fitnessLevel,
    required this.summary,
    required this.workoutPlan,
    required this.nutritionRecommendations,
    required this.safetyNotes,
    required this.model,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String goal;
  final double weightKg;
  final double heightCm;
  final String fitnessLevel;
  final String summary;
  final AIWorkoutPlanModel workoutPlan;
  final AINutritionRecommendationsModel nutritionRecommendations;
  final List<String> safetyNotes;
  final String model;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AIFitnessPlanModel.fromJson(Map<String, dynamic> json) {
    return AIFitnessPlanModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goal: json['goal'] as String,
      weightKg: _toDouble(json['weight_kg']),
      heightCm: _toDouble(json['height_cm']),
      fitnessLevel: json['fitness_level'] as String,
      summary: json['summary'] as String? ?? '',
      workoutPlan: AIWorkoutPlanModel.fromJson(
        json['workout_plan'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      nutritionRecommendations: AINutritionRecommendationsModel.fromJson(
        json['nutrition_recommendations'] as Map<String, dynamic>? ??
            <String, dynamic>{},
      ),
      safetyNotes: (json['safety_notes'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      model: json['model'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class AIWorkoutPlanModel {
  const AIWorkoutPlanModel({
    required this.weeklySchedule,
    required this.progression,
  });

  final List<AIWorkoutDayModel> weeklySchedule;
  final List<String> progression;

  factory AIWorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    return AIWorkoutPlanModel(
      weeklySchedule:
          (json['weekly_schedule'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(AIWorkoutDayModel.fromJson)
              .toList(growable: false),
      progression: (json['progression'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}

class AIWorkoutDayModel {
  const AIWorkoutDayModel({
    required this.day,
    required this.focus,
    required this.durationMinutes,
    required this.warmUp,
    required this.exercises,
    required this.cooldown,
  });

  final int day;
  final String focus;
  final int durationMinutes;
  final List<String> warmUp;
  final List<AIExerciseRecommendationModel> exercises;
  final List<String> cooldown;

  factory AIWorkoutDayModel.fromJson(Map<String, dynamic> json) {
    return AIWorkoutDayModel(
      day: _toInt(json['day']),
      focus: json['focus'] as String? ?? '',
      durationMinutes: _toInt(json['duration_minutes']),
      warmUp: (json['warm_up'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      exercises: (json['exercises'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AIExerciseRecommendationModel.fromJson)
          .toList(growable: false),
      cooldown: (json['cooldown'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}

class AIExerciseRecommendationModel {
  const AIExerciseRecommendationModel({
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.techniqueTip,
  });

  final String name;
  final String muscleGroup;
  final String equipment;
  final int sets;
  final String reps;
  final int restSeconds;
  final String techniqueTip;

  factory AIExerciseRecommendationModel.fromJson(Map<String, dynamic> json) {
    return AIExerciseRecommendationModel(
      name: json['name'] as String? ?? '',
      muscleGroup: json['muscle_group'] as String? ?? '',
      equipment: json['equipment'] as String? ?? '',
      sets: _toInt(json['sets']),
      reps: json['reps']?.toString() ?? '',
      restSeconds: _toInt(json['rest_seconds']),
      techniqueTip: json['technique_tip'] as String? ?? '',
    );
  }
}

class AINutritionRecommendationsModel {
  const AINutritionRecommendationsModel({
    required this.caloriesPerDay,
    required this.proteinG,
    required this.fatsG,
    required this.carbsG,
    required this.mealsPerDay,
    required this.hydrationLiters,
    required this.recommendations,
  });

  final int caloriesPerDay;
  final int proteinG;
  final int fatsG;
  final int carbsG;
  final int mealsPerDay;
  final double hydrationLiters;
  final List<String> recommendations;

  factory AINutritionRecommendationsModel.fromJson(Map<String, dynamic> json) {
    return AINutritionRecommendationsModel(
      caloriesPerDay: _toInt(json['calories_per_day']),
      proteinG: _toInt(json['protein_g']),
      fatsG: _toInt(json['fats_g']),
      carbsG: _toInt(json['carbs_g']),
      mealsPerDay: _toInt(json['meals_per_day']),
      hydrationLiters: _toDouble(json['hydration_liters']),
      recommendations:
          (json['recommendations'] as List<dynamic>? ?? <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false),
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
