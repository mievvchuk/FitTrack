import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/models/analytics_dashboard_model.dart';
import '../../data/services/analytics_api_service.dart';

final analyticsApiServiceProvider = Provider<AnalyticsApiService>((ref) {
  return AnalyticsApiService(ref.watch(apiClientProvider));
});

final analyticsDashboardProvider =
    FutureProvider.family<AnalyticsDashboardModel, int>((ref, days) {
  return ref.watch(analyticsApiServiceProvider).getDashboard(days: days);
});
