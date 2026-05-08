import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: isDestructive ? Colors.redAccent : const Color(0xFF4A6136),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDestructive ? Colors.redAccent : Colors.black87,
            ),
          ),
          trailing: isDestructive 
            ? null 
            : const Icon(Icons.chevron_right, color: Colors.grey),
          contentPadding: EdgeInsets.zero,
        ),
        if (!isDestructive) const Divider(height: 1),
      ],
    );
  }
}
