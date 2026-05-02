class CourtModel {
  final String courtId; // ID từ Document Firestore
  final String ownerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double pricePerHour;
  final String openTime;
  final String closeTime;
  final DateTime createdAt;
  final String imageUrl;

  CourtModel({
    required this.courtId,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    required this.openTime,
    required this.closeTime,
    required this.createdAt,
    required this.imageUrl,
  });

  // Chuyển từ Firestore JSON sang Object Flutter
  factory CourtModel.fromFirestore(Map<String, dynamic> json, String id) {
    return CourtModel(
      courtId: id,
      ownerId: json['owner_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      pricePerHour: (json['price_per_hour'] ?? 0).toDouble(),
      openTime: json['open_time'] ?? '',
      closeTime: json['close_time'] ?? '',
      createdAt: (json['created_at'] != null)
          ? json['created_at'].toDate()
          : DateTime.now(),
      imageUrl: json['image_url'] ?? '',
    );
  }

  // --- HÀM NÀY GIÚP HẾT LỖI Ở REPOSITORY & PROVIDER ---
  Map<String, dynamic> toFirestore() {
    return {
      'owner_id': ownerId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'price_per_hour': pricePerHour,
      'open_time': openTime,
      'close_time': closeTime,
      'created_at': createdAt,
      'image_url': imageUrl,
    };
  }
}
