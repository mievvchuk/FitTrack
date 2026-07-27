class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.plan,
    required this.status,
    required this.priceCents,
    required this.currency,
    required this.startedAt,
    this.expiresAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id']?.toString() ?? '',
      plan: json['plan']?.toString() ?? 'free',
      status: json['status']?.toString() ?? 'active',
      priceCents: json['price_cents'] as int? ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }

  final String id;
  final String plan;
  final String status;
  final int priceCents;
  final String currency;
  final DateTime startedAt;
  final DateTime? expiresAt;

  bool get isPremium => plan == 'premium' && status == 'active';
}
