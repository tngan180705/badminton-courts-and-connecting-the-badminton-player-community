import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 👇 Generate ID U_001, U_002, ...
  Future<String> _generateUserId() async {
    final snapshot = await _firestore.collection('users').get();

    int maxNum = 0;
    for (final doc in snapshot.docs) {
      final id = doc.id;
      if (id.startsWith('U_')) {
        final numStr = id.replaceFirst('U_', '');
        final num = int.tryParse(numStr) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }

    final nextNum = maxNum + 1;
    return 'U_${nextNum.toString().padLeft(3, '0')}';
  }

  // 👇 Upload avatar
  Future<String?> _uploadAndSyncAvatar(String userId, File imageFile) async {
    try {
      final fileName = 'users/$userId/avatar.jpg';
      final ref = _storage.ref(fileName);
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ Avatar upload error: $e');
      return null;
    }
  }

  // 👇 Register user
  Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    required String skillLevel,
    File? imageFile,
  }) async {
    try {
      // 1. Tạo tài khoản Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUid = userCredential.user!.uid;

      // 2. Generate ID U_001, U_002, ...
      final userId = await _generateUserId();

      // 3. Upload avatar nếu có
      String? avatarUrl;
      if (imageFile != null) {
        avatarUrl = await _uploadAndSyncAvatar(userId, imageFile);
      }

      // 4. Lưu user vào Firestore
      await _firestore.collection('users').doc(userId).set({
        'firebase_uid': firebaseUid,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'gender': gender,
        'skill_level': skillLevel,
        'avatar_url': avatarUrl ?? '',
        'reliability_score': 0.0,
        'wallet_balance': 0.0,
        'created_at': Timestamp.now(),
      });

      print('✅ User created: $userId');
    } catch (e) {
      print('❌ Register error: $e');
      rethrow;
    }
  }
}
