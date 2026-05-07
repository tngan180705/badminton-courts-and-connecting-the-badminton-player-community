import 'package:badminton_app/presentation/features/court/providers/review_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../common_widgets/main_header.dart';
import '../../../common_widgets/main_footer.dart';
import '../../community/widgets/match_card.dart';
import '../../community/widgets/match_detail_dialog.dart';
import '../../community/providers/community_provider.dart';
import '../../community/pages/community_screen.dart';
import '../../community/pages/match_join_handler.dart';
import '../../auth/providers/user_provider.dart';
import '../../../../data/models/sub_court_model.dart';
import '../../../../data/models/match_post_view_model.dart';
import '../../court/widgets/court_detail_widgets.dart';
import '../providers/user_repository_provider.dart';

class CourtDetailScreen extends ConsumerStatefulWidget {
  final String courtName;
  final SubCourtModel subCourt;

  const CourtDetailScreen({
    super.key,
    required this.courtName,
    required this.subCourt,
  });

  @override
  ConsumerState<CourtDetailScreen> createState() => _CourtDetailScreenState();
}

class _CourtDetailScreenState extends ConsumerState<CourtDetailScreen> {
  bool isFavorite = false;

  void _showMatchDetail(BuildContext context, MatchPostViewModel match) {
    showDialog(
      context: context,
      builder: (context) => MatchDetailDialog(match: match),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDataProvider);
    final postsAsync = ref.watch(communityPostsProvider);

    // ✅ FIX: dùng đúng subCourtId động, không hardcode
    final reviewsAsync =
        ref.watch(userReviewsProvider(widget.subCourt.subCourtId));

    final List<String> courtImages = [
      'assets/images/chitiet.png',
      'assets/images/chitiet1.png',
      'assets/images/chitiet2.png',
      'assets/images/san4.jpg',
    ];

    final userName = userAsync.maybeWhen(
      data: (data) => data?['full_name'] ?? 'Người dùng',
      orElse: () => 'Người dùng',
    );
    final avatarBase64 = userAsync.maybeWhen(
      data: (data) => data?['avatar_base64'],
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5CA),

      appBar: const MainHeader(),


      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề
            CourtHeader(title: 'Chi tiết ${widget.subCourt.subCourtName}'),

            // Ảnh carousel
            CourtImageCarousel(images: courtImages),

            const SizedBox(height: 16),

            // Giá + Yêu thích + Đặt sân
            CourtPricingCard(
              courtName: widget.courtName,
              subCourt: widget.subCourt,
              onFavoriteChanged: (isFav) {
                setState(() {});
              },
            ),

            const SizedBox(height: 16),

            // Khung giờ trống
            AvailableTimeSlotsWidget(
              subCourt: widget.subCourt,
              selectedDate: DateTime.now(),
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(10.73, 106.7),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.badminton.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(10.73, 106.7),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Đánh giá người dùng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // ================= FIX REVIEW =================
            reviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("Chưa có đánh giá nào."),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return _ReviewTile(review: review);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Lỗi tải đánh giá: $e"),
              ),
            ),

            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
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
                final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                // ✅ Lọc: Cùng sân + Còn chỗ + Chưa kết thúc (provider đã lọc thời gian)
                final filteredPosts = allPosts
                    .where((p) => 
                        p.subCourtId == widget.subCourt.subCourtId && 
                        p.status != 'full')
                    .take(4)
                    .toList();

                if (filteredPosts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
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
                      final isMyPost = match.hostId == currentUserId || match.memberIds.contains(currentUserId);
                      
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        margin: const EdgeInsets.only(right: 12),
                        child: MatchCard(
                          match: match,
                          isMyPost: isMyPost,
                          onJoinPressed: !isMyPost 
                              ? () => MatchJoinHandler.handleJoinMatch(context, ref, match)
                              : null,
                          onDetailPressed: isMyPost 
                              ? () => _showMatchDetail(context, match)
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.smart_toy_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: MainFooter(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CommunityScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}

// ================= FIX REVIEW TILE (KHÔNG LƯỢC CODE) =================
class _ReviewTile extends StatelessWidget {
  final dynamic review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final int rating = (review.ratingScore ?? 0);

    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text(review.fromUserId ?? "Người dùng"),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(review.comment ?? ""),
        ],
      ),
    );
  }
}
