class MatchMemberModel {
  final String matchMemberId; // Prefix: MM_
  final String matchPostId;
  final String userId;
  final bool isPaid;
  final DateTime joinedAt;

  MatchMemberModel({
    required this.matchMemberId,
    required this.matchPostId,
    required this.userId,
    required this.isPaid,
    required this.joinedAt,
  });

  // Chuyển từ Firestore JSON sang Object Flutter
  factory MatchMemberModel.fromFirestore(Map<String, dynamic> json, String id) {
    return MatchMemberModel(
      matchMemberId: id,
      matchPostId: json['match_post_id'] ?? '',
      userId: json['user_id'] ?? '',
      isPaid: json['is_paid'] ?? false,
      joinedAt: (json['joined_at'] != null)
          ? json['joined_at'].toDate()
          : DateTime.now(),
    );
  }

  // --- HÀM NÀY GIÚP HẾT LỖI Ở REPOSITORY ---
  Map<String, dynamic> toFirestore() {
    return {
      'match_post_id': matchPostId,
      'user_id': userId,
      'is_paid': isPaid,
      'joined_at': joinedAt, // Firestore sẽ tự chuyển thành Timestamp
    };
  }
}
