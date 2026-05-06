import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../models/user_model.dart'; // ✅ THÊM

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
      print('📤 Uploading avatar...');

      final ref = _storage.ref().child('users/$userId/avatar.jpg');

      await ref.putFile(imageFile);

      print('✅ Upload done');

      final url = await ref.getDownloadURL();

      print('🌐 URL: $url');

      return url;
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
      print('🔄 Bắt đầu đăng ký...');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUid = userCredential.user!.uid;

      final userId = await _generateUserId();

      String? avatarUrl;
      if (imageFile != null) {
        avatarUrl = await _uploadAndSyncAvatar(userId, imageFile);
      }

      await _firestore.collection('users').doc(userId).set({
        'firebase_uid': firebaseUid,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'gender': gender,
        'skill_level': skillLevel,
        'avatar_url': avatarUrl ?? '',
        'reliability_score': 100.0,
        'wallet_balance': 0.0,
        'created_at': Timestamp.now(),
      });

      await _firestore
          .collection('users_by_firebase_uid')
          .doc(firebaseUid)
          .set({
        'user_id': userId,
        'created_at': Timestamp.now(),
      });

      print('✅ User saved: $userId');
    } catch (e, stack) {
      print('❌ Error: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  // ⭐ FIX THÊM (BẮT BUỘC)
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc.data()!, doc.id);
  }
}