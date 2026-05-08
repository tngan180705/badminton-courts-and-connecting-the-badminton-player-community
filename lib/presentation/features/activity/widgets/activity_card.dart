import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import './member_list_dialog.dart';
import '../../review/widgets/review_court_dialog.dart';
import '../../review/widgets/review_member_dialog.dart';

class ActivityCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String category;

  const ActivityCard({super.key, required this.data, required this.category});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _isCourtReviewed = false;
  bool _isMemberReviewed = false;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkReviewStatus();
  }

  Future<void> _checkReviewStatus() async {
    if (widget.category != 'finished') return;
    
    final db = FirebaseFirestore.instance;
    final bookingId = widget.data['id'] as String;
    // Lấy uid trực tiếp vì ActivityCard không phải ConsumerStatefulWidget, 
    // hoặc có thể mượn FirebaseAuth
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final courtReviewSnap = await db.collection('court_reviews')
          .where('booking_id', isEqualTo: bookingId)
          .where('from_user_id', isEqualTo: currentUserId)
          .limit(1)
          .get();

      final memberReviewSnap = await db.collection('reviews')
          .where('from_user_id', isEqualTo: currentUserId)
          // Ta không lưu booking_id cho member review ở bài trước, cần check hoặc lưu thêm
          // Wait, we need to add booking_id to member review!
          .get();
          
      // Thực tế ta vừa thêm bookingId vào ReviewModel. 
      // Cần query có booking_id
      final memberReviewSnap2 = await db.collection('reviews')
          .where('booking_id', isEqualTo: bookingId)
          .where('from_user_id', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _isCourtReviewed = courtReviewSnap.docs.isNotEmpty;
          _isMemberReviewed = memberReviewSnap2.docs.isNotEmpty;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.data['id'] as String;
    final courtName = widget.data['court_name'] ?? 'Sân Cầu Lông ABC';
    final subCourtName = widget.data['sub_court_name'] ?? 'Sân số 2';
    final bookingDate = (widget.data['booking_date'] as Timestamp).toDate();
    final startTime = widget.data['start_time'] as String? ?? '18:00';
    final endTime = widget.data['end_time'] as String? ?? '20:00';
    final price = widget.data['total_price'] ?? 150000;
    final paymentMethod = widget.data['payment_method'] ?? 'MoMo';
    final hostPhone = widget.data['host_phone'] ?? '0123 456 789';

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
              if (widget.category == 'upcoming')
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
                  widget.category == 'finished' 
                      ? (_isCourtReviewed ? 'Đã đánh giá sân' : 'Đánh giá sân')
                      : 'Xem chi tiết thành viên',
                  widget.category == 'finished' 
                      ? (_isCourtReviewed ? Icons.check_circle : Icons.star_outline) 
                      : Icons.people_outline,
                  () async {
                    if (widget.category == 'finished') {
                      if (_isCourtReviewed) return; // Nếu đã đánh giá thì bỏ qua

                      final courtId = widget.data['court_id'] as String?;
                      final subCourtId = widget.data['sub_court_id'] as String? ?? '';
                      
                      final result = await showDialog(
                        context: context,
                        builder: (context) => ReviewCourtDialog(
                          subCourtId: subCourtId,
                          courtId: widget.data['court_id'] as String? ?? 'CT_001',
                          subCourtName: '$subCourtName - $courtName',
                          bookingId: bookingId,
                        ),
                      );

                      if (result == true) {
                        setState(() => _isCourtReviewed = true);
                      }
                    } else {
                      _showMembers(context, bookingId);
                    }
                  },
                  isCompleted: widget.category == 'finished' && _isCourtReviewed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  widget.category == 'finished' 
                      ? (_isMemberReviewed ? 'Đã đánh giá thành viên' : 'Đánh giá thành viên') 
                      : 'Nhắn tin nhóm',
                  widget.category == 'finished' 
                      ? (_isMemberReviewed ? Icons.check_circle : Icons.rate_review_outlined) 
                      : Icons.chat_bubble_outline,
                  () async {
                    if (widget.category == 'finished') {
                      // Không block return ở đây, vẫn cho phép ấn vào để đánh giá người khác
                      final result = await showDialog(
                        context: context,
                        builder: (context) => ReviewMemberDialog(bookingId: bookingId),
                      );

                      if (result == true) {
                        setState(() => _isMemberReviewed = true);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng nhắn tin nhóm đang được phát triển')),
                      );
                    }
                  },
                  isCompleted: widget.category == 'finished' && _isMemberReviewed,
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

  Widget _buildButton(String label, IconData icon, VoidCallback onTap, {bool isCompleted = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.grey.shade200 : Colors.white,
          border: Border.all(color: isCompleted ? Colors.grey.shade400 : const Color(0xFF4A6136)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isCompleted ? Colors.grey.shade700 : const Color(0xFF4A6136),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: isCompleted ? Colors.grey.shade700 : const Color(0xFF4A6136)),
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
