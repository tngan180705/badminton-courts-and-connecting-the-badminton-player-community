import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Gửi đánh giá cho người chơi khác (sau trận đấu)
  Future<void> addUserReview(UserReviewModel review) async {
    await _firestore.collection('reviews').add(review.toFirestore());
  }

  // Gửi đánh giá cho sân con
  Future<void> addCourtReview(Map<String, dynamic> courtReviewData) async {
    await _firestore.collection('court_reviews').add(courtReviewData);
  }

  // Lấy danh sách đánh giá của một sân con cụ thể
  Future<List<Map<String, dynamic>>> getReviewsBySubCourt(
    String subCourtId,
  ) async {
    final snapshot = await _firestore
        .collection('court_reviews')
        .where('sub_court_id', isEqualTo: subCourtId)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
