import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Thêm để thực hiện Logout

import 'package:badminton_app/presentation/features/auth/providers/user_provider.dart';
import 'package:badminton_app/core/constants/app_colors.dart';
import 'package:badminton_app/core/constants/app_sizes.dart';
import 'package:badminton_app/core/constants/app_text_styles.dart';
import 'package:badminton_app/presentation/features/auth/pages/login_screen.dart';

class MainHeader extends ConsumerWidget implements PreferredSizeWidget {
  const MainHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withOpacity(0.9),
            AppColors.background,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
            vertical: 10,
          ),
          child: userAsync.when(
            data: (data) => _buildBody(
              context, // Truyền context để điều hướng sau khi logout
              data?['full_name'] ?? 'Người dùng',
              data?['avatar_base64'] ?? '',
            ),
            loading: () => _buildBody(context, '...', ''),
            error: (_, __) => _buildBody(context, 'Người dùng', ''),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String name, String avatar) {
    return Row(
      children: [
        // AVATAR
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.inputBorder,
            backgroundImage: avatar.isNotEmpty 
                ? MemoryImage(base64Decode(avatar)) 
                : null,
            child: avatar.isEmpty 
                ? const Icon(Icons.person, color: AppColors.primary, size: 20) 
                : null,
          ),
        ),
        const SizedBox(width: 12),
        // LỜI CHÀO
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Xin chào,",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
              Text(
                name,
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        // --- CÁC ICON CHỨC NĂNG ---
        // Nút Thông báo
        Icon(Icons.notifications_none_rounded, color: AppColors.primary.withOpacity(0.7), size: 22),
        const SizedBox(width: 12),

        // 🛠 NÚT LOGOUT (Đã quay trở lại)
        GestureDetector(
          onTap: () => _handleLogout(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1), // Màu nền đỏ nhạt để báo hiệu
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded, 
              color: AppColors.error, 
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // Hàm xử lý đăng xuất nhanh
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM)),
        title: const Text("Xác nhận"),
        content: const Text("Bạn muốn đăng xuất khỏi ứng dụng?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("HỦY", style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("ĐĂNG XUẤT", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}