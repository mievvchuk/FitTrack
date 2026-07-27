import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/models/app_notification_model.dart';
import '../../data/models/notification_preferences_model.dart';
import '../../data/services/fcm_notification_service.dart';

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final fcmNotificationServiceProvider = Provider<FcmNotificationService>((ref) {
  final service = FcmNotificationService(
    messaging: ref.watch(firebaseMessagingProvider),
    apiClient: ref.watch(apiClientProvider),
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final appNotificationsProvider =
    FutureProvider<List<AppNotificationModel>>((ref) {
  return ref.watch(fcmNotificationServiceProvider).getNotifications();
});

final notificationPreferencesProvider =
    FutureProvider<NotificationPreferencesModel>((ref) {
  return ref.watch(fcmNotificationServiceProvider).getPreferences();
});
