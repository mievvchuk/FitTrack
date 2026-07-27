class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.plan,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.provider,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionId,
    this.stripePaymentIntentId,
    this.stripeCheckoutSessionId,
    this.stripeCheckoutUrl,
    this.description,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      subscriptionId: json['subscription_id']?.toString(),
      plan: json['plan']?.toString() ?? 'premium',
      amountCents: json['amount_cents'] as int? ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? 'pending',
      provider: json['provider']?.toString() ?? 'stripe',
      mode: json['mode']?.toString() ?? 'test',
      stripePaymentIntentId: json['stripe_payment_intent_id']?.toString(),
      stripeCheckoutSessionId: json['stripe_checkout_session_id']?.toString(),
      stripeCheckoutUrl: json['stripe_checkout_url']?.toString(),
      description: json['description']?.toString(),
      paidAt: DateTime.tryParse(json['paid_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String? subscriptionId;
  final String plan;
  final int amountCents;
  final String currency;
  final String status;
  final String provider;
  final String mode;
  final String? stripePaymentIntentId;
  final String? stripeCheckoutSessionId;
  final String? stripeCheckoutUrl;
  final String? description;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get amountLabel {
    return '${currency.toUpperCase()} ${(amountCents / 100).toStringAsFixed(2)}';
  }
}
