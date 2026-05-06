import 'package:cloud_firestore/cloud_firestore.dart';

class UserReviewModel {
  final String reviewId;
  final String fromUserId;
  final String toUserId;
  final String courtId;
  final String subCourtId;
  final int ratingScore;
  final String comment;
  final DateTime createdAt;

  UserReviewModel({
    required this.reviewId,
    required this.fromUserId,
    required this.toUserId,
    required this.courtId,
    required this.subCourtId,
    required this.ratingScore,
    required this.comment,
    required this.createdAt,
  });

  factory UserReviewModel.fromSnapshot(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;

    return UserReviewModel(
      reviewId: doc.id,
      fromUserId: json['from_user_id'] ?? '',
      toUserId: json['to_user_id'] ?? '',
      courtId: json['court_id'] ?? '',
      subCourtId: json['sub_court_id'] ?? '',
      ratingScore: json['rating_score'] ?? 5,
      comment: json['comment'] ?? '',
      createdAt: (json['created_at'] is Timestamp)
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'court_id': courtId,
      'sub_court_id': subCourtId,
      'rating_score': ratingScore,
      'comment': comment,
      'created_at': createdAt,
    };
  }
}