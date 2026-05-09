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

  /// Tổng doanh thu = tất cả transaction (không lọc status)
  /// vì hiện tại app tạo transaction với status 'pending' khi thanh toán
  Future<double> getTotalRevenue() async {
    try {
      final snapshot =
          await _firestore.collection('transactions').get();

      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // amount có thể là int hoặc double → dùng num? để an toàn
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        total += amount;
      }
      return total;
    } catch (e) {
      print('❌ getTotalRevenue error: $e');
      return 0.0;
    }
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
      'payment_method': 'Chuyển Khoản Ngân Hàng',
      'status': 'pending',
      'transfer_content': transferContent,
      'created_at': Timestamp.now(),
    });
    return txId;
  }

  Stream<List<TransactionModel>> getTransactionsByUser(String userId) {
    return _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                TransactionModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
  Future<void> confirmTransaction({
  required String transactionId,
  required String? bookingId,
}) async {
  final batch = _firestore.batch();

  // Update transaction
  final txRef = _firestore
      .collection('transactions')
      .doc(transactionId);

  batch.update(txRef, {
    'status': 'confirmed',
  });

  // Update booking nếu có
  if (bookingId != null && bookingId.isNotEmpty) {
    final bookingRef =
        _firestore.collection('bookings').doc(bookingId);

    batch.update(bookingRef, {
      'status': 'confirmed',
    });
  }

  await batch.commit();
}

Future<void> rejectTransaction({
  required String transactionId,
  required String? bookingId,
}) async {
  final batch = _firestore.batch();

  final txRef = _firestore
      .collection('transactions')
      .doc(transactionId);

  batch.update(txRef, {
    'status': 'rejected',
  });

  if (bookingId != null && bookingId.isNotEmpty) {
    final bookingRef =
        _firestore.collection('bookings').doc(bookingId);

    batch.update(bookingRef, {
      'status': 'cancelled',
    });
  }

  await batch.commit();
}

Stream<List<TransactionModel>> getAllTransactions() {
  return _firestore
      .collection('transactions')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => TransactionModel.fromFirestore(
                doc.data(),
                doc.id,
              ),
            )
            .toList(),
      );
}
Future<List<TransactionModel>> getTransactionsByDateRange({
  required DateTime start,
  required DateTime end,
}) async {
  try {
    final snapshot = await _firestore
        .collection('transactions')
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          'created_at',
          isLessThanOrEqualTo: Timestamp.fromDate(end),
        )
        .orderBy('created_at')
        .get();

    return snapshot.docs
        .map(
          (doc) => TransactionModel.fromFirestore(
            doc.data(),
            doc.id,
          ),
        )
        .toList();
  } catch (e) {
    print('❌ getTransactionsByDateRange error: $e');
    return [];
  }
}
}