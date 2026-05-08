import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/review_repository.dart';
import '../../../../data/models/review_model.dart';

final reviewRepositoryProvider =
    Provider((ref) => ReviewRepository());

// Lấy danh sách đánh giá sân
final courtReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>(
        (ref, subCourtId) {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewsBySubCourt(subCourtId);
});

// Lấy danh sách đánh giá người dùng
final userProfileReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>(
        (ref, userId) {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewsByUser(userId);
});