import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/smart_rebooking_provider.dart';
import '../../booking/pages/booking_screen.dart';
import '../../../../data/models/sub_court_model.dart';
import '../../../../core/constants/app_colors.dart';

class SmartRebookingWidget extends ConsumerWidget {
  const SmartRebookingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionAsync = ref.watch(smartRebookingProvider);

    return suggestionAsync.when(
      data: (suggestion) {
        if (suggestion == null) return const SizedBox.shrink();

        final dayNames = ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
        final dateStr = DateFormat('dd/MM').format(suggestion.suggestedDate);
        final dayStr = dayNames[suggestion.dayOfWeek];

        int? startHour;
        try {
          startHour = int.parse(suggestion.startTime.split(':')[0]);
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E3D21), Color(0xFF4A6136)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E3D21).withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Trang trí background
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.sports_tennis,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Avatar AI mini
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.smart_toy, color: Colors.amber, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flash_on, color: Colors.amber, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'GỢI Ý THÔNG MINH',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '🏸 Chơi $dayStr tới nhé?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${suggestion.subCourtName} còn trống $dateStr lúc ${suggestion.startTime}. Đặt lại thói quen của bạn!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút đặt ngay kiểu mới
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              final subCourt = SubCourtModel(
                                subCourtId: suggestion.subCourtId,
                                courtId: suggestion.courtId,
                                subCourtName: suggestion.subCourtName,
                                isActive: true,
                                status: 'active',
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingScreen(
                                    courtName: suggestion.courtName,
                                    subCourt: subCourt,
                                    initialDate: suggestion.suggestedDate,
                                    initialStartHour: startHour,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2E3D21),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'ĐẶT\nNGAY',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, height: 1.1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, st) => const SizedBox.shrink(),
    );
  }
}
