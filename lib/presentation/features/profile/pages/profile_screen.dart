import 'dart:convert';
import 'package:badminton_app/presentation/features/activity/pages/activity_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../activity/pages/activity_screen.dart';
// Import Constants & Styles
import 'package:badminton_app/core/constants/app_colors.dart';
import 'package:badminton_app/core/constants/app_sizes.dart';
import 'package:badminton_app/core/constants/app_strings.dart';
import 'package:badminton_app/core/constants/app_text_styles.dart';

// Import Models & Providers
import 'package:badminton_app/data/models/user_model.dart';
import 'package:badminton_app/presentation/features/auth/providers/user_provider.dart'; // Đảm bảo đúng đường dẫn userDataProvider

// Import Screens
import 'package:badminton_app/presentation/features/profile/pages/edit_profile_screen.dart';
import 'package:badminton_app/presentation/common_widgets/main_footer.dart';
import 'package:badminton_app/presentation/common_widgets/main_header.dart';
import 'package:badminton_app/presentation/features/court/pages/home_screen.dart';
import 'package:badminton_app/presentation/features/community/pages/community_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🛠 Lắng nghe Stream dữ liệu từ Firestore qua Provider
    final userAsync = ref.watch(userDataProvider);

    return userAsync.when(
      data: (rawData) {
        if (rawData == null) {
          return const Scaffold(body: Center(child: Text("Không tìm thấy thông tin người dùng")));
        }

        // 🛠 Lấy ID từ key 'id' đã được gán thủ công trong Provider
        final String userId = rawData['id']?.toString() ?? "";
        final user = UserModel.fromFirestore(rawData, userId);

        // Debug để kiểm tra ID đã có giá trị chưa (Ví dụ: tqIHiHXw...)
        debugPrint("--- ProfileScreen: Rebuild với ID: ${user.userId} ---");

        // Tính toán chỉ số uy tín (Giả sử 100 điểm tương ứng 5 sao)
        final safeScore = (user.reliabilityScore / 20).clamp(0.0, 5.0);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const MainHeader(),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
            child: Column(
              children: [
                AppSizes.hLarge,
                Text(
                  AppStrings.profileTitle,
                  style: AppTextStyles.heading2.copyWith(fontSize: 22),
                ),
                AppSizes.hLarge,

                // --- INFO CARD ---
                _buildInfoCard(user),

                AppSizes.hLarge,
                _buildReputationSection(safeScore),
                
                AppSizes.hLarge,
                _buildWalletCard(user.walletBalance),
                
                AppSizes.hLarge,

                // --- MENU LIST ---
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        Icons.person_outline_rounded,
                        AppStrings.editInfo,
                        isFirst: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(user: user),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        Icons.history_rounded,
                        AppStrings.transactionHistory,
                        onTap: () { /* Điều hướng */ },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        Icons.favorite_outline_rounded,
                        AppStrings.favoriteCourts,
                        isLast: true,
                        onTap: () { /* Điều hướng */ },
                      ),
                    ],
                  ),
                ),

                AppSizes.hLarge,
                _buildLogoutButton(),
                const SizedBox(height: 120),
              ],
            ),
          ),
          floatingActionButton: _buildFAB(),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text("Lỗi tải dữ liệu: $e")),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildInfoCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
      ),
      child: Row(
        children: [
          _buildBigAvatar(user.avatarBase64),
          AppSizes.wMedium,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.toUpperCase(),
                  style: AppTextStyles.heading2.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Text(
                    "Trình độ: ${user.skillLevel}",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBigAvatar(String base64) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: AppColors.inputBorder,
        backgroundImage: base64.isNotEmpty ? MemoryImage(base64Decode(base64)) : null,
        child: base64.isEmpty ? const Icon(Icons.person, size: 40, color: AppColors.white) : null,
      ),
    );
  }

  Widget _buildWalletCard(double balance) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Số dư ví", style: TextStyle(color: AppColors.white.withOpacity(0.8), fontSize: 13)),
              const SizedBox(height: 5),
              Text(format.format(balance), style: const TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: AppColors.primary),
            child: const Text(AppStrings.deposit),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isFirst = false, bool isLast = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(AppSizes.radiusXL) : Radius.zero,
          bottom: isLast ? const Radius.circular(AppSizes.radiusXL) : Radius.zero,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 50, endIndent: 20, color: AppColors.background);

  Widget _buildLogoutButton() {
    return TextButton.icon(
      onPressed: () { /* Logic Sign Out */ },
      icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
      label: const Text(AppStrings.logout, style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {},
      backgroundColor: AppColors.primary,
      shape: const CircleBorder(),
      child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 30),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
  return MainFooter(
    currentIndex: 3,
    onTap: (index) {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }

      if (index == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CommunityScreen(),
          ),
        );
      }
      if (index == 2) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const ActivityScreen(),
    ),
  );
}

      if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ActivityScreen(),
          ),
        );
      }
    },
  );
}

  Widget _buildReputationSection(double score) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text("Chỉ số uy tín", style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text("${score.toStringAsFixed(1)} / 5.0", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 10),
        _buildReputationBar(score),
      ],
    );
  }

  Widget _buildReputationBar(double score) {
    return LayoutBuilder(builder: (context, constraints) {
      final safeScore = score.clamp(0.0, 5.0);
      double position = (safeScore / 5.0) * constraints.maxWidth;
      position = position.clamp(10.0, constraints.maxWidth - 20);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 10,
            margin: const EdgeInsets.only(top: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              gradient: const LinearGradient(colors: [AppColors.error, AppColors.accent, AppColors.primary]),
            ),
          ),
          Positioned(left: position - 8, top: -5, child: const Icon(Icons.arrow_drop_down, size: 28)),
        ],
      );
    });
  }
}