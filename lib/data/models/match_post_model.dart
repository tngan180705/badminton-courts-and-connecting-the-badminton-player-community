class MatchPostModel {
  final String matchPostId; // Prefix: MP_
  final String hostId;
  final String bookingId;
  final String title;
  final String description;
  final int slotsNeeded;
  final String status;
  final DateTime createdAt;

  MatchPostModel({
    required this.matchPostId,
    required this.hostId,
    required this.bookingId,
    required this.title,
    required this.description,
    required this.slotsNeeded,
    required this.status,
    required this.createdAt,
  });

  factory MatchPostModel.fromFirestore(Map<String, dynamic> json, String id) {
    return MatchPostModel(
      matchPostId: id,
      hostId: json['host_id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      slotsNeeded: json['slots_needed'] ?? 0,
      status: json['status'] ?? 'open',
      createdAt: (json['created_at'] != null)
          ? json['created_at'].toDate()
          : DateTime.now(),
    );
  }
}
