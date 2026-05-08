import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../common_widgets/main_footer.dart';
import '../../auth/providers/user_provider.dart';
import '../../../common_widgets/main_header.dart';
import '../widgets/profile_info.dart';
import '../widgets/reputation_bar.dart';
import '../widgets/profile_menu_item.dart';
import './edit_profile_screen.dart';
import '../../review/pages/user_reviews_screen.dart';
import '../../auth/pages/login_screen.dart';
import '../../court/pages/home_screen.dart';
import '../../community/pages/community_screen.dart';
import '../../activity/pages/activity_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5CA),
      body: SafeArea(
        child: userAsync.when(
          data: (userData) {
            if (userData == null) return const Center(child: Text('Không tìm thấy thông tin người dùng'));

            final name = userData['full_name'] ?? 'Người dùng';
            final avatar = userData['avatar_base64'];
            final skill = userData['skill_level'] ?? 'Mới bắt đầu';
            final reliabilityScore = (userData['reliability_score'] ?? 100).toDouble();
            final score = reliabilityScore / 100 * 5.0;
            final attendance = reliabilityScore; 
            final wallet = (userData['wallet_balance'] ?? 0).toDouble();

            final statsAsync = ref.watch(userStatsProvider);
            final totalMatches = statsAsync.maybeWhen(
              data: (stats) => stats['totalMatches'] ?? 0,
              orElse: () => 0,
            );

            return Column(
              children: [
                MainHeader(userName: name, avatarBase64: avatar),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'HỒ SƠ CỦA BẠN',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A6136),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ProfileInfo(
                          name: name,
                          skillLevel: skill,
                          avatarBase64: avatar,
                          totalMatches: totalMatches,
                          reliability: score,
                          attendance: attendance,
                        ),
                        const SizedBox(height: 20),
                        ReputationBar(score: score),
                        const SizedBox(height: 30),
                        ProfileMenuItem(
                          icon: Icons.star_border,
                          title: 'Xem đánh giá của bạn',
                          onTap: () {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserReviewsScreen(userId: uid),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        ProfileMenuItem(
                          icon: Icons.settings_outlined,
                          title: 'Chỉnh sửa thông tin',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditProfileScreen(userData: userData)),
                            );
                          },
                        ),
                        ProfileMenuItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'Lịch sử giao dịch',
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.favorite_border,
                          title: 'Sân yêu thích',
                          onTap: () {},
                        ),
                        const SizedBox(height: 20),
                        ProfileMenuItem(
                          icon: Icons.logout,
                          title: 'Đăng xuất',
                          isDestructive: true,
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            ref.invalidate(userDataProvider);
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Lỗi: $err')),
        ),
      ),
      bottomNavigationBar: MainFooter(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CommunityScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ActivityScreen()),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF4A6136),
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
