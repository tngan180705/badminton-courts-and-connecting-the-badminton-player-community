import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../data/models/match_post_model.dart';
import '../../../../data/models/match_post_view_model.dart';

/// =========================
/// FILTER PROVIDERS
/// =========================
final skillFilterProvider = StateProvider<String>((ref) => 'Tất cả');
final communityTabProvider = StateProvider<int>((ref) => 0);

/// =========================
/// CORE JOIN FUNCTION
/// =========================
Future<List<MatchPostViewModel>> _fetchAndJoinPosts(
  FirebaseFirestore db,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  DateTime now,
  DateTime sevenDaysLater,
) async {
  final List<MatchPostViewModel> results = [];
  final nowDateOnly = DateTime(now.year, now.month, now.day);

  for (final postDoc in docs) {
    try {
      final post =
          MatchPostModel.fromFirestore(postDoc.data(), postDoc.id);

      if (post.bookingId.isEmpty) continue;

      final bookingSnap =
          await db.collection('bookings').doc(post.bookingId).get();

      if (!bookingSnap.exists || bookingSnap.data() == null) continue;

      final booking = bookingSnap.data() as Map<String, dynamic>;

      final rawDate = booking['booking_date'];

      DateTime bookingDate;

      if (rawDate is Timestamp) {
        bookingDate = rawDate.toDate();
      } else if (rawDate is String) {
        bookingDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      } else {
        continue;
      }

      final bookingDateOnly =
          DateTime(bookingDate.year, bookingDate.month, bookingDate.day);

      if (bookingDateOnly.isBefore(nowDateOnly) ||
          bookingDateOnly.isAfter(sevenDaysLater)) {
        continue;
      }

      /// =========================
      /// SUB COURT
      /// =========================
      final subCourtId = booking['sub_court_id']?.toString() ?? '';
      if (subCourtId.isEmpty) continue;

      final subCourtSnap =
          await db.collection('sub_courts').doc(subCourtId).get();

      if (!subCourtSnap.exists || subCourtSnap.data() == null) continue;

      final subCourt = subCourtSnap.data() as Map<String, dynamic>;

      /// =========================
      /// COURT
      /// =========================
      final courtId = subCourt['court_id']?.toString() ?? '';
      if (courtId.isEmpty) continue;

      final courtSnap =
          await db.collection('courts').doc(courtId).get();

      if (!courtSnap.exists || courtSnap.data() == null) continue;

      final court = courtSnap.data() as Map<String, dynamic>;

      /// =========================
      /// HOST
      /// =========================
      final userSnap = await db
          .collection('users')
          .where('firebase_uid', isEqualTo: post.hostId)
          .limit(1)
          .get();

      String hostName = 'Người dùng';

      if (userSnap.docs.isNotEmpty) {
        hostName =
            userSnap.docs.first.data()['full_name'] ?? 'Người dùng';
      }

      /// =========================
      /// MEMBERS
      /// =========================
      final membersSnap = await db
          .collection('match_members')
          .where('match_post_id', isEqualTo: post.matchPostId)
          .get();

      final memberIds = membersSnap.docs
          .map((e) => (e.data()['user_id'] ?? '').toString())
          .where((e) => e.isNotEmpty)
          .toList();

      /// =========================
      /// ADD VIEW MODEL
      /// =========================
      results.add(MatchPostViewModel(
        matchPostId: post.matchPostId,
        hostId: post.hostId,
        hostName: hostName,
        hostAvatarUrl: null,
        hostReliabilityScore: 100,
        title: post.title,
        courtName: court['name']?.toString() ?? '',
        subCourtName: subCourt['sub_court_name']?.toString() ?? '',
        bookingDate: bookingDate,
        startTime: booking['start_time']?.toString() ?? '',
        endTime: booking['end_time']?.toString() ?? '',
        slotsNeeded: post.slotsNeeded,
        status: post.status,
        skillLevel: post.skillLevel,
        subCourtId: subCourtId,
        memberIds: memberIds,
      ));
    } catch (e) {
      continue;
    }
  }

  results.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
  return results;
}
/// =========================
/// ALL POSTS
/// =========================
final communityPostsProvider =
    FutureProvider<List<MatchPostViewModel>>((ref) async {
  final db = FirebaseFirestore.instance;

  final now = DateTime.now();
  final sevenDaysLater = now.add(const Duration(days: 7));

  final snapshot = await db
      .collection('match_posts')
      .where('status', whereIn: ['open', 'full'])
      .get();

  return _fetchAndJoinPosts(
    db,
    snapshot.docs,
    now,
    sevenDaysLater,
  );
});

/// =========================
/// MY POSTS
/// =========================
final myPostsProvider =
    FutureProvider<List<MatchPostViewModel>>((ref) async {
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return [];

  final now = DateTime.now();
  final sevenDaysLater = now.add(const Duration(days: 7));

  /// hosted
  final hostedSnap = await db
      .collection('match_posts')
      .where('host_id', isEqualTo: user.uid)
      .get();

  /// joined
  final memberSnap = await db
      .collection('match_members')
      .where('user_id', isEqualTo: user.uid)
      .get();

  final joinedIds =
      memberSnap.docs.map((e) => e['match_post_id'].toString()).toList();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> joinedDocs = [];

  if (joinedIds.isNotEmpty) {
    final snap = await db
        .collection('match_posts')
        .where(FieldPath.documentId, whereIn: joinedIds)
        .get();

    joinedDocs = snap.docs;
  }

  final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  final unique = <String>{};

  for (final d in hostedSnap.docs) {
    if (unique.add(d.id)) allDocs.add(d);
  }

  for (final d in joinedDocs) {
    if (unique.add(d.id)) allDocs.add(d);
  }

  return _fetchAndJoinPosts(db, allDocs, now, sevenDaysLater);
});

/// =========================
/// FILTERED POSTS
/// =========================
final filteredPostsProvider =
    FutureProvider<List<MatchPostViewModel>>((ref) async {
  final posts = await ref.watch(communityPostsProvider.future);
  final filter = ref.watch(skillFilterProvider);

  final base = posts.where((p) => p.status != 'full').toList();

  if (filter == 'Tất cả') return base;

  return base.where((p) => p.skillLevel == filter).toList();
});