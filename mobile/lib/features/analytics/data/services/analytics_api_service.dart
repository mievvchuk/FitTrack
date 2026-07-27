import '../../../../core/network/api_client.dart';
import '../models/analytics_dashboard_model.dart';

class AnalyticsApiService {
  const AnalyticsApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<AnalyticsDashboardModel> getDashboard({int days = 30}) async {
    final response = await _apiClient.get(
      '/analytics/dashboard',
      queryParameters: <String, dynamic>{'days': days},
    );
    return AnalyticsDashboardModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
