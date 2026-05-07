import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class FindTeammatesDialog extends StatefulWidget {
  final Function(int, String) onConfirm;

  const FindTeammatesDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  State<FindTeammatesDialog> createState() => _FindTeammatesDialogState();
}

class _FindTeammatesDialogState extends State<FindTeammatesDialog> {
  int _slots = 2;
  String _skill = 'Chơi ổn';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Tìm thêm người',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Số lượng người cần tìm?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _slots,
                isExpanded: true,
                items: [1, 2, 3, 4]
                    .map((n) => DropdownMenuItem(
                          value: n,
                          child: Text('$n người', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _slots = val ?? 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Trình độ yêu cầu?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          ...[
            'Mới bắt đầu',
            'Chơi ổn',
            'Chơi tốt',
          ].map((skill) => RadioListTile<String>(
                title: Text(skill, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                value: skill,
                groupValue: _skill,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (val) =>
                    setState(() => _skill = val ?? 'Chơi ổn'),
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirm(_slots, _skill);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Tiếp tục', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
