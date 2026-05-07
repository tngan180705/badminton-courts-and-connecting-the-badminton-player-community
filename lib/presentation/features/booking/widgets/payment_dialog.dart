import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final formatter = NumberFormat('#,###', 'vi_VN');
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.payment, color: AppColors.primary),
          SizedBox(width: 10),
          Text('Thanh toán cọc', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Để duy trì hệ thống và đảm bảo việc ghép nhóm, vui lòng thanh toán tiền cọc sân.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cọc (30%):',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${formatter.format(depositAmount)} đ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance, size: 20, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chuyển khoản ngân hàng',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blue),
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
          child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
