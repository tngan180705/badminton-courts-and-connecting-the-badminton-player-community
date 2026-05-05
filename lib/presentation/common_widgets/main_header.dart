import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/pages/login_screen.dart';

class MainHeader extends StatelessWidget implements PreferredSizeWidget {
  final String userName;

  const MainHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E5CA),
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 10),
      child: Row(
        children: [
          const CircleAvatar(radius: 20, backgroundColor: Color(0xFF9BAB60)),
          const SizedBox(width: 10),
          Expanded(
              child: Text("Chào, $userName!",
                  style: const TextStyle(fontWeight: FontWeight.bold))),

          // Nút Thông báo
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Điều hướng sang trang Thông báo
            },
          ),

          // Nút Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Chuyển về màn hình đăng nhập và xóa toàn bộ lịch sử trang cũ
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
