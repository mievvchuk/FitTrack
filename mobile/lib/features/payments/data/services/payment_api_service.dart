import '../../../../core/network/api_client.dart';
import '../models/checkout_session_model.dart';
import '../models/payment_history_model.dart';
import '../models/payment_model.dart';
import '../models/subscription_model.dart';
import '../models/subscription_plan_model.dart';

class PaymentApiService {
  const PaymentApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<SubscriptionPlanModel>> getPlans() async {
    final response = await _apiClient.get('/subscription/plans');
    final data = response.data as List<dynamic>? ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionPlanModel.fromJson)
        .toList(growable: false);
  }

  Future<SubscriptionModel> getSubscription() async {
    final response = await _apiClient.get('/subscription/me');
    return SubscriptionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CheckoutSessionModel> createCheckoutSession() async {
    final response = await _apiClient.post(
      '/subscription/checkout-session',
      data: <String, dynamic>{
        'success_url': 'fittrack://payment-success',
        'cancel_url': 'fittrack://payment-cancel',
      },
    );
    return CheckoutSessionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<PaymentModel> confirmTestPayment(String paymentId) async {
    final response = await _apiClient.post(
      '/subscription/payments/$paymentId/confirm-test',
    );
    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PaymentModel>> getPayments() async {
    final response = await _apiClient.get('/subscription/payments');
    final data = response.data as List<dynamic>? ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PaymentModel.fromJson)
        .toList(growable: false);
  }

  Future<PaymentModel> getPayment(String paymentId) async {
    final response = await _apiClient.get('/subscription/payments/$paymentId');
    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PaymentHistoryModel>> getPaymentHistory(String paymentId) async {
    final response = await _apiClient.get(
      '/subscription/payments/$paymentId/history',
    );
    final data = response.data as List<dynamic>? ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PaymentHistoryModel.fromJson)
        .toList(growable: false);
  }
}
