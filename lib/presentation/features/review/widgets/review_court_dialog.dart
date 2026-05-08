import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/review_provider.dart';
import '../../../../data/models/review_model.dart';
import '../../auth/providers/user_provider.dart';

class ReviewCourtDialog extends ConsumerStatefulWidget {
  final String subCourtId;
  final String courtId;
  final String subCourtName;
  final String bookingId;

  const ReviewCourtDialog({
    super.key,
    required this.subCourtId,
    required this.courtId,
    required this.subCourtName,
    required this.bookingId,
  });

  @override
  ConsumerState<ReviewCourtDialog> createState() => _ReviewCourtDialogState();
}

class _ReviewCourtDialogState extends ConsumerState<ReviewCourtDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung đánh giá')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final userData = ref.read(userDataProvider).value;
      
      final review = ReviewModel(
        reviewId: '', // Sẽ được tự tạo trong repository
        fromUserId: currentUser.uid,
        courtId: widget.courtId,
        subCourtId: widget.subCourtId,
        bookingId: widget.bookingId,
        ratingScore: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        fromUserName: userData?['full_name'] ?? 'Người dùng',
        fromUserAvatar: userData?['avatar_base64'],
      );

      final repo = ref.read(reviewRepositoryProvider);
      await repo.addCourtReview(review);
      
      // Refresh provider
      ref.invalidate(courtReviewsProvider(widget.subCourtId));

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi đánh giá thành công!'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Đánh giá sân: ${widget.subCourtName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chất lượng sân như thế nào?', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1);
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Nhập đánh giá của bạn về sân...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading 
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Gửi đánh giá', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
