import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/sub_court_model.dart';
import '../../booking/pages/booking_screen.dart';

// 👇 Widget hiển thị giá + yêu thích
class CourtPricingCard extends StatefulWidget {
  final String courtName;
  final SubCourtModel subCourt;
  final Function(bool) onFavoriteChanged;

  const CourtPricingCard({
    super.key,
    required this.courtName,
    required this.subCourt,
    required this.onFavoriteChanged,
  });

  @override
  State<CourtPricingCard> createState() => _CourtPricingCardState();
}

class _CourtPricingCardState extends State<CourtPricingCard> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.courtName} - ${widget.subCourt.subCourtName}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // 👇 Mở BookingScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(
                      courtName: widget.courtName,
                      subCourt: widget.subCourt,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text("Đặt sân ngay"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    isFavorite = !isFavorite;
                    widget.onFavoriteChanged(isFavorite);
                  });
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.payments_outlined, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '150.000đ / giờ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '🔥 Giờ vàng (5h-7h & 20h-22h): Chỉ 40.000đ/giờ',
              style: TextStyle(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 👇 Widget khung giờ trống
class AvailableTimeSlotsWidget extends StatelessWidget {
  final SubCourtModel subCourt;
  final DateTime selectedDate;

  const AvailableTimeSlotsWidget({
    super.key,
    required this.subCourt,
    required this.selectedDate,
  });

  Future<List<int>> _getAvailableHours() async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    // Giờ bắt đầu
    int startHour = 5;
    if (isToday) {
      startHour = now.hour + 1; // Từ giờ tới
      if (startHour > 22) startHour = 22; // Tối đa 22h
    }

    // Giờ kết thúc
    const int endHour = 22;

    // Lấy bookings đã đặt trong ngày này
    final bookingsSnapshot = await db
        .collection('bookings')
        .where('sub_court_id', isEqualTo: subCourt.subCourtId)
        .where('booking_date',
            isEqualTo: Timestamp.fromDate(DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
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
    final availableHours = <int>[];
    for (int h = startHour; h <= endHour; h++) {
      if (!bookedHours.contains(h)) {
        availableHours.add(h);
      }
    }

    return availableHours;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Khung giờ trống - ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<int>>(
          future: _getAvailableHours(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Không có khung giờ trống'),
              );
            }

            final availableHours = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableHours.map((hour) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// 👇 Widget Review Tile
class ReviewTile extends StatelessWidget {
  final dynamic review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final int rating = (review.ratingScore ?? 0);

    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text(review.fromUserId ?? "Người dùng"),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(review.comment ?? ""),
        ],
      ),
    );
  }
}

// 👇 Widget CourtImageCarousel
class CourtImageCarousel extends StatelessWidget {
  final List<String> images;

  const CourtImageCarousel({
    super.key,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: images.length,
        itemBuilder: (context, index) => Container(
          width: 300,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage(images[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

// 👇 Widget CourtHeader
class CourtHeader extends StatelessWidget {
  final String title;

  const CourtHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// 👇 Widget SectionTitle
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
