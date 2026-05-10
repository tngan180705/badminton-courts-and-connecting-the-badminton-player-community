import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/pages/login_screen.dart';
import './admin_dashboard_screen.dart';
import './admin_user_management_screen.dart';
import './admin_transaction_approval_screen.dart';
import './admin_booking_management_screen.dart';
import './admin_booking_screen.dart';

final adminMenuIndexProvider = StateProvider<int>((ref) => 0);

class AdminMainScreen extends ConsumerWidget {
  const AdminMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(adminMenuIndexProvider);
    final userAsync = ref.watch(userDataProvider);

    final List<Widget> pages = [
      const AdminDashboardScreen(),
      const AdminUserManagementScreen(),
      const AdminBookingScreen(),
      const AdminBookingManagementScreen(),
      const AdminTransactionApprovalScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5CA),
      appBar: AppBar(
        title: Text(
          _getTitle(currentIndex),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4A6136),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context, ref, userAsync),
      body: pages[currentIndex],
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return 'Bảng điều khiển';
      case 1: return 'Người dùng';
      case 2: return 'Sân cầu lông';
      case 3: return 'Đặt lịch';
      case 4: return 'Giao dịch';
      default: return 'Quản trị';
    }
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, AsyncValue<Map<String, dynamic>?> userAsync) {
    final currentIndex = ref.watch(adminMenuIndexProvider);

    return Drawer(
      backgroundColor: const Color(0xFF4A6136),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DF92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Color(0xFF4A6136), size: 30),
                ),
                const SizedBox(width: 15),
                const Text(
                  'QUẢN TRỊ VIÊN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildMenuItem(context, ref, Icons.dashboard_outlined, 'Bảng điều khiển', 0, currentIndex),
          _buildMenuItem(context, ref, Icons.people_outline, 'Người dùng', 1, currentIndex),
          _buildMenuItem(context, ref, Icons.sports_tennis_outlined, 'Sân cầu lông', 2, currentIndex),
          _buildMenuItem(context, ref, Icons.receipt_long_outlined, 'Đặt lịch', 3, currentIndex),
          _buildMenuItem(context, ref, Icons.account_balance_wallet_outlined, 'Giao dịch', 4, currentIndex),
          
          const Spacer(),
          
          // User profile section at bottom
          userAsync.when(
            data: (userData) => Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white.withOpacity(0.1),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFFD9DF92),
                    child: Icon(Icons.person, color: Color(0xFF4A6136)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userData?['full_name'] ?? 'Administrator',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'System Manager',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      ref.invalidate(userDataProvider);
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
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, WidgetRef ref, IconData icon, String title, int index, int currentIndex) {
    final isSelected = index == currentIndex;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          ref.read(adminMenuIndexProvider.notifier).state = index;
          // Close drawer
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD9DF92) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF4A6136) : Colors.white,
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF4A6136) : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
