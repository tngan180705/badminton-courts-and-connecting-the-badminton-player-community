import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _courtReviewsCol = 'court_reviews';
  final String _userReviewsCol = 'reviews';

  Future<String> _generateReviewId(String collection, String prefix) async {
    final snapshot = await _firestore.collection(collection).get();
    int maxNum = 0;
    for (final doc in snapshot.docs) {
      if (doc.id.startsWith(prefix)) {
        final numStr = doc.id.replaceFirst(prefix, '');
        final num = int.tryParse(numStr) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }
    return '$prefix${(maxNum + 1).toString().padLeft(4, '0')}';
  }

  // Thêm đánh giá Sân
  Future<void> addCourtReview(ReviewModel review) async {
    final newId = await _generateReviewId(_courtReviewsCol, 'RVC_');
    await _firestore.collection(_courtReviewsCol).doc(newId).set(review.toFirestore());
  }

  // Thêm đánh giá User
  Future<void> addPlayerReview(ReviewModel review) async {
    final newId = await _generateReviewId(_userReviewsCol, 'RVU_');
    await _firestore.collection(_userReviewsCol).doc(newId).set(review.toFirestore());
  }

  // Lấy đánh giá sân
  Stream<List<ReviewModel>> getReviewsBySubCourt(String subCourtId) {
    return _firestore
        .collection(_courtReviewsCol)
        .where('sub_court_id', isEqualTo: subCourtId)
        .snapshots()
        .map((snapshot) {
           final list = snapshot.docs.map((doc) => ReviewModel.fromSnapshot(doc)).toList();
           list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
           return list;
        });
  }

  // Lấy đánh giá người chơi
  Stream<List<ReviewModel>> getReviewsByUser(String userId) {
    return _firestore
        .collection(_userReviewsCol)
        .where('to_user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
           final list = snapshot.docs.map((doc) => ReviewModel.fromSnapshot(doc)).toList();
           list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
           return list;
        });
  }
}