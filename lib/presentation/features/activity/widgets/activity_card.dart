import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import './member_list_dialog.dart';

class ActivityCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ActivityCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final bookingId = data['id'] as String;
    final courtName = data['court_name'] ?? 'Sân Cầu Lông ABC';
    final subCourtName = data['sub_court_name'] ?? 'Sân số 2';
    final bookingDate = (data['booking_date'] as Timestamp).toDate();
    final startTime = data['start_time'] as String? ?? '18:00';
    final endTime = data['end_time'] as String? ?? '20:00';
    final price = data['total_price'] ?? 150000;
    final paymentMethod = data['payment_method'] ?? 'MoMo';

    final dateStr = _getFormattedDate(bookingDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.sports_tennis, '$subCourtName - $courtName'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, '$dateStr, $startTime - $endTime'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.attach_money, '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price)} - Đã thanh toán $paymentMethod'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  'Xem chi tiết thành viên',
                  Icons.people_outline,
                  () {
                    _showMembers(context, bookingId);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  'Nhắn tin nhóm',
                  Icons.chat_bubble_outline,
                  () {
                    // Placeholder for chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng nhắn tin nhóm đang được phát triển')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMembers(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => MemberListDialog(bookingId: bookingId),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF4A6136)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4A6136),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: const Color(0xFF4A6136)),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hôm nay';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Ngày mai';
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
