class UserActivityLogModel {
  final String activityLogId; // Prefix: LOG_
  final String userId;
  final String actionType; // view_court, book_court, join_match
  final String targetId;
  final DateTime createdAt;

  UserActivityLogModel({
    required this.activityLogId,
    required this.userId,
    required this.actionType,
    required this.targetId,
    required this.createdAt,
  });

  factory UserActivityLogModel.fromFirestore(
    Map<String, dynamic> json,
    String id,
  ) {
    return UserActivityLogModel(
      activityLogId: id,
      userId: json['user_id'] ?? '',
      actionType: json['action_type'] ?? 'view_court',
      targetId: json['target_id'] ?? '',
      createdAt: (json['created_at'] != null)
          ? json['created_at'].toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'action_type': actionType,
      'target_id': targetId,
      'created_at': createdAt,
    };
  }
}
