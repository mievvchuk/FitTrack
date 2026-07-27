import '../core/network/api_client.dart';

class ApiService {
  const ApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> healthCheck() async {
    await _apiClient.get('/health');
  }
}
