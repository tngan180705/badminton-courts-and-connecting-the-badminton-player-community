import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/court_repository.dart';
import '../../../../data/models/court_model.dart';
import '../../../../data/models/sub_court_model.dart';

// 1. Provider cung cấp instance của CourtRepository
// Điều này giúp dễ dàng thay thế hoặc Mock khi viết Unit Test
final courtRepositoryProvider = Provider<CourtRepository>((ref) {
  return CourtRepository();
});

// 2. FutureProvider lấy toàn bộ danh sách sân lớn
// UI Home Screen sẽ watch provider này
final allCourtsProvider = FutureProvider<List<CourtModel>>((ref) async {
  // Lắng nghe repository
  final repository = ref.watch(courtRepositoryProvider);

  // Gọi hàm lấy dữ liệu từ Firebase mà bạn đã viết
  return repository.getAllCourts();
});

// 3. FutureProvider lấy danh sách sân con theo ID sân lớn
// Sử dụng .family để có thể truyền tham số courtId từ UI vào
final subCourtsProvider =
    FutureProvider.family<List<SubCourtModel>, String>((ref, courtId) async {
  final repository = ref.watch(courtRepositoryProvider);

  // Gọi hàm lấy sân con dựa trên ID sân lớn
  return repository.getSubCourtsByCourtId(courtId);
});
