class CheckoutSessionModel {
  const CheckoutSessionModel({
    required this.paymentId,
    required this.stripeCheckoutSessionId,
    required this.checkoutUrl,
    required this.status,
    required this.amountCents,
    required this.currency,
  });

  factory CheckoutSessionModel.fromJson(Map<String, dynamic> json) {
    return CheckoutSessionModel(
      paymentId: json['payment_id']?.toString() ?? '',
      stripeCheckoutSessionId:
          json['stripe_checkout_session_id']?.toString() ?? '',
      checkoutUrl: json['checkout_url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      amountCents: json['amount_cents'] as int? ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
    );
  }

  final String paymentId;
  final String stripeCheckoutSessionId;
  final String checkoutUrl;
  final String status;
  final int amountCents;
  final String currency;
}
