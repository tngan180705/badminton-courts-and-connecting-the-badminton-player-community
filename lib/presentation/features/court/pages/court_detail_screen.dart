import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../common_widgets/main_header.dart';
import '../../../common_widgets/main_footer.dart';
import '../../community/widgets/match_card.dart';
import '../../community/providers/community_provider.dart';
import '../../community/pages/community_screen.dart';
import '../../auth/providers/user_provider.dart';
import '../../../../data/models/sub_court_model.dart';
import '../../../../data/models/match_post_view_model.dart';

class CourtDetailScreen extends ConsumerWidget {
  final String courtName; // Tên sân lớn (ví dụ: Sân Cầu Lông NBC)
  final SubCourtModel subCourt; // Object sân con

  const CourtDetailScreen({
    super.key,
    required this.courtName,
    required this.subCourt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);
    final postsAsync = ref.watch(communityPostsProvider);

    final userName = userAsync.maybeWhen(
      data: (data) => data?['full_name'] ?? 'Người dùng',
      orElse: () => 'Người dùng',
    );

    return Scaffold(
      backgroundColor:
          const Color(0xFFE5E5CA), // Màu nền đồng bộ CommunityScreen
      appBar: MainHeader(userName: userName),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tiêu đề trang
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Chi tiết ${subCourt.subCourtName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF407F3E),
                ),
              ),
            ),

            // 2. Hình ảnh chi tiết sân (3-4 ảnh)
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                itemBuilder: (context, index) => Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage(
                          'https://VNASports.vn/uploads/tiny/tin-tuc/kich-thuoc-san-cau-long.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            // 3. Tên sân & Thông tin giá tiền
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$courtName - ${subCourt.subCourtName}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.payments_outlined,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Giá thuê: 150.000đ / giờ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔥 Giờ vàng (5h-7h & 20h-22h): Chỉ 40.000đ/giờ',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Mô tả cơ bản
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Mô tả:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'Sân đạt tiêu chuẩn thi đấu, thảm chuyên dụng chống trơn trượt. Hệ thống đèn chiếu sáng hiện đại, không gây lóa mắt. Sân thường rất đông vào khung giờ tối từ 18h - 20h.',
                style:
                    TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ),

            // 5. Đánh giá sân (Rating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Đánh giá: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List.generate(
                      4,
                      (index) => const Icon(Icons.star,
                          color: Colors.amber, size: 20)),
                  const Icon(Icons.star_half, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Text('4.5 (120 lượt đánh giá)',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1, height: 1),

            // 6. Các trận ghép (Lướt ngang - Đã sửa theo ảnh của bạn)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'CÁC TRẬN GHÉP TẠI SÂN NÀY',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF407F3E),
                ),
              ),
            ),

            postsAsync.when(
              data: (allPosts) {
                final filteredPosts = allPosts
                    .where((p) => p.subCourtName == subCourt.subCourtName)
                    .take(4)
                    .toList();

                if (filteredPosts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('Chưa có trận ghép nào.')),
                  );
                }

                return SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final match = filteredPosts[index];
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        margin: const EdgeInsets.only(right: 12),
                        child: MatchCard(
                          match: match,
                          onJoinPressed: () {},
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
            ),

            const SizedBox(height: 120), // Khoảng trống cho FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Tích hợp AI Chat ở đây
          debugPrint("Mở AI Chat");
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: MainFooter(
        currentIndex: 0, // Đang ở chi tiết sân nên có thể coi là nhánh của Home
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context); // Quay về trang chủ
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CommunityScreen()),
            );
          }
        },
      ),
    );
  }
}
