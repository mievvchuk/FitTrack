import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/models/ai_fitness_plan_model.dart';
import '../../data/services/ai_assistant_api_service.dart';

final aiAssistantApiServiceProvider = Provider<AIAssistantApiService>((ref) {
  return AIAssistantApiService(ref.watch(apiClientProvider));
});

final aiFitnessPlanHistoryProvider =
    FutureProvider<List<AIFitnessPlanModel>>((ref) {
  return ref.watch(aiAssistantApiServiceProvider).getPlans();
});
