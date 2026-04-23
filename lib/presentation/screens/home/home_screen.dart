import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để dùng HapticFeedback
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import '../../../core/constants/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Hàm định dạng tiền tệ: 100000 -> 100.000đ
  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          // Hiển thị trạng thái chờ chuyên nghiệp hơn
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final fullName = userData['full_name'] ?? 'Lông thủ';
          final avatarUrl = userData['avatar_url'] ?? '';
          final balance = (userData['wallet_balance'] ?? 0).toInt();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(fullName, avatarUrl),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPremiumWalletCard(balance),
                      const SizedBox(height: 35),
                      const _SectionHeader(title: "DỊCH VỤ CỦA BẠN"),
                      const SizedBox(height: 18),
                      _buildServiceGrid(),
                      const SizedBox(height: 35),
                      const _SectionHeader(title: "SÂN ĐANG TRỐNG", showViewAll: true),
                      const SizedBox(height: 15),
                      _buildCourtCarousel(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildCustomFAB(),
    );
  }

  // --- COMPONENT: APP BAR ---
  Widget _buildModernAppBar(String name, String avatar) {
    return SliverAppBar(
      expandedHeight: 160.0,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          alignment: Alignment.centerRight,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Opacity(
              opacity: 0.1,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Icon(Icons.sports_tennis, size: 180, color: AppColors.white),
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Row(
          children: [
            _buildAvatar(avatar),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Chào mừng,", style: TextStyle(fontSize: 11, color: AppColors.white.withOpacity(0.7), fontWeight: FontWeight.w400)),
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        _buildActionBtn(Icons.notifications_none_rounded, () {}),
        _buildActionBtn(Icons.logout_rounded, () => FirebaseAuth.instance.signOut()),
        const SizedBox(width: 10),
      ],
    );
  }

  // --- COMPONENT: WALLET ---
  Widget _buildPremiumWalletCard(int balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Số dư khả dụng", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              Icon(Icons.verified_user_rounded, color: AppColors.secondary.withOpacity(0.5), size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(_formatCurrency(balance), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 25),
          Row(
            children: [
              _buildBtn("Nạp tiền", AppColors.primary, AppColors.white, Icons.add_circle_outline, () {}),
              const SizedBox(width: 15),
              _buildBtn("Lịch sử", AppColors.background, AppColors.primary, Icons.history, () {}),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGETS PHỤ TRỢ ---
  Widget _buildAvatar(String url) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.white.withOpacity(0.5), width: 2)),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.inputBorder,
        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
        child: url.isEmpty ? const Icon(Icons.person, color: AppColors.primary, size: 20) : null,
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact(); // Hiệu ứng rung nhẹ iPhone
        onTap();
      },
      icon: Icon(icon, color: AppColors.white, size: 26),
    );
  }

  Widget _buildBtn(String text, Color bg, Color txt, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: txt, size: 18),
              const SizedBox(width: 8),
              Text(text, style: TextStyle(color: txt, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceGrid() {
    final services = [
      {'icon': Icons.map_rounded, 'label': 'Tìm Sân', 'color': AppColors.primary},
      {'icon': Icons.groups_rounded, 'label': 'Tìm Kèo', 'color': AppColors.secondary},
      {'icon': Icons.emoji_events_rounded, 'label': 'Giải Đấu', 'color': Colors.orange},
      {'icon': Icons.more_horiz_rounded, 'label': 'Thêm', 'color': AppColors.textSecondary},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: services.map((s) => _buildServiceItem(s['icon'] as IconData, s['label'] as String, s['color'] as Color)).toList(),
    );
  }

  Widget _buildServiceItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildCourtCarousel() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(30)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: Image.asset(
                    "assets/images/image.png",
                    height: 150, 
                    width: 300, 
                    fit: BoxFit.cover,
                    // Nếu file image.png không tồn tại hoặc lỗi đường dẫn
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: 300,
                        color: AppColors.inputBorder,
                        child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Sân Cầu Lông Đống Đa", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          SizedBox(height: 5),
                          Text("1.2km • Hải Châu, Đà Nẵng", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.3), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomFAB() {
    return FloatingActionButton.extended(
      onPressed: () => HapticFeedback.heavyImpact(),
      backgroundColor: AppColors.primary,
      elevation: 10,
      label: const Text("ĐẶT SÂN NGAY", style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.white, letterSpacing: 1.5)),
      icon: const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 24),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showViewAll;
  const _SectionHeader({required this.title, this.showViewAll = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.5)),
        if (showViewAll)
          Text( "Tất cả", style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}