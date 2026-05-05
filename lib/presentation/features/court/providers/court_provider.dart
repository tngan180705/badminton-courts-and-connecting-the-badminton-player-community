import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/court_repository.dart';
import '../../../../data/models/court_model.dart';
import '../../../../data/models/sub_court_model.dart';

// Provider cung cấp instance duy nhất của CourtRepository
final courtRepositoryProvider = Provider<CourtRepository>((ref) {
  return CourtRepository();
});

// FutureProvider dành cho trang Home của người dùng
final allCourtsProvider = FutureProvider<List<CourtModel>>((ref) async {
  final repository = ref.watch(courtRepositoryProvider);
  return repository.getAllCourts(); // Bây giờ sẽ không còn báo lỗi đỏ nữa
});

// FutureProvider lấy sân con kèm tham số ID
final subCourtsProvider =
    FutureProvider.family<List<SubCourtModel>, String>((ref, courtId) async {
  final repository = ref.watch(courtRepositoryProvider);
  return repository.getSubCourtsByCourtId(courtId);
});
