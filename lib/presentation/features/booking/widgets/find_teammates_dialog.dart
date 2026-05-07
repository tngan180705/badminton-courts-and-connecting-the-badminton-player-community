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
      title: const Text('Tìm thêm người'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Cần bao nhiêu người?'),
          const SizedBox(height: 8),
          DropdownButton<int>(
            value: _slots,
            isExpanded: true,
            items: [1, 2, 3, 4]
                .map((n) => DropdownMenuItem(
                      value: n,
                      child: Text('$n người'),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _slots = val ?? 2),
          ),
          const SizedBox(height: 16),
          const Text('Trình độ yêu cầu?'),
          const SizedBox(height: 8),
          ...[
            'Mới bắt đầu',
            'Chơi ổn',
            'Chơi tốt',
          ]
              .map((skill) => RadioListTile<String>(
                    title: Text(skill),
                    value: skill,
                    groupValue: _skill,
                    onChanged: (val) =>
                        setState(() => _skill = val ?? 'Chơi ổn'),
                  ))
              .toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirm(_slots, _skill);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('Tiếp tục'),
        ),
      ],
    );
  }
}
