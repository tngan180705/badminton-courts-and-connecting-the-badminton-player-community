import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/admin_provider.dart';
import '../widgets/transaction_info_card.dart';

class AdminTransactionApprovalScreen extends ConsumerWidget {
  const AdminTransactionApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingTransactionsAsync = ref.watch(pendingTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Giao dịch chờ duyệt',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A6136)),
          ),
        ),
        Expanded(
          child: pendingTransactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('Tất cả giao dịch đã được xử lý', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  return TransactionInfoCard(transactionData: transactions[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi: $e')),
          ),
        ),
      ],
    );
  }
}
