import '../../../../core/network/api_client.dart';
import '../models/ai_fitness_plan_model.dart';

class AIAssistantApiService {
  const AIAssistantApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<AIFitnessPlanModel> generatePlan({
    required String goal,
    required double weightKg,
    required double heightCm,
    required String fitnessLevel,
  }) async {
    final response = await _apiClient.post(
      '/ai-assistant/plans',
      data: <String, dynamic>{
        'goal': goal,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'fitness_level': fitnessLevel,
      },
    );
    return AIFitnessPlanModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<AIFitnessPlanModel>> getPlans({int limit = 20}) async {
    final response = await _apiClient.get(
      '/ai-assistant/plans',
      queryParameters: <String, dynamic>{'limit': limit},
    );
    final data = response.data as List<dynamic>? ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AIFitnessPlanModel.fromJson)
        .toList(growable: false);
  }
}
