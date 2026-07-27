class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.status,
    required this.createdAt,
    this.fcmMessageId,
    this.errorMessage,
    this.sentAt,
    this.readAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: data is Map<String, dynamic>
          ? data.map((key, value) => MapEntry(key, value.toString()))
          : const <String, String>{},
      status: json['status']?.toString() ?? 'queued',
      fcmMessageId: json['fcm_message_id']?.toString(),
      errorMessage: json['error_message']?.toString(),
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? ''),
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, String> data;
  final String status;
  final String? fcmMessageId;
  final String? errorMessage;
  final DateTime? sentAt;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;
}
