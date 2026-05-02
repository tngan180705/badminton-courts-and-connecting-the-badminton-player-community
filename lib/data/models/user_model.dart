import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String fullName;
  final String email; // Mới bổ sung
  final String phone;
  final String gender; // Mới bổ sung
  final String avatarUrl;
  final String role;
  final String skillLevel;
  final int reliabilityScore;
  final double walletBalance;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.avatarUrl,
    required this.role,
    required this.skillLevel,
    required this.reliabilityScore,
    required this.walletBalance,
    required this.isActive,
    required this.createdAt,
  });

  // Chuyển đổi từ JSON (Firestore) sang Object Flutter
  factory UserModel.fromFirestore(Map<String, dynamic> json, String id) {
    return UserModel(
      userId: id,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? 'Nam',
      avatarUrl: json['avatar_url'] ?? '',
      role: json['role'] ?? 'player',
      skillLevel: json['skill_level'] ?? 'Mới bắt đầu',
      reliabilityScore: json['reliability_score'] ?? 100,
      walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: (json['created_at'] != null)
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Chuyển đổi từ Object Flutter sang JSON để đẩy lên Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'avatar_url': avatarUrl,
      'role': role,
      'skill_level': skillLevel,
      'reliability_score': reliabilityScore,
      'wallet_balance': walletBalance,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
