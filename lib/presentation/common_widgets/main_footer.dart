import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MainFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MainFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(), // 👈 tạo notch
      notchMargin: 6,
      height: 65,
      color: Colors.white,
      elevation: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, "Trang chủ", 0),
          _buildNavItem(Icons.people_alt_outlined, "Ghép nhóm", 1),
          const SizedBox(width: 40), // 👈 chừa chỗ cho FAB
          _buildNavItem(Icons.calendar_month_outlined, "Hoạt động", 2),
          _buildNavItem(Icons.person_outline, "Hồ sơ", 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppColors.primary : Colors.black54),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppColors.primary : Colors.black54,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
