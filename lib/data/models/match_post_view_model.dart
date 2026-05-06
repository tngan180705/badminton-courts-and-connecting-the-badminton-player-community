// Model tổng hợp sau khi join data từ nhiều collections
class MatchPostViewModel {
  final String matchPostId;
  final String hostId;
  final String hostName; // từ users
  final String? hostAvatarUrl;
  final double hostReliabilityScore;
  final String title;
  final String courtName; // từ courts (qua booking → sub_court → court)
  final String subCourtName; // từ sub_courts
  final DateTime bookingDate; // từ bookings
  final String startTime; // từ bookings
  final String endTime; // từ bookings
  final int slotsNeeded;
  final String status;
  final String skillLevel; // từ match_posts
  final List<String> memberIds;

  MatchPostViewModel({
    required this.matchPostId,
    required this.hostId,
    required this.hostName,
    this.hostAvatarUrl,
    required this.hostReliabilityScore,
    required this.title,
    required this.courtName,
    required this.subCourtName,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.slotsNeeded,
    required this.status,
    required this.skillLevel,
    this.memberIds = const [],
  });
}
