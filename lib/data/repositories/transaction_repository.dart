import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _generateTransactionId() async {
    final snapshot = await _firestore.collection('transactions').get();
    int maxNum = 0;
    for (final doc in snapshot.docs) {
      if (doc.id.startsWith('TX_')) {
        final numStr = doc.id.replaceFirst('TX_', '');
        final num = int.tryParse(numStr) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }
    return 'TX_${(maxNum + 1).toString().padLeft(3, '0')}';
  }

  Future<String> createTransaction({
    required String userId,
    required String? bookingId,
    required double amount,
    required String type,
    required String paymentType,
    required String transferContent,
  }) async {
    final txId = await _generateTransactionId();
    await _firestore.collection('transactions').doc(txId).set({
      'user_id': userId,
      'booking_id': bookingId,
      'amount': amount,
      'type': type,
      'payment_type': paymentType,
      'payment_method': 'Chuyển khoản ngân hàng',
      'status': 'pending',
      'transfer_content': transferContent,
      'created_at': Timestamp.now(),
    });
    print('✅ Transaction created: $txId');
    return txId;
  }

  Stream<List<TransactionModel>> getTransactionsByUser(String userId) {
    return _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}