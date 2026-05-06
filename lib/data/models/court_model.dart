import 'package:cloud_firestore/cloud_firestore.dart';

class CourtModel {
  final String courtId;
  final String ownerId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double pricePerHour;
  final String openTime;
  final String closeTime;
  final DateTime createdAt;
  final List<String> imageUrls;

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
    required this.imageUrls,
  });

  factory CourtModel.fromFirestore(Map<String, dynamic> json, String id) {
    return CourtModel(
      courtId: id,
      ownerId: json['owner_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',

      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,

      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,

      pricePerHour: (json['price_per_hour'] is num)
          ? (json['price_per_hour'] as num).toDouble()
          : double.tryParse(json['price_per_hour']?.toString() ?? '') ?? 0.0,

      openTime: json['open_time'] ?? '',
      closeTime: json['close_time'] ?? '',

      createdAt: (json['created_at'] is Timestamp)
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),

      // ✅ FIX NULL SAFE 100%
      imageUrls: (json['image_urls'] is List)
          ? List<String>.from(json['image_urls'])
          : [],
    );
  }

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
      'image_urls': imageUrls,
    };
  }
}