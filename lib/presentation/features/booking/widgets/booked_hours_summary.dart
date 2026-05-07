import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

class BookedHoursSummary extends StatelessWidget {
  final String subCourtId;

  const BookedHoursSummary({
    super.key,
    required this.subCourtId,
  });

  Future<Map<String, List<String>>> _fetchAllBookedSlots() async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    // Lấy từ bắt đầu ngày hôm nay (00:00:00)
    final today = DateTime(now.year, now.month, now.day);
    // Lấy đến hết 7 ngày tới (23:59:59)
    final next7Days = today.add(const Duration(days: 8));

    final snapshot = await db
        .collection('bookings')
        .where('sub_court_id', isEqualTo: subCourtId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    final Map<String, List<String>> bookedMap = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rawDate = data['booking_date'];
      DateTime? bookingDate;

      if (rawDate is Timestamp) {
        bookingDate = rawDate.toDate();
      } else if (rawDate is String) {
        bookingDate = DateTime.tryParse(rawDate);
      }

      if (bookingDate == null) continue;

      // Chỉ lấy trong khoảng 7 ngày tới (từ hôm nay)
      if (bookingDate.isBefore(today) || bookingDate.isAfter(next7Days)) {
        continue;
      }

      final startTime = data['start_time']?.toString() ?? '';
      final endTime = data['end_time']?.toString() ?? '';
      if (startTime.isEmpty || endTime.isEmpty) continue;

      // ✅ Kiểm tra nếu là hôm nay thì phải chưa kết thúc
      if (bookingDate.year == now.year && bookingDate.month == now.month && bookingDate.day == now.day) {
        final endParts = endTime.split(':');
        if (endParts.length == 2) {
          final endHour = int.tryParse(endParts[0]) ?? 0;
          final endMin = int.tryParse(endParts[1]) ?? 0;
          final endDateTime = DateTime(now.year, now.month, now.day, endHour, endMin);
          if (now.isAfter(endDateTime)) {
            continue; // Đã qua giờ kết thúc
          }
        }
      }

      final dateStr = DateFormat('dd/MM').format(bookingDate);

      if (!bookedMap.containsKey(dateStr)) {
        bookedMap[dateStr] = [];
      }
      bookedMap[dateStr]!.add('$startTime - $endTime');
    }

    return bookedMap;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.event_busy, size: 18, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Lịch đã được đặt (7 ngày tới)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, List<String>>>(
          future: _fetchAllBookedSlots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Chưa có ai đặt sân trong 7 ngày tới. Hãy là người đầu tiên!',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              );
            }

            final data = snapshot.data!;
            final sortedDates = data.keys.toList()..sort();

            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final slots = data[date]!;

                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 5,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                        const Divider(height: 8),
                        Expanded(
                          child: ListView(
                            children: slots
                                .map((s) => Text(
                                      s,
                                      style: const TextStyle(fontSize: 11),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
