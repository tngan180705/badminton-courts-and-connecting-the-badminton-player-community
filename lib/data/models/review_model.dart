class UserReviewModel {
  final String reviewId; // Prefix: RVU_
  final String fromUserId;
  final String toUserId;
  final int ratingScore;
  final String comment;
  final DateTime createdAt;

  UserReviewModel({
    required this.reviewId,
    required this.fromUserId,
    required this.toUserId,
    required this.ratingScore,
    required this.comment,
    required this.createdAt,
  });

  // Chuyển từ Firestore JSON sang Object Flutter
  factory UserReviewModel.fromFirestore(Map<String, dynamic> json, String id) {
    return UserReviewModel(
      reviewId: id,
      fromUserId: json['from_user_id'] ?? '',
      toUserId: json['to_user_id'] ?? '',
      ratingScore: json['rating_score'] ?? 5,
      comment: json['comment'] ?? '',
      createdAt: (json['created_at'] != null)
          ? json['created_at'].toDate()
          : DateTime.now(),
    );
  }

  // --- HÀM NÀY GIÚP HẾT LỖI Ở REPOSITORY ---
  Map<String, dynamic> toFirestore() {
    return {
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'rating_score': ratingScore,
      'comment': comment,
      'created_at': createdAt,
    };
  }
}
