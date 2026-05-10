import 'package:flutter/material.dart';

class QuickActionsRow extends StatelessWidget {
  final Function(String) onActionTap;

  const QuickActionsRow({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (icon: Icons.today_outlined, label: 'Hôm nay tôi có gì?'),
      (icon: Icons.calendar_month_outlined, label: 'Lịch 7 ngày tới'),
      (icon: Icons.sports_tennis_outlined, label: 'Khi nào tôi chơi tiếp?'),
      (icon: Icons.history_rounded, label: 'Đặt lại lịch tuần trước'),
      (icon: Icons.stadium_outlined, label: 'Sân trống tối nay'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onActionTap(action.label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF4A6136).withValues(alpha: 0.35),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFF0F7EC),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          action.icon,
                          size: 14,
                          color: const Color(0xFF4A6136),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          action.label,
                          style: const TextStyle(
                            color: Color(0xFF4A6136),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
