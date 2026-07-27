class PaymentHistoryModel {
  const PaymentHistoryModel({
    required this.id,
    required this.paymentId,
    required this.newStatus,
    required this.eventType,
    required this.provider,
    required this.mode,
    required this.createdAt,
    this.oldStatus,
    this.stripeEventId,
    this.message,
  });

  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      id: json['id']?.toString() ?? '',
      paymentId: json['payment_id']?.toString() ?? '',
      oldStatus: json['old_status']?.toString(),
      newStatus: json['new_status']?.toString() ?? 'pending',
      eventType: json['event_type']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'stripe',
      mode: json['mode']?.toString() ?? 'test',
      stripeEventId: json['stripe_event_id']?.toString(),
      message: json['message']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String paymentId;
  final String? oldStatus;
  final String newStatus;
  final String eventType;
  final String provider;
  final String mode;
  final String? stripeEventId;
  final String? message;
  final DateTime createdAt;
}
