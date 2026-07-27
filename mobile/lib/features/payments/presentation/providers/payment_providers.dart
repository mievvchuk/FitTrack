import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/services/payment_api_service.dart';

final paymentApiServiceProvider = Provider<PaymentApiService>((ref) {
  return PaymentApiService(ref.watch(apiClientProvider));
});

final subscriptionPlansProvider =
    FutureProvider<List<SubscriptionPlanModel>>((ref) {
  return ref.watch(paymentApiServiceProvider).getPlans();
});

final currentSubscriptionProvider = FutureProvider<SubscriptionModel>((ref) {
  return ref.watch(paymentApiServiceProvider).getSubscription();
});

final paymentHistoryProvider = FutureProvider<List<PaymentModel>>((ref) {
  return ref.watch(paymentApiServiceProvider).getPayments();
});

final paymentStatusProvider = FutureProvider.family<PaymentModel, String>((
  ref,
  paymentId,
) {
  return ref.watch(paymentApiServiceProvider).getPayment(paymentId);
});
