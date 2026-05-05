// lib/presentation/features/admin/court_management/pages/admin_court_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Thêm import này
import '../providers/admin_court_provider.dart';
import '../widgets/admin_court_card.dart';
import 'add_edit_court_screen.dart';

class AdminCourtListScreen extends ConsumerWidget {
  const AdminCourtListScreen({super.key});

  // Hàm hiển thị hộp thoại xác nhận đăng xuất
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn thoát quyền Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Đóng dialog
              await FirebaseAuth.instance.signOut(); // Thực hiện đăng xuất
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courtsAsync = ref.watch(allCourtsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Quản lý sân cầu lông',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout,
              color: Colors.red), // Thêm nút Logout bên trái hoặc phải
          onPressed: () => _showLogoutDialog(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Colors.black, size: 30),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditCourtScreen()),
            ),
          ),
        ],
      ),
      body: courtsAsync.when(
        data: (courts) {
          if (courts.isEmpty) {
            return const Center(
                child: Text("Chưa có sân nào. Bấm (+) để thêm."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courts.length,
            itemBuilder: (context, index) {
              return AdminCourtCard(court: courts[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}
