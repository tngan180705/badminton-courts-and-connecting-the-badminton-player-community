import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/review_provider.dart';
import '../widgets/review_tile.dart';

class UserReviewsScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserReviewsScreen({super.key, required this.userId});

  @override
  ConsumerState<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends ConsumerState<UserReviewsScreen> {
  int? _selectedStarFilter;

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(userProfileReviewsProvider(widget.userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Đánh giá của bạn'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lọc theo:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedStarFilter,
                      hint: const Text('Tất cả sao', style: TextStyle(fontSize: 14)),
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tất cả')),
                        const DropdownMenuItem(value: 5, child: Text('5 Sao')),
                        const DropdownMenuItem(value: 4, child: Text('4 Sao')),
                        const DropdownMenuItem(value: 3, child: Text('3 Sao')),
                        const DropdownMenuItem(value: 2, child: Text('2 Sao')),
                        const DropdownMenuItem(value: 1, child: Text('1 Sao')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedStarFilter = val;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reviewsAsync.when(
              data: (reviews) {
                final filteredReviews = _selectedStarFilter == null
                    ? reviews
                    : reviews.where((r) => r.ratingScore == _selectedStarFilter).toList();

                if (filteredReviews.isEmpty) {
                  return const Center(
                    child: Text(
                      "Chưa có đánh giá nào phù hợp.",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReviews.length,
                  itemBuilder: (context, index) {
                    return ReviewTile(review: filteredReviews[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Lỗi: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
