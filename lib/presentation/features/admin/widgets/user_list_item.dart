import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import './user_detail_bottom_sheet.dart';

class UserListItem extends ConsumerWidget {
  final Map<String, dynamic> userData;

  const UserListItem({super.key, required this.userData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final isLocked = userData['is_locked'] ?? false;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isSelf = userData['firebase_uid'] == currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFE5E5CA),
                  backgroundImage: (userData['avatar_base64'] != null && userData['avatar_base64'].toString().isNotEmpty)
                      ? MemoryImage(base64Decode(userData['avatar_base64']))
                      : null,
                  child: (userData['avatar_base64'] == null || userData['avatar_base64'].toString().isEmpty)
                      ? Text(
                          (userData['full_name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A6136)),
                        )
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['full_name'] ?? 'N/A',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userData['email'] ?? 'N/A',
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBadge(userData['role']?.toString().toUpperCase() ?? 'PLAYER', const Color(0xFFE8F5E9), const Color(0xFF4A6136)),
                          const SizedBox(width: 8),
                          _buildBadge(userData['skill_level'] ?? 'Mới bắt đầu', const Color(0xFFFFF9C4), const Color(0xFFFBC02D)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _buildActionButton(
                      context,
                      isLocked ? 'Mở khoá' : 'Khoá',
                      isLocked ? Colors.green : Colors.red,
                      Icons.lock_outline,
                      isSelf ? null : () => _toggleLock(context, isLocked),
                    ),
                    const SizedBox(height: 10),
                    _buildActionButton(
                      context,
                      'Phân quyền',
                      const Color(0xFF4A6136),
                      Icons.settings_suggest_outlined,
                      () => _promoteUser(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Bottom Stats Row
          InkWell(
            onTap: () => _showUserDetails(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F0),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomStat(Icons.phone, userData['phone'] ?? 'N/A'),
                  _buildBottomStat(Icons.wallet, '${currencyFormatter.format(userData['wallet_balance'] ?? 0)}đ'),
                  _buildBottomStat(Icons.star, '${userData['reliability_score'] ?? 100}%'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, Color color, IconData icon, VoidCallback? onTap) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(isDisabled ? 0.05 : 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(isDisabled ? 0.1 : 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color.withOpacity(isDisabled ? 0.3 : 1.0)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(isDisabled ? 0.3 : 1.0), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4A6136)),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _toggleLock(BuildContext context, bool currentStatus) async {
    final db = FirebaseFirestore.instance;
    try {
      await db.collection('users').doc(userData['id']).update({
        'is_locked': !currentStatus,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(currentStatus ? 'Đã mở khoá tài khoản' : 'Đã khoá tài khoản')),
        );
      }
    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _promoteUser(BuildContext context) async {
    final currentRole = userData['role'] ?? 'player';
    final newRole = currentRole == 'admin' ? 'player' : 'admin';
    
    final db = FirebaseFirestore.instance;
    try {
      await db.collection('users').doc(userData['id']).update({
        'role': newRole,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đổi vai trò sang $newRole')),
        );
      }
    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showUserDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailBottomSheet(userData: userData),
    );
  }
}
