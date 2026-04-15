import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'transactions';

  // Tạo giao dịch mới (Thanh toán, Nạp tiền, Hoàn tiền)
  Future<void> createTransaction(TransactionModel transaction) async {
    await _firestore.collection(_collection).add(transaction.toFirestore());
  }

  // Lấy lịch sử giao dịch của người dùng
  Future<List<TransactionModel>> getTransactionsByUser(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}
