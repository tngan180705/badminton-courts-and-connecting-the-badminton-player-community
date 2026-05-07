import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class BookingPriceSummary extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const BookingPriceSummary({
    super.key,
    required this.startTime,
    required this.endTime,
  });

  double _calculatePrice() {
    final startHour = startTime.hour;
    final startMin = startTime.minute;
    final endHour = endTime.hour;
    final endMin = endTime.minute;

    double totalPrice = 0;

    DateTime startDT = DateTime(2026, 1, 1, startHour, startMin);
    DateTime endDT = DateTime(2026, 1, 1, endHour, endMin);
    
    DateTime temp = startDT;
    const stepMinutes = 15;
    
    while (temp.isBefore(endDT)) {
      final hour = temp.hour;
      final isGolden = (hour >= 5 && hour < 7) || (hour >= 20 && hour < 22);
      final pricePerMinute = (isGolden ? 40000 : 150000) / 60;
      
      int remainingMinutes = endDT.difference(temp).inMinutes;
      int currentStep = remainingMinutes < stepMinutes ? remainingMinutes : stepMinutes;
      
      totalPrice += currentStep * pricePerMinute;
      temp = temp.add(Duration(minutes: currentStep));
    }

    return totalPrice;
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M đ';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K đ';
    }
    return '${price.toStringAsFixed(0)} đ';
  }

  // 👇 Tính chi tiết từng khung giờ
  Map<String, double> _getPriceBreakdown() {
    final breakdown = <String, double>{};
    final start = startTime.hour;
    final end = endTime.hour;
    final endMin = endTime.minute;

    for (int h = start; h < end; h++) {
      final double price =
          (h >= 5 && h < 7) || (h >= 20 && h < 22) ? 40000 : 150000;
      final label = '${h.toString().padLeft(2, '0')}:00-'
          '${(h + 1).toString().padLeft(2, '0')}:00';
      breakdown[label] = price;
    }

    if (endMin > 0) {
      final lastHour = end;
      final price =
          (lastHour >= 5 && lastHour < 7) || (lastHour >= 20 && lastHour < 22)
              ? 40000
              : 150000;
      final label = '${lastHour.toString().padLeft(2, '0')}:00-'
          '${lastHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}';
      breakdown[label] = (endMin / 60) * price;
    }

    return breakdown;
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculatePrice();
    final priceBreakdown = _getPriceBreakdown();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👇 Chi tiết từng khung giờ
          ...priceBreakdown.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${entry.value.toInt()} đ',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 12),

          // 👇 Tổng tiền
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tiền',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _formatPrice(totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
