class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.code,
    required this.name,
    required this.priceCents,
    required this.currency,
    required this.features,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      priceCents: json['price_cents'] as int? ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      features: (json['features'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }

  final String code;
  final String name;
  final int priceCents;
  final String currency;
  final List<String> features;

  String get priceLabel {
    if (priceCents == 0) {
      return 'Free';
    }

    return '${currency.toUpperCase()} ${(priceCents / 100).toStringAsFixed(2)}';
  }
}
