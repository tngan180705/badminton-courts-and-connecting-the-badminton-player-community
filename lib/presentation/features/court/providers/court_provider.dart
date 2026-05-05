import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/court_repository.dart';
import '../../../../data/models/court_model.dart';
import '../../../../data/models/sub_court_model.dart';

final courtRepositoryProvider = Provider<CourtRepository>((ref) {
  return CourtRepository();
});

// Lấy court đầu tiên (cửa hàng duy nhất)
final singleCourtProvider = FutureProvider<CourtModel?>((ref) async {
  final repository = ref.watch(courtRepositoryProvider);
  final courts = await repository.getAllCourts();
  return courts.isNotEmpty ? courts.first : null;
});

// Lấy sub_courts của court đầu tiên — dùng cho HomeScreen
final homeSubCourtsProvider = FutureProvider<List<SubCourtModel>>((ref) async {
  final courtAsync = await ref.watch(singleCourtProvider.future);
  if (courtAsync == null) return [];
  final repository = ref.watch(courtRepositoryProvider);
  return repository.getSubCourtsByCourtId(courtAsync.courtId);
});

// Giữ lại để dùng ở chỗ khác nếu cần
final allCourtsProvider = FutureProvider<List<CourtModel>>((ref) async {
  return ref.watch(courtRepositoryProvider).getAllCourts();
});

final subCourtsProvider =
    FutureProvider.family<List<SubCourtModel>, String>((ref, courtId) async {
  return ref.watch(courtRepositoryProvider).getSubCourtsByCourtId(courtId);
});
