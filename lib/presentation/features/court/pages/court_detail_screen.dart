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
import '../../community/providers/community_provider.dart';
import '../../community/pages/community_screen.dart';
import '../../auth/providers/user_provider.dart';
import '../../../../data/models/sub_court_model.dart';
import '../../../../data/models/match_post_view_model.dart';

// ✅ FIX: giữ import nhưng đảm bảo tồn tại file
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

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5CA),
      appBar: MainHeader(userName: userName),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chi tiết ${widget.subCourt.subCourtName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF407F3E),
                ),
              ),
            ),

            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: courtImages.length,
                itemBuilder: (context, index) => Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: AssetImage(courtImages[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    '${widget.courtName} - ${widget.subCourt.subCourtName}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        debugPrint("Đặt sân ${widget.subCourt.subCourtName}");
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: const Text("Đặt sân ngay"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF407F3E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      IconButton(
                        onPressed: () {
                          setState(() {
                            isFavorite = !isFavorite;
                          });
                        },
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.red,
                        ),
                      ),

                      const Row(
                        children: [
                          Icon(Icons.payments_outlined,
                              color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '150.000đ / giờ',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
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

            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Khung giờ trống',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(8, (index) {
                  final hour = 8 + index;
                  final isBooked = index == 2 || index == 5;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.grey.shade300
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$hour:00",
                      style: TextStyle(
                        color: isBooked
                            ? Colors.grey
                            : Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ),
            ),

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
  urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
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
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
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
                final filteredPosts = allPosts
                    .where((p) =>
                        p.subCourtName ==
                        widget.subCourt.subCourtName)
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final match = filteredPosts[index];
                      return Container(
                        width:
                            MediaQuery.of(context).size.width * 0.85,
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Lỗi: $err')),
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

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: MainFooter(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CommunityScreen(),
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
                index < rating
                    ? Icons.star
                    : Icons.star_border,
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