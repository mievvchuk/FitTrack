class AnalyticsDashboardModel {
  const AnalyticsDashboardModel({
    required this.period,
    required this.summary,
    required this.weightChart,
    required this.workoutActivityChart,
    required this.volumeChart,
    required this.calorieChart,
    required this.activity,
  });

  final AnalyticsPeriodModel period;
  final AnalyticsSummaryModel summary;
  final List<AnalyticsPointModel> weightChart;
  final List<AnalyticsPointModel> workoutActivityChart;
  final List<AnalyticsPointModel> volumeChart;
  final List<AnalyticsCaloriesPointModel> calorieChart;
  final List<AnalyticsActivityPointModel> activity;

  factory AnalyticsDashboardModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsDashboardModel(
      period: AnalyticsPeriodModel.fromJson(
        json['period'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      summary: AnalyticsSummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      weightChart: (json['weight_chart'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsPointModel.fromJson)
          .toList(growable: false),
      workoutActivityChart:
          (json['workout_activity_chart'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(AnalyticsPointModel.fromJson)
              .toList(growable: false),
      volumeChart: (json['volume_chart'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsPointModel.fromJson)
          .toList(growable: false),
      calorieChart: (json['calorie_chart'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsCaloriesPointModel.fromJson)
          .toList(growable: false),
      activity: (json['activity'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsActivityPointModel.fromJson)
          .toList(growable: false),
    );
  }
}

class AnalyticsPeriodModel {
  const AnalyticsPeriodModel({
    required this.fromDate,
    required this.toDate,
    required this.days,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final int days;

  factory AnalyticsPeriodModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsPeriodModel(
      fromDate: DateTime.parse(json['from_date'] as String),
      toDate: DateTime.parse(json['to_date'] as String),
      days: _toInt(json['days']),
    );
  }
}

class AnalyticsSummaryModel {
  const AnalyticsSummaryModel({
    required this.workoutCount,
    required this.completedWorkoutCount,
    required this.activeDays,
    required this.averageWeightKg,
    required this.latestWeightKg,
    required this.weightChangeKg,
    required this.progressPercent,
    required this.totalVolumeKg,
    required this.caloriesBurned,
    required this.caloriesConsumed,
    required this.averageDailyCalories,
    required this.activityScore,
  });

  final int workoutCount;
  final int completedWorkoutCount;
  final int activeDays;
  final double? averageWeightKg;
  final double? latestWeightKg;
  final double? weightChangeKg;
  final double? progressPercent;
  final double totalVolumeKg;
  final int caloriesBurned;
  final int caloriesConsumed;
  final int averageDailyCalories;
  final int activityScore;

  String get averageWeightLabel {
    final value = averageWeightKg;
    return value == null ? '--' : '${value.toStringAsFixed(1)} kg';
  }

  String get weightChangeLabel {
    final value = weightChangeKg;
    if (value == null) {
      return '--';
    }
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)} kg';
  }

  String get progressLabel {
    final value = progressPercent;
    if (value == null) {
      return '--';
    }
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }

  factory AnalyticsSummaryModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummaryModel(
      workoutCount: _toInt(json['workout_count']),
      completedWorkoutCount: _toInt(json['completed_workout_count']),
      activeDays: _toInt(json['active_days']),
      averageWeightKg: _toNullableDouble(json['average_weight_kg']),
      latestWeightKg: _toNullableDouble(json['latest_weight_kg']),
      weightChangeKg: _toNullableDouble(json['weight_change_kg']),
      progressPercent: _toNullableDouble(json['progress_percent']),
      totalVolumeKg: _toDouble(json['total_volume_kg']),
      caloriesBurned: _toInt(json['calories_burned']),
      caloriesConsumed: _toInt(json['calories_consumed']),
      averageDailyCalories: _toInt(json['average_daily_calories']),
      activityScore: _toInt(json['activity_score']),
    );
  }
}

class AnalyticsPointModel {
  const AnalyticsPointModel({
    required this.date,
    required this.value,
  });

  final DateTime date;
  final double value;

  factory AnalyticsPointModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsPointModel(
      date: DateTime.parse(json['date'] as String),
      value: _toDouble(json['value']),
    );
  }
}

class AnalyticsCaloriesPointModel {
  const AnalyticsCaloriesPointModel({
    required this.date,
    required this.consumed,
    required this.burned,
  });

  final DateTime date;
  final int consumed;
  final int burned;

  factory AnalyticsCaloriesPointModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsCaloriesPointModel(
      date: DateTime.parse(json['date'] as String),
      consumed: _toInt(json['consumed']),
      burned: _toInt(json['burned']),
    );
  }
}

class AnalyticsActivityPointModel {
  const AnalyticsActivityPointModel({
    required this.date,
    required this.workoutsCount,
    required this.caloriesBurned,
    required this.caloriesConsumed,
    required this.totalVolumeKg,
  });

  final DateTime date;
  final int workoutsCount;
  final int caloriesBurned;
  final int caloriesConsumed;
  final double totalVolumeKg;

  bool get isActive {
    return workoutsCount > 0 || caloriesBurned > 0 || caloriesConsumed > 0;
  }

  factory AnalyticsActivityPointModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsActivityPointModel(
      date: DateTime.parse(json['date'] as String),
      workoutsCount: _toInt(json['workouts_count']),
      caloriesBurned: _toInt(json['calories_burned']),
      caloriesConsumed: _toInt(json['calories_consumed']),
      totalVolumeKg: _toDouble(json['total_volume_kg']),
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _toNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  return _toDouble(value);
}

int _toInt(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
