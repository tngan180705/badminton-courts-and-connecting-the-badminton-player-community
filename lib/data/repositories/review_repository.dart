import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'court_reviews'; // ✅ CHỐT 1 COLLECTION

  Future<void> addCourtReview(UserReviewModel review) async {
    await _firestore.collection(_collection).add(review.toFirestore());
  }

  Future<List<UserReviewModel>> getReviewsBySubCourt(String subCourtId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('sub_court_id', isEqualTo: subCourtId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => UserReviewModel.fromSnapshot(doc))
        .toList();
  }
}