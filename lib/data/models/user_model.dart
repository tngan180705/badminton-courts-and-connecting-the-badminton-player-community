class UserModel {
  final String userId;
  final String fullName;
  final String phone;
  final String password;
  final String avatarUrl;
  final String role;
  final String skillLevel;
  final int reliabilityScore;
  final double walletBalance;
  final double latitude;
  final double longitude;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.password,
    required this.avatarUrl,
    required this.role,
    required this.skillLevel,
    required this.reliabilityScore,
    required this.walletBalance,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    required this.createdAt,
  });

  // Chuyển đổi từ JSON (Firestore) sang Object Flutter
  factory UserModel.fromFirestore(Map<String, dynamic> json, String id) {
    return UserModel(
      userId: id,
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      role: json['role'] ?? 'player',
      skillLevel: json['skill_level'] ?? 'beginner',
      reliabilityScore: json['reliability_score'] ?? 100,
      walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: (json['created_at'] != null)
          ? json['created_at'].toDate()
          : DateTime.now(),
    );
  }

  // Chuyển đổi từ Object Flutter sang JSON để đẩy lên Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'full_name': fullName,
      'phone': phone,
      'password': password,
      'avatar_url': avatarUrl,
      'role': role,
      'skill_level': skillLevel,
      'reliability_score': reliabilityScore,
      'wallet_balance': walletBalance,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}
