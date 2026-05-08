import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate ID U_001, U_002...
  Future<String> _generateUserId() async {
    final snapshot = await _firestore.collection('users').get();

    int maxNum = 0;

    for (final doc in snapshot.docs) {
      final id = doc.id;

      if (id.startsWith('U_')) {
        final numStr = id.replaceFirst('U_', '');
        final num = int.tryParse(numStr) ?? 0;

        if (num > maxNum) {
          maxNum = num;
        }
      }
    }

    final nextNum = maxNum + 1;

    return 'U_${nextNum.toString().padLeft(3, '0')}';
  }

  /// Register User
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
      print('🔄 Registering user...');

      /// 1. Create Firebase Auth
      final userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUid = userCredential.user!.uid;

      /// 2. Generate custom user id
      final userId = await _generateUserId();

      /// 3. Convert image -> Base64
      String avatarBase64 = '';

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();

        avatarBase64 = base64Encode(bytes);

        print('✅ Avatar converted to Base64');
      }

      /// 4. Save user
      await _firestore.collection('users').doc(userId).set({
        'firebase_uid': firebaseUid,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'gender': gender,
        'skill_level': skillLevel,
        'avatar_base64': avatarBase64,
        'reliability_score': 100.0,
        'wallet_balance': 0.0,
        'created_at': Timestamp.now(),
      });

      print('✅ User saved: $userId');
    } catch (e, stack) {
      print('❌ Register Error: $e');
      print(stack);

      rethrow;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    final doc =
        await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc.data()!, doc.id);
  }
}