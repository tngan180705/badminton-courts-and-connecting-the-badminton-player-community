import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/admin_stats_model.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../../../../data/repositories/court_repository.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../data/repositories/user_repository.dart';

final adminStatsProvider = StateNotifierProvider<
    AdminStatsNotifier,
    AsyncValue<AdminStatsModel>>(
  (ref) => AdminStatsNotifier(),
);

class AdminStatsNotifier
    extends StateNotifier<AsyncValue<AdminStatsModel>> {
  AdminStatsNotifier() : super(const AsyncLoading()) {
    fetchDashboardStats();
  }

  final BookingRepository _bookingRepository = BookingRepository();
  final UserRepository _userRepository = UserRepository();
  final CourtRepository _courtRepository = CourtRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();

  Future<void> fetchDashboardStats() async {
    try {
      state = const AsyncLoading();

      // Gọi riêng từng Future — giữ đúng type, tránh lỗi cast từ Future.wait
      final int totalUsers =
          await _userRepository.getTotalUsers();

      final int totalCourts =
await _courtRepository.getTotalSubCourts();      final int totalBookings =
          await _bookingRepository.getTotalBookings();

      final int todayBookings =
          await _bookingRepository.getTodayBookings();

      final double totalRevenue =
          await _transactionRepository.getTotalRevenue();

      state = AsyncData(
        AdminStatsModel(
          totalUsers: totalUsers,
          totalCourts: totalCourts,
          totalBookings: totalBookings,
          todayBookings: todayBookings,
          totalRevenue: totalRevenue,
        ),
      );
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}