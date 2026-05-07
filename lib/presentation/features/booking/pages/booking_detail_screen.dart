import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/sub_court_model.dart';
import '../widgets/booking_info_box.dart';
import '../widgets/booking_user_info_box.dart';
import '../widgets/find_teammates_dialog.dart';
import '../widgets/payment_dialog.dart';

class BookingDetailScreen extends StatefulWidget {
  final String courtName;
  final SubCourtModel subCourt;
  final DateTime bookingDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const BookingDetailScreen({
    super.key,
    required this.courtName,
    required this.subCourt,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _isLoading = false;

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  double _calculatePrice() {
    final start = widget.startTime.hour;
    final end = widget.endTime.hour;
    final endMin = widget.endTime.minute;

    double totalPrice = 0;

    for (int h = start; h < end; h++) {
      if ((h >= 5 && h < 7) || (h >= 20 && h < 22)) {
        totalPrice += 40000;
      } else {
        totalPrice += 150000;
      }
    }

    if (endMin > 0) {
      final lastHour = end;
      final pricePerHour =
          (lastHour >= 5 && lastHour < 7) || (lastHour >= 20 && lastHour < 22)
              ? 40000
              : 150000;
      totalPrice += (endMin / 60) * pricePerHour;
    }

    return totalPrice;
  }

  Future<String> _generateMatchPostId() async {
    final db = FirebaseFirestore.instance;

    try {
      final snapshot = await db.collection('match_posts').get();

      int maxNum = 0;
      for (final doc in snapshot.docs) {
        if (doc.id.startsWith('MP_')) {
          final numStr = doc.id.replaceFirst('MP_', '');
          final num = int.tryParse(numStr) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }

      final nextNum = maxNum + 1;
      final matchPostId = 'MP_${nextNum.toString().padLeft(3, '0')}';
      print('✅ Generated match post ID: $matchPostId');
      return matchPostId;
    } catch (e) {
      print('❌ Error generating ID: $e');
      rethrow;
    }
  }

  Future<String> _generateBookingId() async {
    final db = FirebaseFirestore.instance;

    try {
      final snapshot = await db.collection('bookings').get();

      int maxNum = 0;
      for (final doc in snapshot.docs) {
        if (doc.id.startsWith('BK_')) {
          final numStr = doc.id.replaceFirst('BK_', '');
          final num = int.tryParse(numStr) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }

      final nextNum = maxNum + 1;
      final bookingId = 'BK_${nextNum.toString().padLeft(3, '0')}';
      print('✅ Generated booking ID: $bookingId');
      return bookingId;
    } catch (e) {
      print('❌ Error generating ID: $e');
      rethrow;
    }
  }

  Future<void> _bookAlone() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;

      // ✅ Generate booking ID
      final bookingId = await _generateBookingId();

      await db.collection('bookings').doc(bookingId).set({
        'player_id': currentUser.uid,
        'sub_court_id': widget.subCourt.subCourtId,
        'booking_date': Timestamp.fromDate(widget.bookingDate),
        'start_time': _formatTime(widget.startTime),
        'end_time': _formatTime(widget.endTime),
        'status': 'confirmed',
        'total_price': _calculatePrice().toInt(),
        'payment_method': 'wallet',
        'check_in_status': false,
        'created_at': Timestamp.now(),
      });

      print('✅ Booking created: $bookingId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt sân thành công!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _findTeammates() {
    showDialog(
      context: context,
      builder: (context) => FindTeammatesDialog(
        onConfirm: (slots, skill) {
          _createMatchPost(slots, skill);
        },
      ),
    );
  }

  Future<void> _createMatchPost(int slots, String skill) async {
    final depositPrice = (_calculatePrice() * 0.3).toInt();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        depositAmount: depositPrice,
        onConfirm: () async {
          Navigator.pop(context); // Đóng dialog
          await _submitMatchPost(slots, skill); // Tạo booking + post
        },
      ),
    );
  }

  Future<void> _submitMatchPost(int slots, String skill) async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;

      // ✅ 1. Generate booking ID
      final bookingId = await _generateBookingId();

      // ✅ 2. Tạo booking
      await db.collection('bookings').doc(bookingId).set({
        'player_id': currentUser.uid,
        'sub_court_id': widget.subCourt.subCourtId,
        'booking_date': Timestamp.fromDate(widget.bookingDate),
        'start_time': _formatTime(widget.startTime),
        'end_time': _formatTime(widget.endTime),
        'status': 'confirmed',
        'total_price': _calculatePrice().toInt(),
        'deposit_paid': true,
        'deposit_amount': (_calculatePrice() * 0.3).toInt(),
        'payment_method': 'bank_transfer',
        'check_in_status': false,
        'created_at': Timestamp.now(),
      });

      // ✅ 3. Tạo match_post
      final matchPostId = await _generateMatchPostId();
      await db.collection('match_posts').doc(matchPostId).set({
        'host_id': currentUser.uid,
        'booking_id': bookingId, // Link tới booking
        'title': 'Tìm $slots người chơi',
        'description': 'Trình độ: $skill',
        'slots_needed': slots,
        'status': 'open',
        'skill_level': skill,
        'created_at': Timestamp.now(),
      });

      print('✅ Match post created: $matchPostId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng bài ghép nhóm thành công!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context); // Quay lại court detail
        Navigator.pop(context); // Quay lại home
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculatePrice();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đặt sân'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sân
              BookingInfoBox(
                label: 'Sân',
                value: '${widget.courtName} - ${widget.subCourt.subCourtName}',
              ),
              const SizedBox(height: 12),

              // Ngày
              BookingInfoBox(
                label: 'Ngày',
                value: DateFormat('dd/MM/yyyy').format(widget.bookingDate),
              ),
              const SizedBox(height: 12),

              // Giờ
              BookingInfoBox(
                label: 'Thời gian',
                value:
                    '${_formatTime(widget.startTime)} - ${_formatTime(widget.endTime)}',
              ),
              const SizedBox(height: 12),

              // Giá
              BookingInfoBox(
                label: 'Tổng tiền',
                value: '${totalPrice.toInt()} đ',
                backgroundColor: Colors.orange.shade50,
              ),
              const SizedBox(height: 12),

              // User info
              const BookingUserInfoBox(),
              const SizedBox(height: 32),

              // Buttons
              const Text(
                'Bạn muốn:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _bookAlone,
                  icon: const Icon(Icons.person),
                  label: const Text('Đánh riêng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _findTeammates,
                  icon: const Icon(Icons.people),
                  label: const Text('Tìm thêm người'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
