import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- HÀM LẤY THÔNG TIN USER (QUAN TRỌNG ĐỂ CHECK ROLE) ---
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi lấy thông tin user: $e');
      return null;
    }
  }

  // --- HÀM ĐĂNG KÝ (GIỮ NGUYÊN CỦA BẠN) ---
  Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    required String skillLevel,
    File? imageFile,
  }) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    String uid = credential.user!.uid;

    UserModel newUser = UserModel(
      userId: uid,
      email: email,
      fullName: fullName,
      phone: phone,
      gender: gender,
      avatarUrl: "",
      role: "player", // Mặc định là player
      skillLevel: skillLevel,
      reliabilityScore: 100,
      walletBalance: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(uid).set(newUser.toFirestore());

    if (imageFile != null) {
      _uploadAndSyncAvatar(uid, imageFile);
    }
  }

  Future<void> _uploadAndSyncAvatar(String uid, File file) async {
    try {
      final ref =
          FirebaseStorage.instance.ref().child('avatars').child('$uid.jpg');
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();
      await _db
          .collection('users')
          .doc(uid)
          .update({'avatar_url': downloadUrl});
    } catch (e) {
      debugPrint("Lỗi xử lý ảnh ngầm: $e");
    }
  }
}
