import 'dart:io'; // Cần để dùng kiểu dữ liệu File
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Cần để upload ảnh
import '../models/user_model.dart';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registerUser({
  required String email,
  required String password,
  required String fullName,
  required String phone,
  required String gender,
  required String skillLevel,
  File? imageFile,
}) async {
  // 1. Tạo Auth (Bắt buộc phải xong trước)
  UserCredential credential = await _auth.createUserWithEmailAndPassword(
    email: email, 
    password: password
  );
  String uid = credential.user!.uid;

  // 2. Tạo đối tượng User với avatarUrl trống
  UserModel newUser = UserModel(
    userId: uid,
    email: email,
    fullName: fullName,
    phone: phone,
    gender: gender,
    avatarUrl: "", // Tạm thời để trống
    role: "player",
    skillLevel: skillLevel,
    reliabilityScore: 100,
    walletBalance: 0,
    isActive: true,
    createdAt: DateTime.now(),
  );

  // 3. Lưu vào Firestore ngay lập tức (Để user thành công bước này đã)
  await _db.collection('users').doc(uid).set(newUser.toFirestore());

  // 4. Xử lý ảnh chạy ngầm (Nếu có ảnh)
  if (imageFile != null) {
    // Không dùng await ở đây nếu bạn muốn đăng ký xong ngay lập tức
    // Hoặc dùng try-catch riêng để nếu lỗi ảnh cũng không hỏng Register
    _uploadAndSyncAvatar(uid, imageFile);
  }
}

// Hàm bổ trợ: Upload và tự động đồng bộ link vào Firestore
Future<void> _uploadAndSyncAvatar(String uid, File file) async {
  try {
    final ref = FirebaseStorage.instance.ref().child('avatars').child('$uid.jpg');
    
    // Upload file
    await ref.putFile(file);
    
    // Lấy link
    String downloadUrl = await ref.getDownloadURL();
    
    // Cập nhật lại duy nhất trường avatar_url trong Firestore
    await _db.collection('users').doc(uid).update({
      'avatar_url': downloadUrl,
    });
    
    print("Đã cập nhật Avatar thành công!");
  } catch (e) {
    print("Lỗi xử lý ảnh ngầm: $e");
  }
}
}