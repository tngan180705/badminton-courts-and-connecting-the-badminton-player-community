import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String gender;
  final String avatarBase64;
  final String role;
  final String skillLevel;
  final double reliabilityScore;
  final double walletBalance;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.avatarBase64,
    required this.role,
    required this.skillLevel,
    required this.reliabilityScore,
    required this.walletBalance,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> json, String id) {
    return UserModel(
      userId: id, // 🛠 ID này được truyền từ UI/Provider
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? 'Nam',
      avatarBase64: json['avatar_base64'] ?? '',
      role: json['role'] ?? 'player',
      skillLevel: json['skill_level'] ?? 'Mới bắt đầu',
      reliabilityScore: (json['reliability_score'] ?? 100).toDouble(),
      walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}