import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/review_repository.dart';
import '../../../../data/models/review_model.dart';

final reviewRepositoryProvider =
    Provider((ref) => ReviewRepository());

final userReviewsProvider =
    FutureProvider.family<List<UserReviewModel>, String>(
        (ref, subCourtId) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewsBySubCourt(subCourtId);
});