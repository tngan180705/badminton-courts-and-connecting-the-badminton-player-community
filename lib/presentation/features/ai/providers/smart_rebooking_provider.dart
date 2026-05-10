import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../activity/pages/activity_screen.dart'; // Correct path

class RebookingSuggestion {
  final int dayOfWeek;
  final String startTime;
  final String subCourtId;
  final String subCourtName;
  final String courtId;
  final String courtName;
  final DateTime suggestedDate;

  RebookingSuggestion({
    required this.dayOfWeek,
    required this.startTime,
    required this.subCourtId,
    required this.subCourtName,
    required this.courtId,
    required this.courtName,
    required this.suggestedDate,
  });
}

final smartRebookingProvider = FutureProvider<RebookingSuggestion?>((ref) async {
  print('REBOOK_DEBUG: Starting smartRebookingProvider');
  
  // Wait for activity provider
  final activitiesAsync = ref.watch(userActivitiesProvider);
  
  if (activitiesAsync.isLoading) {
    print('REBOOK_DEBUG: Activities still loading...');
    return null;
  }
  
  if (activitiesAsync.hasError) {
    print('REBOOK_DEBUG: Error loading activities: ${activitiesAsync.error}');
    return null;
  }

  final activities = activitiesAsync.value ?? [];
  print('REBOOK_DEBUG: Found ${activities.length} total activities');
  
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  final pastActivities = activities.where((a) {
    final bookingDate = a['booking_date'];
    if (bookingDate == null) return false;
    final date = (bookingDate as Timestamp).toDate();
    final status = a['status'] as String? ?? '';
    return date.isBefore(now) && date.isAfter(thirtyDaysAgo) && status != 'cancelled';
  }).toList();

  print('REBOOK_DEBUG: Found ${pastActivities.length} past activities in last 30 days');

  if (pastActivities.isEmpty) {
    print('REBOOK_DEBUG: No history found. Returning default suggestion.');
    return RebookingSuggestion(
      dayOfWeek: (now.weekday % 7) + 1,
      startTime: '19:00',
      subCourtId: 'SCT_001',
      subCourtName: 'Sân số 1',
      courtId: 'CT_001',
      courtName: 'Sân Cầu Lông Phạm Như Xương',
      suggestedDate: now.add(const Duration(days: 1)),
    );
  }

  // Count frequencies
  final dayCounts = <int, int>{};
  final timeCounts = <String, int>{};
  final subCourtCounts = <String, int>{};

  for (var a in pastActivities) {
    final date = (a['booking_date'] as Timestamp).toDate();
    final dow = date.weekday;
    final start = a['start_time'] as String? ?? '';
    final subId = a['sub_court_id'] as String? ?? '';

    dayCounts[dow] = (dayCounts[dow] ?? 0) + 1;
    if (start.isNotEmpty) timeCounts[start] = (timeCounts[start] ?? 0) + 1;
    if (subId.isNotEmpty) subCourtCounts[subId] = (subCourtCounts[subId] ?? 0) + 1;
  }

  final favoriteDay = dayCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final favoriteTime = timeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final favoriteSubCourt = subCourtCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  if (favoriteDay.isEmpty || favoriteTime.isEmpty) return null;

  final bestDay = favoriteDay.first.key;
  final bestTime = favoriteTime.first.key;
  final bestSubCourtId = favoriteSubCourt.isNotEmpty ? favoriteSubCourt.first.key : 'SCT_001';

  DateTime suggestedDate = now.add(const Duration(days: 1));
  while (suggestedDate.weekday != bestDay) {
    suggestedDate = suggestedDate.add(const Duration(days: 1));
  }
  suggestedDate = DateTime(suggestedDate.year, suggestedDate.month, suggestedDate.day);

  final db = FirebaseFirestore.instance;
  
  // Check availability
  final bookingsQuery = await db
      .collection('bookings')
      .where('sub_court_id', isEqualTo: bestSubCourtId)
      .where('booking_date', isEqualTo: Timestamp.fromDate(suggestedDate))
      .where('start_time', isEqualTo: bestTime)
      .where('status', isEqualTo: 'confirmed')
      .get();

  String finalSubCourtId = bestSubCourtId;
  String finalSubCourtName = '';
  String finalCourtId = '';
  String finalCourtName = 'Sân Cầu Lông Phạm Như Xương';

  if (bookingsQuery.docs.isEmpty) {
    final subDoc = await db.collection('sub_courts').doc(bestSubCourtId).get();
    finalSubCourtName = subDoc.data()?['sub_court_name'] ?? 'Sân của bạn';
    finalCourtId = subDoc.data()?['court_id'] ?? 'CT_001';
  } else {
    final allSubCourts = await db.collection('sub_courts').where('is_active', isEqualTo: true).get();
    for (var doc in allSubCourts.docs) {
      final id = doc.id;
      final checkQuery = await db
          .collection('bookings')
          .where('sub_court_id', isEqualTo: id)
          .where('booking_date', isEqualTo: Timestamp.fromDate(suggestedDate))
          .where('start_time', isEqualTo: bestTime)
          .where('status', isEqualTo: 'confirmed')
          .get();
      
      if (checkQuery.docs.isEmpty) {
        finalSubCourtId = id;
        finalSubCourtName = doc.data()['sub_court_name'] ?? 'Sân trống';
        finalCourtId = doc.data()['court_id'] ?? 'CT_001';
        break;
      }
    }
  }

  if (finalSubCourtName.isEmpty) return null;

  return RebookingSuggestion(
    dayOfWeek: bestDay,
    startTime: bestTime,
    subCourtId: finalSubCourtId,
    subCourtName: finalSubCourtName,
    courtId: finalCourtId,
    courtName: finalCourtName,
    suggestedDate: suggestedDate,
  );
});
