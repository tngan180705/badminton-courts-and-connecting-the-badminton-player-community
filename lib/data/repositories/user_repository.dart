import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Lấy thông tin chi tiết một người dùng
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error getting user: $e');
    }
    return null;
  }

  // Cập nhật số dư ví (Khi nạp tiền hoặc thanh toán)
  Future<void> updateWalletBalance(String userId, double newBalance) async {
    await _firestore.collection(_collection).doc(userId).update({
      'wallet_balance': newBalance,
    });
  }
}
