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
import '../../activity/pages/activity_screen.dart';



class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subCourtsAsync = ref.watch(homeSubCourtsProvider);
    final courtAsync = ref.watch(singleCourtProvider);
    final userAsync = ref.watch(userDataProvider);

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
              /// HEADER
              SliverToBoxAdapter(
                child: userAsync.when(
                  data: (data) =>
                      MainHeader(
  userName: data?['full_name'] ?? 'Người dùng',
  avatarBase64: data?['avatar_base64'],
),
                  loading: () => const MainHeader(userName: '...'),
                  error: (_, __) =>
                      const MainHeader(userName: 'Người dùng'),
                ),
              ),

              /// BANNER
              SliverToBoxAdapter(child: _buildMainBannerSlider()),

              /// PROMO
              SliverToBoxAdapter(child: _buildPromotionBanner()),

              /// TITLE
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.spaceMedium,
                    horizontal: AppSizes.screenPadding,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'DANH SÁCH SÂN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (courtName.isNotEmpty)
                        Text(
                          courtName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              /// GRID
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSizes.spaceMedium,
                    crossAxisSpacing: AppSizes.spaceMedium,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return CourtCard(
                        subCourt: subCourts[index],
                        courtName: courtName,
                        onTap: () {
                          final court = courtAsync.value;

                          if (court == null) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourtDetailScreen(
                                courtName: court.name, // ✅ FIXED
                                subCourt: subCourts[index],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: subCourts.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Lỗi: $err')),
        ),
      ),

      bottomNavigationBar: MainFooter(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ActivityScreen(),
              ),
            );
          }
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
    );
  }

  /// ================= BANNER =================
  Widget _buildMainBannerSlider() {
    final List<String> imgList = [
      'assets/images/banner1.jpg',
      'assets/images/banner2.jpg',
      'assets/images/banner3.jpg',
      'assets/images/banner4.jpg',
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 240,
        autoPlay: true,
        viewportFraction: 0.9,
        enlargeCenterPage: true,
      ),
      items: imgList.map((imgPath) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            imgPath,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        );
      }).toList(),
    );
  }

  /// ================= PROMO =================
  Widget _buildPromotionBanner() {
    return Container(
      margin: const EdgeInsets.all(AppSizes.screenPadding),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          Icon(Icons.smart_toy_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('Thứ 3 rồi, đặt sân số 2 lúc 18h nhé?')),
        ],
      ),
    );
  }
}