import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/court_provider.dart';
import '../widgets/court_card.dart';
import '../../auth/providers/user_provider.dart';

// 1. Provider lấy dữ liệu người dùng từ Firestore
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
    final courtsAsync = ref.watch(allCourtsProvider);
    final userAsync = ref.watch(userDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5CA),
      body: SafeArea(
        child: courtsAsync.when(
          data: (courts) => CustomScrollView(
            slivers: [
              // Header lấy tên thật
              SliverToBoxAdapter(
                child: userAsync.when(
                  data: (data) => _buildUserHeader(
                      context, data?['full_name'] ?? "Người dùng"),
                  loading: () => _buildUserHeader(context, "..."),
                  error: (_, __) => _buildUserHeader(context, "Lỗi tải"),
                ),
              ),

              // Banner 4 ảnh tự động chạy
              SliverToBoxAdapter(child: _buildMainBannerSlider()),

              // Banner Gợi ý Robot
              SliverToBoxAdapter(child: _buildPromotionBanner()),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.spaceMedium),
                  child: Center(
                      child: Text("DANH SÁCH SÂN",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ),

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
      bottomNavigationBar: BottomAppBar(
        height: 65, // Chiều cao vừa đủ để icon không bị sát mép
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Colors.white, // Đảm bảo nền trắng để nút Robot xanh nổi bật lên
        elevation: 10, // Tạo đổ bóng nhẹ bên dưới
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Trang chủ", true),
            _buildNavItem(Icons.people_alt_outlined, "Ghép nhóm", false),
            const SizedBox(width: 40), // Chừa khe hở cho nút Robot lặn xuống
            _buildNavItem(Icons.calendar_month_outlined, "Hoạt động", false),
            _buildNavItem(Icons.person_outline, "Hồ sơ", false),
          ],
        ),
      ),
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

  // --- CÁC HÀM BỔ TRỢ (WIDGETS) ---

  Widget _buildUserHeader(BuildContext context, String name) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundColor: Color(0xFF9BAB60)),
          const SizedBox(width: 12),
          Text("Chào, $name!",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
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
        height: 240.0, // Chiều cao banner
        autoPlay: true, // Tự động chạy
        autoPlayInterval: const Duration(seconds: 4),
        viewportFraction: 0.9, // Độ rộng của mỗi ảnh so với màn hình
        enlargeCenterPage: true, // Hiệu ứng phóng to ảnh ở giữa
      ),
      items: imgList.map((imgPath) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                // Bo góc cho hình ảnh
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  imgPath, // HIỂN THỊ ẢNH THẬT
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 220.0,
                  // Xử lý khi không tìm thấy file ảnh
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
        color: const Color(0xFFD4D984).withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_outlined, color: Colors.black54),
          const SizedBox(width: 10),
          const Expanded(
            child: Text("Thứ 3 rồi, đặt sân số 2 lúc 18h nhé?",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B8E4E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Đặt ngay",
                style: TextStyle(color: Colors.white, fontSize: 12)),
          )
        ],
      ),
    );
  }

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
