import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/admin_provider.dart';

class AdminBookingCard extends ConsumerWidget {
  final Map<String, dynamic> bookingData;

  const AdminBookingCard({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNameAsync = ref.watch(userNameProvider(bookingData['player_id'] ?? ''));
    final subCourtNameAsync = ref.watch(subCourtNameProvider(bookingData['sub_court_id'] ?? ''));
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final status = bookingData['status'] ?? 'pending';
    final checkInStatus = bookingData['check_in_status'] ?? false;

    DateTime bDate;
    final rawDate = bookingData['booking_date'];
    if (rawDate is Timestamp) {
      bDate = rawDate.toDate();
    } else if (rawDate is String) {
      if (rawDate.contains('/')) {
        final parts = rawDate.split('/');
        bDate = parts.length == 3 ? DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0])) : DateTime.now();
      } else {
        bDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      }
    } else {
      bDate = DateTime.now();
    }
    final formattedDate = DateFormat('dd/MM/yyyy').format(bDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6136).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_today, color: Color(0xFF4A6136)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bookingData['player_id'] == 'ADMIN_BOOKING' && bookingData['customer_name'] != null)
                        Text(
                          '${bookingData['customer_name']} (Khách)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        )
                      else
                        userNameAsync.when(
                          data: (name) => Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          loading: () => const Text('Đang tải...'),
                          error: (_, __) => const Text('Khách lạ'),
                        ),
                      subCourtNameAsync.when(
                        data: (name) => Text(name, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status, checkInStatus),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F0),
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$formattedDate, ${bookingData['start_time']} - ${bookingData['end_time']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A6136)),
                    ),
                    const Text('Thời gian', style: TextStyle(fontSize: 10, color: Colors.black54)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${currencyFormatter.format(bookingData['total_price'] ?? 0)}đ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('Tổng tiền', style: TextStyle(fontSize: 10, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),

          if (status == 'cancellation_pending' && bookingData['cancellation_reason'] != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.purple.withOpacity(0.05),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lý do: ${bookingData['cancellation_reason']}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),

          // Action Buttons
          _buildActionButtons(context, status, checkInStatus),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool checkInStatus) {
    Color color = Colors.grey;
    String label = status.toUpperCase();

    if (status == 'confirmed') {
      color = Colors.blue;
      label = 'ĐÃ XÁC NHẬN';
    } else if (status == 'ongoing') {
      color = Colors.orange;
      label = 'ĐANG DIỄN RA';
    } else if (status == 'completed') {
      color = Colors.green;
      label = 'HOÀN THÀNH';
    } else if (status == 'cancelled') {
      color = Colors.red;
      label = 'ĐÃ HUỶ';
    } else if (status == 'cancellation_pending') {
      color = Colors.purple;
      label = 'CHỜ HUỶ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String status, bool checkInStatus) {
    if (status == 'confirmed') {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              'Check-in',
              const Color(0xFF4A6136),
              Icons.check_circle_outline,
              () => _updateStatus(context, 'ongoing', true),
            ),
          ),
          Expanded(
            child: _buildButton(
              'Huỷ & Hoàn tiền',
              Colors.red,
              Icons.cancel_outlined,
              () => _showCancelDialog(context),
            ),
          ),
        ],
      );
    } else if (status == 'ongoing') {
      return _buildButton(
        'Kết thúc trận đấu',
        const Color(0xFF4A6136),
        Icons.done_all,
        () => _updateStatus(context, 'completed', true),
      );
    } else if (status == 'cancellation_pending') {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              'Đồng ý huỷ',
              Colors.green,
              Icons.check,
              () => _updateStatus(context, 'cancelled', false),
            ),
          ),
          Expanded(
            child: _buildButton(
              'Từ chối',
              Colors.red,
              Icons.close,
              () => _updateStatus(context, 'confirmed', false),
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  Widget _buildButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border(
            top: BorderSide(color: color.withOpacity(0.2)),
            left: BorderSide(color: color.withOpacity(0.1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus, bool checkIn) async {
    final db = FirebaseFirestore.instance;
    try {
      await db.collection('bookings').doc(bookingData['id']).update({
        'status': newStatus,
        'check_in_status': checkIn,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái: $newStatus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận huỷ sân?'),
        content: const Text('Hành động này sẽ huỷ sân và bạn cần thực hiện hoàn tiền thủ công cho khách qua Zalo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(context, 'cancelled', false);
            },
            child: const Text('Huỷ sân & Hoàn tiền', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
