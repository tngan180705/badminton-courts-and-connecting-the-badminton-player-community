import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/community_provider.dart';

class CommunityTabBar extends StatelessWidget {
  final int currentTab;
  final Function(int) onTabChanged;
  final VoidCallback onPostPress;

  const CommunityTabBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    required this.onPostPress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTab(context, 0, 'Tất cả trận'),
        _buildTab(context, 1, 'Trận của tôi'),
        _buildTab(context, 2, '+ Đăng tin mới'),
      ],
    );
  }

  Widget _buildTab(BuildContext context, int index, String label) {
    final isSelected = currentTab == index;

    final bgColor = index == 2
        ? const Color(0xFFDBD46B)
        : (isSelected ? const Color(0xFF407F3E) : Colors.white);

    final textColor = index == 2
        ? Colors.black87
        : (isSelected ? Colors.white : Colors.black54);

    final borderColor = index == 2
        ? const Color(0xFFDBD46B)
        : (isSelected ? const Color(0xFF407F3E) : Colors.grey[300]!);

    return GestureDetector(
      onTap: () {
        if (index == 2) {
          onPostPress();
          return;
        }
        onTabChanged(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
