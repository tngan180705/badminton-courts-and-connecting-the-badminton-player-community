import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 👇 Provider lưu booking hiện tại (để share giữa screens)
final currentBookingProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

// 👇 Provider lấy available time slots cho ngày + sân
final availableTimeSlotsProvider =
    FutureProvider.family<List<String>, ({String subCourtId, DateTime date})>(
        (ref, params) async {
  final db = FirebaseFirestore.instance;
  final now = DateTime.now();
  final isToday = params.date.year == now.year &&
      params.date.month == now.month &&
      params.date.day == now.day;

  // Giờ bắt đầu
  int startHour = 5;
  if (isToday) {
    startHour = now.hour + 1;
    if (startHour > 22) startHour = 22;
  }

  const int endHour = 22;

  // Lấy bookings đã đặt
  final bookingsSnapshot = await db
      .collection('bookings')
      .where('sub_court_id', isEqualTo: params.subCourtId)
      .where('booking_date',
          isEqualTo: Timestamp.fromDate(DateTime(
            params.date.year,
            params.date.month,
            params.date.day,
          )))
      .where('status', isEqualTo: 'confirmed')
      .get();

  // Parse giờ đã đặt
  final bookedHours = <int>{};
  for (final booking in bookingsSnapshot.docs) {
    final startTime = booking['start_time'] as String?;
    final endTime = booking['end_time'] as String?;

    if (startTime != null && endTime != null) {
      final startHourParsed = int.parse(startTime.split(':')[0]);
      final endHourParsed = int.parse(endTime.split(':')[0]);

      for (int h = startHourParsed; h < endHourParsed; h++) {
        bookedHours.add(h);
      }
    }
  }

  // Giờ trống
  final availableHours = <String>[];
  for (int h = startHour; h <= endHour; h++) {
    if (!bookedHours.contains(h)) {
      availableHours.add('${h.toString().padLeft(2, '0')}:00');
    }
  }

  return availableHours;
});
// 👇 Generate booking ID
final generateBookingIdProvider = FutureProvider((ref) async {
  final db = FirebaseFirestore.instance;
  final snapshot = await db.collection('bookings').get();

  int maxNum = 0;
  for (final doc in snapshot.docs) {
    final data = doc.data();
    // Nếu doc.id có format BK_XXX
    if (doc.id.startsWith('BK_')) {
      final numStr = doc.id.replaceFirst('BK_', '');
      final num = int.tryParse(numStr) ?? 0;
      if (num > maxNum) maxNum = num;
    }
  }

  final nextNum = maxNum + 1;
  return 'BK_${nextNum.toString().padLeft(3, '0')}';
});
