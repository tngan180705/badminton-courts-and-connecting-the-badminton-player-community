import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

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
              // HEADER
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

              _buildDetailRow(
                icon: Icons.location_on,
                label: 'Sân:',
                value: '${match.courtName} - ${match.subCourtName}',
              ),
              const SizedBox(height: 12),

              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Ngày:',
                value: DateFormat('dd/MM/yyyy').format(match.bookingDate),
              ),
              const SizedBox(height: 12),

              _buildDetailRow(
                icon: Icons.access_time_outlined,
                label: 'Thời gian:',
                value: '${match.startTime} - ${match.endTime}',
              ),
              const SizedBox(height: 12),

              _buildDetailRow(
                icon: Icons.bar_chart_outlined,
                label: 'Trình độ:',
                value: match.skillLevel,
              ),
              const SizedBox(height: 12),

              _buildDetailRow(
                icon: Icons.people_outline,
                label: 'Số người:',
                value: 'Còn thiếu ${match.slotsNeeded} người',
                valueColor: Colors.red,
              ),
              const SizedBox(height: 12),

              _buildDetailRow(
                icon: Icons.attach_money_outlined,
                label: 'Giá:',
                value: '${_calculatePrice(match.startTime, match.endTime)}đ',
              ),
              const SizedBox(height: 20),

              const Text(
                'Thành viên:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _MembersList(match: match),

              const SizedBox(height: 20),

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
                    style: TextStyle(color: Colors.white),
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
    Color valueColor = Colors.black,
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
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
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

      final hours = (end - start).abs().toDouble();
      return (hours * 150000).toInt().toString();
    } catch (e) {
      return '150000';
    }
  }
}

class _MembersList extends StatelessWidget {
  final MatchPostViewModel match;

  const _MembersList({required this.match});

  double _scoreToRating(double score) => (score / 100) * 5;

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

            final avatar = member['avatarBase64'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.secondary.withOpacity(0.3),
                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                        ? MemoryImage(base64Decode(avatar))
                        : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? const Icon(Icons.person,
                            color: AppColors.secondary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['full_name'] ?? 'Người dùng',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (member['isHost'] == true)
                          const Text(
                            'Host',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (member['rating'] != null)
                    Row(
                      children: [
                        Text(member['rating']),
                        const Icon(Icons.star,
                            color: Colors.amber, size: 14),
                      ],
                    ),
                ],
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

    final hostSnapshot = await db
        .collection('users')
        .where('firebase_uid', isEqualTo: match.hostId)
        .limit(1)
        .get();

    if (hostSnapshot.docs.isNotEmpty) {
      final host = hostSnapshot.docs.first.data();

      members.add({
        'full_name': host['full_name'],
        'avatarBase64': host['avatar_base64'],
        'isHost': true,
        'rating':
            _scoreToRating((host['reliability_score'] ?? 100).toDouble())
                .toStringAsFixed(1),
      });
    }

    final joinSnapshot = await db
        .collection('match_members')
        .where('match_post_id', isEqualTo: match.matchPostId)
        .get();

    for (var doc in joinSnapshot.docs) {
      final userId = doc['user_id'];

      final userSnap = await db
          .collection('users')
          .where('firebase_uid', isEqualTo: userId)
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        final u = userSnap.docs.first.data();

        members.add({
          'full_name': u['full_name'],
          'avatarBase64': u['avatar_base64'],
          'isHost': false,
          'rating':
              _scoreToRating((u['reliability_score'] ?? 100).toDouble())
                  .toStringAsFixed(1),
        });
      }
    }

    return members;
  }
}