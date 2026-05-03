import 'package:badminton_app/presentation/features/auth/providers/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/court_provider.dart';
import '../widgets/court_card.dart';
import '../../auth/providers/user_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courtsAsync = ref.watch(allCourtsProvider);
    final userAsync = ref.watch(userDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5CA),
      body: SafeArea(
        child: courtsAsync.when(
          data: (courts) => CustomScrollView(
            slivers: [
              /// ✅ HEADER
              SliverToBoxAdapter(
                child: userAsync.when(
                  data: (data) => _buildUserHeader(
                      context, ref, data?['full_name'] ?? "Người dùng"),
                  loading: () => _buildUserHeader(context, ref, "..."),
                  error: (_, __) => _buildUserHeader(context, ref, "Lỗi tải"),
                ),
              ),

              /// ✅ BANNER
              SliverToBoxAdapter(child: _buildMainBannerSlider()),

              /// ✅ PROMOTION
              SliverToBoxAdapter(child: _buildPromotionBanner()),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.spaceMedium),
                  child: Center(
                    child: Text(
                      "DANH SÁCH SÂN",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              /// ✅ GRID
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
                    (context, index) => CourtCard(court: courts[index]),
                    childCount: courts.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Lỗi: $err")),
        ),
      ),

      /// ✅ BOTTOM NAV
      bottomNavigationBar: BottomAppBar(
        height: 65,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Colors.white,
        elevation: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Trang chủ", true),
            _buildNavItem(Icons.people_alt_outlined, "Ghép nhóm", false),
            const SizedBox(width: 40),
            _buildNavItem(Icons.calendar_month_outlined, "Hoạt động", false),
            _buildNavItem(Icons.person_outline, "Hồ sơ", false),
          ],
        ),
      ),

      /// ✅ FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF6B8E4E),
        elevation: 2,
        child:
            const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ================= HEADER =================
  Widget _buildUserHeader(BuildContext context, WidgetRef ref, String name) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF9BAB60),
          ),
          const SizedBox(width: 12),

          Text(
            "Chào, $name!",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const Spacer(),

          /// 🔥 LOGOUT BUTTON
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn muốn thoát khỏi ứng dụng?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Ở lại'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        try {
                          await ref.read(authControllerProvider).logout();
                          // ✅ Không cần Navigator → MyApp sẽ tự rebuild
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Logout lỗi: $e")),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Thoát',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= BANNER =================
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            imgPath,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= PROMO =================
  Widget _buildPromotionBanner() {
    return Container(
      margin: const EdgeInsets.all(AppSizes.screenPadding),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4D984).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_outlined),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Thứ 3 rồi, đặt sân số 2 lúc 18h nhé?",
              style: TextStyle(fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Đặt ngay"),
          )
        ],
      ),
    );
  }

  // ================= NAV =================
  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? Colors.green : Colors.black54),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: isActive ? Colors.green : Colors.black54)),
      ],
    );
  }
}
