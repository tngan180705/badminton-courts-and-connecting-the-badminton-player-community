import 'package:badminton_app/data/models/user_model.dart';
import 'package:badminton_app/presentation/features/court/providers/user_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        
        // 🛠 Khởi tạo một bản sao Map mới để tránh lỗi tham chiếu
        final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data()!);
        
        // Gán trực tiếp ID của document vào key 'id'
        data['id'] = doc.id; 
        
        return data;
      });
});

final userByIdProvider =
    FutureProvider.family<UserModel?, String>((ref, String userId) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserById(userId);
});