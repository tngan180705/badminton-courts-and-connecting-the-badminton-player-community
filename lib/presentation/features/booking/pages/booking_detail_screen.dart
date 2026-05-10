import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/sub_court_model.dart';
import '../../auth/providers/user_provider.dart';
import '../../community/providers/community_provider.dart';
import '../../transaction/pages/viet_qr_payment_screen.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../widgets/booking_info_box.dart';
import '../widgets/booking_user_info_box.dart';
import '../widgets/find_teammates_dialog.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _isLoading = false;

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  double _calculatePrice() {
    final startHour = widget.startTime.hour;
    final startMin = widget.startTime.minute;
    final endHour = widget.endTime.hour;
    final endMin = widget.endTime.minute;

    double totalPrice = 0;

    // Tính tiền theo từng block 30 phút hoặc 1 tiếng bằng cách quét qua từng phút (hoặc đơn giản hơn là từng block)
    // Để chính xác nhất, ta tính tổng số phút và kiểm tra giá tại từng thời điểm
    DateTime startDT = DateTime(2026, 1, 1, startHour, startMin);
    DateTime endDT = DateTime(2026, 1, 1, endHour, endMin);
    
    DateTime temp = startDT;
    const stepMinutes = 15; // Tính theo bước 15 phút để đảm bảo độ chính xác
    
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

  // ── Lấy tên người dùng từ provider ──────────────────────────────────────────
  String _getUserFullName() {
    final userData = ref.read(userDataProvider).value;
    return userData?['full_name'] ?? 'Người dùng';
  }

  // ── Flow 1: Đánh riêng / Nhóm riêng → Thanh toán 100% ───────────────────────
  void _bookAlone() {
    final fullName = _getUserFullName();
    final totalPrice = _calculatePrice();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VietQRPaymentScreen(
          paymentType: 'full_payment',
          totalAmount: totalPrice,
          payAmount: totalPrice,
          courtName: widget.courtName,
          subCourtName: widget.subCourt.subCourtName,
          formattedDate: DateFormat('dd/MM/yyyy').format(widget.bookingDate),
          startTime: _formatTime(widget.startTime),
          endTime: _formatTime(widget.endTime),
          fullName: fullName,
          onPaymentConfirmed: _saveBookingAlone,
        ),
      ),
    );
  }

  Future<void> _saveBookingAlone() async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;
    final txRepo = ref.read(transactionRepositoryProvider);

    final bookingId = await _generateBookingId();
    final totalPrice = _calculatePrice();

    // 1. Tạo booking với status pending_confirmation
    await db.collection('bookings').doc(bookingId).set({
      'player_id': currentUser.uid,
      'sub_court_id': widget.subCourt.subCourtId,
      'booking_date': Timestamp.fromDate(widget.bookingDate),
      'start_time': _formatTime(widget.startTime),
      'end_time': _formatTime(widget.endTime),
      'status': 'pending_confirmation',
      'total_price': totalPrice.toInt(),
      'payment_method': 'Chuyển khoản ngân hàng',
      'check_in_status': false,
      'created_at': Timestamp.now(),
    });

    // 2. Tạo match_post ảo
    final matchPostId = await _generateMatchPostId();
    await db.collection('match_posts').doc(matchPostId).set({
      'host_id': currentUser.uid,
      'booking_id': bookingId,
      'title': 'Đánh riêng',
      'description': 'Lịch đặt sân riêng',
      'slots_needed': 0,
      'status': 'full',
      'skill_level': 'Tất cả',
      'created_at': Timestamp.now(),
    });

    // 3. Tạo transaction record
    final transferContent = buildTransferContent(
      fullName: _getUserFullName(),
      paymentType: 'full_payment',
      subCourtName: widget.subCourt.subCourtName,
      startTime: _formatTime(widget.startTime),
      formattedDate: DateFormat('dd/MM/yyyy').format(widget.bookingDate),
    );
    await txRepo.createTransaction(
      userId: currentUser.uid,
      bookingId: bookingId,
      amount: totalPrice,
      type: 'payment',
      paymentType: 'full_payment',
      transferContent: transferContent,
    );

    print('✅ Booking alone created: $bookingId');

    if (mounted) {
      ref.invalidate(communityPostsProvider);
      ref.invalidate(myPostsProvider);
    }
  }

  // ── Flow 2: Tìm thêm người → Cọc 30% ────────────────────────────────────────
  void _findTeammates() {
    showDialog(
      context: context,
      builder: (context) => FindTeammatesDialog(
        onConfirm: (slots, skill) {
          _navigateToDepositPayment(slots, skill);
        },
      ),
    );
  }

  void _navigateToDepositPayment(int slots, String skill) {
    final fullName = _getUserFullName();
    final totalPrice = _calculatePrice();
    final depositAmount = totalPrice * 0.3;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VietQRPaymentScreen(
          paymentType: 'deposit',
          totalAmount: totalPrice,
          payAmount: depositAmount,
          courtName: widget.courtName,
          subCourtName: widget.subCourt.subCourtName,
          formattedDate: DateFormat('dd/MM/yyyy').format(widget.bookingDate),
          startTime: _formatTime(widget.startTime),
          endTime: _formatTime(widget.endTime),
          fullName: fullName,
          onPaymentConfirmed: () => _saveMatchPost(slots, skill),
        ),
      ),
    );
  }

  Future<void> _saveMatchPost(int slots, String skill) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;
    final txRepo = ref.read(transactionRepositoryProvider);
    final totalPrice = _calculatePrice();
    final depositAmount = totalPrice * 0.3;

    // 1. Tạo booking với status pending_confirmation
    final bookingId = await _generateBookingId();
    await db.collection('bookings').doc(bookingId).set({
      'player_id': currentUser.uid,
      'sub_court_id': widget.subCourt.subCourtId,
      'booking_date': Timestamp.fromDate(widget.bookingDate),
      'start_time': _formatTime(widget.startTime),
      'end_time': _formatTime(widget.endTime),
      'status': 'pending_confirmation',
      'total_price': totalPrice.toInt(),
      'deposit_paid': true,
      'deposit_amount': depositAmount.toInt(),
      'payment_method': 'Chuyển khoản ngân hàng',
      'check_in_status': false,
      'created_at': Timestamp.now(),
    });

    // 2. Tạo match_post với status 'pending_payment' → ẩn khỏi community feed
    // Admin xác nhận thanh toán → đổi thành 'open' để hiện lên
    final matchPostId = await _generateMatchPostId();
    await db.collection('match_posts').doc(matchPostId).set({
      'host_id': currentUser.uid,
      'booking_id': bookingId,
      'title': 'Tìm $slots người chơi',
      'description': 'Trình độ: $skill',
      'slots_needed': slots,
      'status': 'pending_payment',
      'skill_level': skill,
      'created_at': Timestamp.now(),
    });

    // 3. Tạo transaction record
    final transferContent = buildTransferContent(
      fullName: _getUserFullName(),
      paymentType: 'deposit',
      subCourtName: widget.subCourt.subCourtName,
      startTime: _formatTime(widget.startTime),
      formattedDate: DateFormat('dd/MM/yyyy').format(widget.bookingDate),
    );
    await txRepo.createTransaction(
      userId: currentUser.uid,
      bookingId: bookingId,
      amount: depositAmount,
      type: 'deposit',
      paymentType: 'deposit',
      transferContent: transferContent,
    );

    print('✅ Match post + deposit booking created: $bookingId, $matchPostId');

    if (mounted) {
      ref.invalidate(communityPostsProvider);
      ref.invalidate(myPostsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculatePrice();
    final formatter = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Xác nhận đặt sân'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Decoration
            Container(
              width: double.infinity,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
            
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Main Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSectionTitle(Icons.sports_tennis, 'Thông tin sân'),
                          const SizedBox(height: 16),
                          _buildInfoRow('Tên sân', widget.courtName),
                          _buildInfoRow('Số sân', widget.subCourt.subCourtName),
                          const Divider(height: 32),
                          
                          _buildSectionTitle(Icons.calendar_today, 'Thời gian'),
                          const SizedBox(height: 16),
                          _buildInfoRow('Ngày đặt', DateFormat('dd/MM/yyyy').format(widget.bookingDate)),
                          _buildInfoRow('Giờ', '${_formatTime(widget.startTime)} - ${_formatTime(widget.endTime)}'),
                          const Divider(height: 32),
                          
                          // Price Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tổng cộng',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${formatter.format(totalPrice.toInt())} đ',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // User Info Card
                    const BookingUserInfoBox(),
                    const SizedBox(height: 30),
                    
                    // Action Buttons
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Hình thức chơi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Button 1: Solo
                    _buildActionButton(
                      onPressed: _isLoading ? null : _bookAlone,
                      icon: Icons.person_outline,
                      title: 'Đánh riêng / Nhóm riêng',
                      subtitle: 'Bạn sẽ bao trọn sân trong khung giờ này',
                      color: Colors.blue[600]!,
                    ),
                    const SizedBox(height: 12),
                    
                    // Button 2: Find Teammates
                    _buildActionButton(
                      onPressed: _isLoading ? null : _findTeammates,
                      icon: Icons.group_add_outlined,
                      title: 'Tìm thêm người chơi',
                      subtitle: 'Đăng tin để ghép nhóm và chia sẻ chi phí',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
