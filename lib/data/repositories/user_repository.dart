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

    return 'U_${(maxNum + 1).toString().padLeft(3, '0')}';
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

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUid = userCredential.user!.uid;
      final userId = await _generateUserId();

      String avatarBase64 = '';
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        avatarBase64 = base64Encode(bytes);
        print('✅ Avatar converted to Base64');
      }

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
        'role': 'player',
        'is_active': true,
        'created_at': Timestamp.now(),
      });

      print('✅ User saved: $userId');
    } catch (e, stack) {
      print('❌ Register Error: $e');
      print(stack);
      rethrow;
    }
  }

  /// Tổng số user — chỉ 1 hàm duy nhất, có try/catch
  Future<int> getTotalUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ getTotalUsers error: $e');
      return 0;
    }
  }

  Future<UserModel?> getUserByFirebaseUid(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('firebase_uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return UserModel.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      print('❌ getUserByFirebaseUid error: $e');
      return null;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('❌ getUserById error: $e');
      return null;
    }
  }

  /// Update User Info
  Future<void> updateUser({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('❌ updateUser error: $e');
      rethrow;
    }
  }
}