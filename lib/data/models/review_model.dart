import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String fromUserId; // ID người đánh giá
  final String? toUserId; // Chỉ dùng cho đánh giá người chơi (RVU)
  final String? courtId; // Chỉ dùng cho đánh giá sân (RVC)
  final String? subCourtId; // Chỉ dùng cho đánh giá sân (RVC)
  final String? bookingId; // Lưu lại ID trận đấu để tracking nút 'Hoàn thành'
  final int ratingScore;
  final String comment;
  final DateTime createdAt;
  
  // Dữ liệu UI (lấy thêm thủ công)
  String fromUserName;
  String? fromUserAvatar;

  ReviewModel({
    required this.reviewId,
    required this.fromUserId,
    this.toUserId,
    this.courtId,
    this.subCourtId,
    this.bookingId,
    required this.ratingScore,
    required this.comment,
    required this.createdAt,
    this.fromUserName = 'Người dùng',
    this.fromUserAvatar,
  });

  factory ReviewModel.fromSnapshot(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>?;
    if (json == null) throw Exception("Document is empty");

    return ReviewModel(
      reviewId: doc.id,
      fromUserId: json['from_user_id'] ?? '',
      toUserId: json['to_user_id'],
      courtId: json['court_id'],
      subCourtId: json['sub_court_id'],
      bookingId: json['booking_id'],
      ratingScore: json['rating_score'] ?? 5,
      comment: json['comment'] ?? '',
      createdAt: (json['created_at'] is Timestamp)
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      fromUserName: json['from_user_name'] ?? 'Người dùng',
      fromUserAvatar: json['from_user_avatar'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'from_user_id': fromUserId,
      if (toUserId != null) 'to_user_id': toUserId,
      if (courtId != null) 'court_id': courtId,
      if (subCourtId != null) 'sub_court_id': subCourtId,
      if (bookingId != null) 'booking_id': bookingId,
      'rating_score': ratingScore,
      'comment': comment,
      'created_at': createdAt,
      'from_user_name': fromUserName,
      if (fromUserAvatar != null) 'from_user_avatar': fromUserAvatar,
    };
  }
}