import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/court_provider.dart';
import '../widgets/court_card.dart';
import '../pages/court_detail_screen.dart';
import '../../auth/providers/user_provider.dart';
import '../../../common_widgets/main_header.dart';
import '../../../common_widgets/main_footer.dart';
import '../../../features/community/pages/community_screen.dart';

final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) => snapshot.data());
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subCourtsAsync = ref.watch(homeSubCourtsProvider);
    final courtAsync = ref.watch(singleCourtProvider);
    final userAsync = ref.watch(userDataProvider);

    // Lấy tên cửa hàng để truyền vào CourtCard
    final courtName = courtAsync.maybeWhen(
      data: (court) => court?.name ?? '',
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: subCourtsAsync.when(
          data: (subCourts) => CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: userAsync.when(
                  data: (data) =>
                      MainHeader(userName: data?['full_name'] ?? 'Người dùng'),
                  loading: () => const MainHeader(userName: '...'),
                  error: (_, __) => const MainHeader(userName: 'Người dùng'),
                ),
              ),

              // Banner slider
              SliverToBoxAdapter(child: _buildMainBannerSlider()),

              // Banner gợi ý AI
              SliverToBoxAdapter(child: _buildPromotionBanner()),

              // Tiêu đề + tên cửa hàng
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.spaceMedium,
                      horizontal: AppSizes.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'DANH SÁCH SÂN',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (courtName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            courtName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Grid sub_courts
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSizes.spaceMedium,
                    crossAxisSpacing: AppSizes.spaceMedium,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => CourtCard(
                      subCourt: subCourts[index],
                      courtName: courtName,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourtDetailScreen(
                              subCourt: subCourts[index],
                              courtName: courtName,
                            ),
                          ),
                        );
                      },
                    ),
                    childCount: subCourts.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Lỗi: $err')),
        ),
      ),
      bottomNavigationBar: MainFooter(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CommunityScreen()),
            );
          }
        },
      ),
      // 👇 BẮT BUỘC PHẢI CÓ
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: AI sau
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildMainBannerSlider() {
    final List<String> imgList = [
      'assets/images/banner1.jpg',
      'assets/images/banner2.jpg',
      'assets/images/banner3.jpg',
      'assets/images/banner4.jpg',
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 240.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        viewportFraction: 0.9,
        enlargeCenterPage: true,
      ),
      items: imgList.map((imgPath) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: double.infinity,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  imgPath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 220.0,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey, size: 50),
                    );
                  },
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildPromotionBanner() {
    return Container(
      margin: const EdgeInsets.all(AppSizes.screenPadding),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_outlined, color: Colors.black54),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Thứ 3 rồi, đặt sân số 2 lúc 18h nhé?',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Đặt ngay',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
