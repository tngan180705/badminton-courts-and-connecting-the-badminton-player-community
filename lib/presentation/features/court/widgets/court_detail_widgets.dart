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
  final formatter = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${widget.courtName} - ${widget.subCourt.subCourtName}',
                  style: const TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
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
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildPriceTag('150.000', 'Cơ bản', Colors.blue),
              const SizedBox(width: 12),
              _buildPriceTag('40.000', 'Giờ vàng', Colors.orange),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 20),
                  SizedBox(width: 10),
                  Text(
                    "ĐẶT SÂN NGAY",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Giờ vàng (5h-7h & 20h-22h): Tiết kiệm tới 70%',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTag(String price, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '$price đ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
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
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Khung giờ trống - ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<int>>(
          future: _getAvailableHours(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text(
                    'Hết khung giờ trống trong ngày',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }

            final availableHours = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableHours.map((hour) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
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
