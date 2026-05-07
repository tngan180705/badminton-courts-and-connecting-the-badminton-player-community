import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PaymentDialog extends StatelessWidget {
  final int depositAmount;
  final Function onConfirm;

  const PaymentDialog({
    super.key,
    required this.depositAmount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thanh toán cọc'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cọc 30%: $depositAmount đ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Phương thức: Chuyển khoản ngân hàng',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
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
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
