import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import './member_list_dialog.dart';

class ActivityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String category;

  const ActivityCard({super.key, required this.data, required this.category});

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
    final hostPhone = data['host_phone'] ?? '0123 456 789';

    final dateStr = _getFormattedDate(bookingDate);
    final now = DateTime.now();
    final hoursUntilMatch = bookingDate.difference(now).inHours;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildInfoRow(Icons.sports_tennis, '$subCourtName - $courtName')),
              if (category == 'upcoming')
                GestureDetector(
                  onTap: () => _handleCancellation(context, hoursUntilMatch),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, '$dateStr, $startTime - $endTime'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, 'SĐT: $hostPhone'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.attach_money, '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price)} - Đã thanh toán $paymentMethod'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  category == 'finished' ? 'Đánh giá sân' : 'Xem chi tiết thành viên',
                  category == 'finished' ? Icons.star_outline : Icons.people_outline,
                  () {
                    if (category == 'finished') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đánh giá sân đang được phát triển')),
                      );
                    } else {
                      _showMembers(context, bookingId);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  category == 'finished' ? 'Đánh giá thành viên' : 'Nhắn tin nhóm',
                  category == 'finished' ? Icons.rate_review_outlined : Icons.chat_bubble_outline,
                  () {
                    if (category == 'finished') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đánh giá thành viên đang được phát triển')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng nhắn tin nhóm đang được phát triển')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleCancellation(BuildContext context, int hoursUntilMatch) {
    if (hoursUntilMatch > 24) {
      _showCancellationForm(context);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Hiện tại trận đấu diễn ra trong vòng 24h. Vui lòng liên hệ số 0566697796 để trao đổi chi tiết.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    }
  }

  void _showCancellationForm(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu hủy trận'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập lý do hủy trận:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Thoát'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do')),
                );
                return;
              }
              // Here you would typically send the request to Firestore
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yêu cầu hủy đã được gửi thành công')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A6136)),
            child: const Text('Gửi yêu cầu', style: TextStyle(color: Colors.white)),
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
