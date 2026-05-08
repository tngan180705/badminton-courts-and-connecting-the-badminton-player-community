import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

/// Card tóm tắt thông tin đặt sân + số tiền cần thanh toán
class PaymentInfoCard extends StatelessWidget {
  final String paymentType; // 'trả hết' | 'đặt cọc'
  final String courtName;
  final String subCourtName;
  final String formattedDate;
  final String startTime;
  final String endTime;
  final double totalAmount;
  final double payAmount;

  const PaymentInfoCard({
    super.key,
    required this.paymentType,
    required this.courtName,
    required this.subCourtName,
    required this.formattedDate,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.payAmount,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final isDeposit = paymentType == 'deposit';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge loại thanh toán
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isDeposit
                  ? Colors.orange.withOpacity(0.12)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isDeposit ? '🔒 Đặt cọc 30%' : '✅ Thanh toán toàn bộ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDeposit ? Colors.orange[700] : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Thông tin sân
          _infoRow(Icons.sports_tennis, 'Sân', '$courtName – $subCourtName'),
          const SizedBox(height: 8),
          _infoRow(Icons.calendar_today, 'Ngày', formattedDate),
          const SizedBox(height: 8),
          _infoRow(Icons.access_time, 'Giờ', '$startTime – $endTime'),

          const Divider(height: 24),

          // Số tiền
          if (isDeposit) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền sân',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text('${formatter.format(totalAmount.toInt())} đ',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDeposit ? 'Cần cọc (30%)' : 'Cần thanh toán',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                '${formatter.format(payAmount.toInt())} đ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDeposit ? Colors.orange[700] : AppColors.primary,
                ),
              ),
            ],
          ),

          if (isDeposit)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '* Phần còn lại thanh toán trực tiếp tại sân',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
