import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/match_post_view_model.dart';

class MatchDetailDialog extends StatelessWidget {
  final MatchPostViewModel match;

  const MatchDetailDialog({super.key, required this.match});
  double _calculateActualPrice() {
    final start = int.parse(match.startTime.split(':')[0]);
    final end = int.parse(match.endTime.split(':')[0]);
    final endMin = int.parse(match.endTime.split(':')[1]);

    double totalPrice = 0;

    for (int h = start; h < end; h++) {
      if ((h >= 5 && h < 7) || (h >= 20 && h < 22)) {
        totalPrice += 40000;
      } else {
        totalPrice += 150000;
      }
    }

    if (endMin > 0) {
      final lastHour = end;
      final pricePerHour =
          (lastHour >= 5 && lastHour < 7) || (lastHour >= 20 && lastHour < 22)
              ? 40000
              : 150000;
      totalPrice += (endMin / 60) * pricePerHour;
    }

    return totalPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chi tiết trận đấu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Sân
              _buildDetailRow(
                icon: Icons.location_on,
                label: 'Sân:',
                value: '${match.courtName} - ${match.subCourtName}',
              ),
              const SizedBox(height: 12),

              // Ngày
              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Ngày:',
                value: DateFormat('dd/MM/yyyy').format(match.bookingDate),
              ),
              const SizedBox(height: 12),

              // Thời gian
              _buildDetailRow(
                icon: Icons.access_time_outlined,
                label: 'Thời gian:',
                value: '${match.startTime} - ${match.endTime}',
              ),
              const SizedBox(height: 12),

              // Trình độ
              _buildDetailRow(
                icon: Icons.bar_chart_outlined,
                label: 'Trình độ:',
                value: match.skillLevel,
              ),
              const SizedBox(height: 12),

              // Số người
              _buildDetailRow(
                icon: Icons.people_outline,
                label: 'Số người:',
                value: 'Còn thiếu ${match.slotsNeeded} người',
                valueColor: AppColors.error,
              ),
              const SizedBox(height: 12),

              // Giá tiền
              _buildDetailRow(
                icon: Icons.attach_money_outlined,
                label: 'Giá:',
                value: '${_calculatePrice(match.startTime, match.endTime)}đ',
              ),
              const SizedBox(height: 20),

              // Thành viên
              const Text(
                'Thành viên:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _MembersList(match: match),
              const SizedBox(height: 20),

              // Nút đóng
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = AppColors.textPrimary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculatePrice(String startTime, String endTime) {
    try {
      final start = int.parse(startTime.split(':')[0]);
      final end = int.parse(endTime.split(':')[0]);
      final startMin = int.parse(startTime.split(':')[1]);
      final endMin = int.parse(endTime.split(':')[1]);

      double hours = (end - start).toDouble();
      if (endMin > startMin) {
        hours += (endMin - startMin) / 60;
      } else if (endMin < startMin) {
        hours += (60 - (startMin - endMin)) / 60;
      }

      final price = (hours * 150000).toInt();
      return price.toString();
    } catch (e) {
      return '150000';
    }
  }
}

class _MembersList extends StatelessWidget {
  final MatchPostViewModel match;

  const _MembersList({required this.match});
  double _scoreToRating(double score) {
    return (score / 100) * 5;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Chưa có thành viên');
        }

        final members = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return GestureDetector(
              onTap: () => _showUserProfile(context, member),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.secondary.withOpacity(0.3),
                      backgroundImage: member['avatarUrl'] != null &&
                              member['avatarUrl'].toString().isNotEmpty
                          ? NetworkImage(member['avatarUrl'])
                          : null,
                      child: member['avatarUrl'] == null ||
                              member['avatarUrl'].toString().isEmpty
                          ? const Icon(Icons.person,
                              color: AppColors.secondary, size: 24)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['full_name'] ?? 'Người dùng',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (member['isHost'] ?? false)
                            const Text(
                              'Host',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                        ],
                      ),
                    ),
                    if (member['rating'] != null)
                      Row(
                        children: [
                          Text(
                            member['rating'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    final db = FirebaseFirestore.instance;
    final members = <Map<String, dynamic>>[];

    try {
      // 👇 Lấy host theo firebase_uid
      final hostSnapshot = await db
          .collection('users')
          .where('firebase_uid', isEqualTo: match.hostId)
          .limit(1)
          .get();

      if (hostSnapshot.docs.isNotEmpty) {
        final hostData = hostSnapshot.docs.first.data();
        members.add({
          'userId': match.hostId,
          'full_name': hostData['full_name'] ?? 'Người dùng',
          'phone': hostData['phone'] ?? '',
          'skill_level': hostData['skill_level'] ?? '',
          'reliability_score': hostData['reliability_score'] ?? 0,
          'avatarUrl': hostData['avatar_url'] ?? '',
          'rating':
              _scoreToRating(hostData['reliability_score']?.toDouble() ?? 100.0)
                  .toStringAsFixed(1),
          'isHost': true,
        });
      }

      // Lấy members join
      final membersSnapshot = await db
          .collection('match_members')
          .where('match_post_id', isEqualTo: match.matchPostId)
          .get();

      for (final memberDoc in membersSnapshot.docs) {
        final userId = memberDoc['user_id'];

        // 👇 Query theo firebase_uid
        final userSnapshot = await db
            .collection('users')
            .where('firebase_uid', isEqualTo: userId)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          final userData = userSnapshot.docs.first.data();
          members.add({
            'userId': userId,
            'full_name': userData['full_name'] ?? 'Người dùng',
            'phone': userData['phone'] ?? '',
            'skill_level': userData['skill_level'] ?? '',
            'reliability_score': userData['reliability_score'] ?? 0,
            'avatarUrl': userData['avatar_url'] ?? '',
            'rating': _scoreToRating(
                    userData['reliability_score']?.toDouble() ?? 100.0)
                .toStringAsFixed(1),
            'isHost': false,
          });
        }
      }

      print('✅ Fetched ${members.length} members');
    } catch (e) {
      print('❌ Error fetching members: $e');
    }

    return members;
  }

  void _showUserProfile(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => UserProfileDialog(user: user),
    );
  }
}

class UserProfileDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserProfileDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar + Tên
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.secondary.withOpacity(0.3),
                    backgroundImage: user['avatarUrl'] != null &&
                            user['avatarUrl'].toString().isNotEmpty
                        ? NetworkImage(user['avatarUrl'])
                        : null,
                    child: user['avatarUrl'] == null ||
                            user['avatarUrl'].toString().isEmpty
                        ? const Icon(Icons.person,
                            color: AppColors.secondary, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user['full_name'] ?? 'Người dùng',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Số điện thoại
            _buildProfileRow(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại:',
              value: user['phone'] ?? 'Chưa cập nhật',
            ),
            const SizedBox(height: 12),

            // Trình độ
            _buildProfileRow(
              icon: Icons.bar_chart_outlined,
              label: 'Trình độ:',
              value: user['skill_level'] ?? 'Chưa cập nhật',
            ),
            const SizedBox(height: 12),

            // Số sao
            _buildProfileRow(
              icon: Icons.star_outlined,
              label: 'Đánh giá:',
              value: '${user['rating'] ?? 0} ⭐',
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Đóng',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
