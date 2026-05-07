import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class BookingTimePicker extends StatelessWidget {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final DateTime selectedDate;
  final Function(TimeOfDay) onStartTimeSelected;
  final Function(TimeOfDay) onEndTimeSelected;

  const BookingTimePicker({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.selectedDate,
    required this.onStartTimeSelected,
    required this.onEndTimeSelected,
  });

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickStartTime(BuildContext context) async {
    final now = DateTime.now();

    final nowDateOnly = DateTime(now.year, now.month, now.day);
    final selectedDateOnly =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    int minHour = 5;

    // 👇 Fix: So sánh selectedDate, không phải DateTime.now()
    if (selectedDateOnly == nowDateOnly) {
      minHour = now.hour + 1;
      if (minHour > 22) minHour = 22;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay(hour: minHour, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      if (picked.hour < minHour) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phải đặt từ ${minHour}:00 trở đi'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      onStartTimeSelected(picked);
    }
  }

  Future<void> _pickEndTime(BuildContext context) async {
    if (startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giờ bắt đầu trước')),
      );
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: endTime ??
          TimeOfDay(
            hour: (startTime!.hour + 1).clamp(0, 23),
            minute: startTime!.minute,
          ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      if (picked.hour < startTime!.hour ||
          (picked.hour == startTime!.hour &&
              picked.minute <= startTime!.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giờ kết thúc phải sau giờ bắt đầu!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      onEndTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn giờ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Giờ bắt đầu
            Expanded(
              child: GestureDetector(
                onTap: () => _pickStartTime(
                    context), // 👈 Fix: không truyền DateTime.now()
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: startTime != null
                          ? AppColors.primary
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          startTime != null ? _formatTime(startTime!) : 'Từ',
                          style: TextStyle(
                            fontSize: 13,
                            color: startTime != null
                                ? AppColors.textPrimary
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child:
                  Text('—', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
            // Giờ kết thúc
            Expanded(
              child: GestureDetector(
                onTap: () => _pickEndTime(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: endTime != null
                          ? AppColors.primary
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          endTime != null ? _formatTime(endTime!) : 'Đến',
                          style: TextStyle(
                            fontSize: 13,
                            color: endTime != null
                                ? AppColors.textPrimary
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
