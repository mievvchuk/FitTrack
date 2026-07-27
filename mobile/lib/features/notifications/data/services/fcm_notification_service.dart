import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../models/app_notification_model.dart';
import '../models/notification_preferences_model.dart';

class FcmNotificationService {
  FcmNotificationService({
    required FirebaseMessaging messaging,
    required ApiClient apiClient,
  })  : _messaging = messaging,
        _apiClient = apiClient;

  final FirebaseMessaging _messaging;
  final ApiClient _apiClient;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp;

  Future<void> initialize({String? deviceId, String? appVersion}) async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await registerCurrentDeviceToken(
      deviceId: deviceId,
      appVersion: appVersion,
    );
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      registerDeviceToken(
        token,
        deviceId: deviceId,
        appVersion: appVersion,
      );
    });
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> registerCurrentDeviceToken({
    String? deviceId,
    String? appVersion,
  }) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await registerDeviceToken(
      token,
      deviceId: deviceId,
      appVersion: appVersion,
    );
  }

  Future<void> registerDeviceToken(
    String token, {
    String? deviceId,
    String? appVersion,
  }) async {
    await _apiClient.post(
      '/notifications/device-tokens',
      data: <String, dynamic>{
        'fcm_token': token,
        'platform': _platform,
        'device_id': deviceId,
        'app_version': appVersion,
      },
    );
  }

  Future<List<AppNotificationModel>> getNotifications() async {
    final response = await _apiClient.get('/notifications');
    final data = response.data as List<dynamic>? ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AppNotificationModel.fromJson)
        .toList(growable: false);
  }

  Future<AppNotificationModel> markAsRead(String notificationId) async {
    final response = await _apiClient.patch(
      '/notifications/$notificationId/read',
    );
    return AppNotificationModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<NotificationPreferencesModel> getPreferences() async {
    final response = await _apiClient.get('/notifications/preferences');
    return NotificationPreferencesModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferencesModel preferences,
  ) async {
    final response = await _apiClient.put(
      '/notifications/preferences',
      data: preferences.toJson(),
    );
    return NotificationPreferencesModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  String get _platform {
    if (kIsWeb) {
      return 'web';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'android',
    };
  }
}
