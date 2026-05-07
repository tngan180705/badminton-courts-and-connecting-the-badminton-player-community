class MatchPostViewModel {
  final String matchPostId;

  final String hostId;
  final String hostName;

  final String? hostAvatarBase64;

  final double hostReliabilityScore;

  final String title;

  final String courtName;
  final String subCourtName;

  final DateTime bookingDate;

  final String startTime;
  final String endTime;

  final int slotsNeeded;

  final String status;
  final String skillLevel;

  final String subCourtId;

  final List<String> memberIds;

  MatchPostViewModel({
    required this.matchPostId,
    required this.hostId,
    required this.hostName,
    this.hostAvatarBase64,
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
    required this.subCourtId,
    this.memberIds = const [],
  });
}