class NotificationPreferencesModel {
  const NotificationPreferencesModel({
    required this.workoutRemindersEnabled,
    required this.workoutReminderTime,
    required this.paymentNotificationsEnabled,
    required this.premiumExpirationEnabled,
    required this.premiumExpirationDaysBefore,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      workoutRemindersEnabled:
          json['workout_reminders_enabled'] as bool? ?? true,
      workoutReminderTime:
          json['workout_reminder_time']?.toString() ?? '09:00:00',
      paymentNotificationsEnabled:
          json['payment_notifications_enabled'] as bool? ?? true,
      premiumExpirationEnabled:
          json['premium_expiration_enabled'] as bool? ?? true,
      premiumExpirationDaysBefore:
          json['premium_expiration_days_before'] as int? ?? 3,
    );
  }

  final bool workoutRemindersEnabled;
  final String workoutReminderTime;
  final bool paymentNotificationsEnabled;
  final bool premiumExpirationEnabled;
  final int premiumExpirationDaysBefore;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'workout_reminders_enabled': workoutRemindersEnabled,
      'workout_reminder_time': workoutReminderTime,
      'payment_notifications_enabled': paymentNotificationsEnabled,
      'premium_expiration_enabled': premiumExpirationEnabled,
      'premium_expiration_days_before': premiumExpirationDaysBefore,
    };
  }
}
