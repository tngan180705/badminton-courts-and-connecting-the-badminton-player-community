class NotificationModel {
  final String notificationId; // Prefix: NT_
  final String userId;
  final String title;
  final String body;
  final String type; // transaction, social, ai_suggest
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(
    Map<String, dynamic> json,
    String id,
  ) {
    return NotificationModel(
      notificationId: id,
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'social',
      isRead: json['is_read'] ?? false,
      createdAt: (json['created_at'] != null)
          ? json['created_at'].toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }
}
