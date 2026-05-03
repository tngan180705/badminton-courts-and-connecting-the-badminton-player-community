import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../data/repositories/court_repository.dart';
import '../../../../../data/models/court_model.dart';
// Import lại repository provider gốc
import '../../../court/providers/court_provider.dart';

// StreamProvider cho Admin (Tự động cập nhật UI khi xóa/sửa)
final allCourtsStreamProvider = StreamProvider.autoDispose<List<CourtModel>>((ref) {
  final repository = ref.watch(courtRepositoryProvider);
  return repository.watchAllCourts();
});

// StateNotifier điều khiển logic ghi dữ liệu
final adminCourtActionProvider = StateNotifierProvider<AdminCourtNotifier, AsyncValue<void>>((ref) {
  return AdminCourtNotifier(ref.watch(courtRepositoryProvider));
});

class AdminCourtNotifier extends StateNotifier<AsyncValue<void>> {
  final CourtRepository _repository;
  
  AdminCourtNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> addNewCourt(CourtModel court) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addCourt(court);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editCourt(CourtModel court) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateCourt(court);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeCourt(String courtId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCourt(courtId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}