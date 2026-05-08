import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/match_post_view_model.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/user_stream_provider.dart';
class MatchCard extends ConsumerWidget {
  final MatchPostViewModel match;
  final bool isMyPost;
  final VoidCallback? onJoinPressed;
  final VoidCallback? onDetailPressed;

  const MatchCard({
    super.key,
    required this.match,
    this.isMyPost = false,
    this.onJoinPressed,
    this.onDetailPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final userAsync =
    ref.watch(userByFirebaseUidProvider(match.hostId));

    final userData = userAsync.asData?.value;

    final hostName =
        userData?['full_name'] ??
        'Người dùng';

    final hostAvatar =
        userData?['avatar_base64'] ??
    '';

    final reliability =
        (userData?['reliability_score'] ?? 100)
            .toDouble();
    final now = DateTime.now();
    final isToday = match.bookingDate.day == now.day &&
        match.bookingDate.month == now.month &&
        match.bookingDate.year == now.year;
    final dateStr = isToday
        ? 'Hôm nay'
        : DateFormat('dd/MM/yyyy').format(match.bookingDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
  radius: 22,
  backgroundColor:
      AppColors.secondary.withOpacity(0.3),

  backgroundImage: hostAvatar.isNotEmpty
      ? MemoryImage(base64Decode(hostAvatar))
      : null,

  child: hostAvatar.isEmpty
      ? const Icon(
          Icons.person,
          color: AppColors.secondary,
          size: 24,
        )
      : null,
),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hostName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (reliability / 100 * 5)
                          .toStringAsFixed(1), // 👈 tính từ reliability_score
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.location_on, size: 17, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${match.courtName} - ${match.subCourtName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_outlined,
                  size: 17, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                '$dateStr, ${match.startTime} - ${match.endTime}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.bar_chart_outlined,
                  size: 17, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Trình độ: ${match.skillLevel}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Còn thiếu ${match.slotsNeeded} người',
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              // 👇 Hiển thị nút khác nhau
              if (isMyPost && onDetailPressed != null)
                ElevatedButton.icon(
                  onPressed: onDetailPressed,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Chi tiết'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                )
              else if (!isMyPost && onJoinPressed != null)
                ElevatedButton(
                  onPressed: onJoinPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Tham gia',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
