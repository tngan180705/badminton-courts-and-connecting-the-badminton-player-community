import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/match_post_model.dart';
import '../../../../data/models/match_post_view_model.dart';

final skillFilterProvider = StateProvider<String>((ref) => 'Tất cả');
final communityTabProvider = StateProvider<int>((ref) => 0);

Future<List<MatchPostViewModel>> _fetchAndJoinPosts(
  FirebaseFirestore db,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  DateTime now,
  DateTime sevenDaysLater,
) async {
  print('=== Tổng số docs: ${docs.length}');
  final List<MatchPostViewModel> results = [];
  final nowDateOnly = DateTime(now.year, now.month, now.day);

  for (final postDoc in docs) {
    try {
      final post = MatchPostModel.fromFirestore(postDoc.data(), postDoc.id);
      print('=== Post: ${post.matchPostId}, bookingId: ${post.bookingId}');

      if (post.bookingId.isEmpty) {
        print('=== SKIP: bookingId rỗng');
        continue;
      }

      final bookingDoc =
          await db.collection('bookings').doc(post.bookingId).get();
      print('=== Booking exists: ${bookingDoc.exists}');
      if (!bookingDoc.exists) continue;
      final booking = bookingDoc.data()!;

      final rawDate = booking['booking_date'];
      print('=== booking_date: $rawDate (${rawDate.runtimeType})');

      DateTime bookingDate;
      if (rawDate is Timestamp) {
        bookingDate = rawDate.toDate();
      } else if (rawDate is String) {
        bookingDate = DateTime.parse(rawDate);
      } else {
        print('=== SKIP: booking_date không hợp lệ');
        continue;
      }

      final bookingDateOnly =
          DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
      print(
          '=== bookingDateOnly: $bookingDateOnly | nowDateOnly: $nowDateOnly | +7days: $sevenDaysLater');

      if (bookingDateOnly.isBefore(nowDateOnly) ||
          bookingDateOnly.isAfter(sevenDaysLater)) {
        print('=== SKIP: ngoài khoảng 7 ngày');
        continue;
      }

      final subCourtId = booking['sub_court_id'] ?? '';
      print('=== subCourtId: $subCourtId');

      if (subCourtId.isEmpty) {
        print('=== SKIP: subCourtId rỗng');
        continue;
      }

      final subCourtDoc =
          await db.collection('sub_courts').doc(subCourtId).get();
      print('=== SubCourt exists: ${subCourtDoc.exists}');
      if (!subCourtDoc.exists) continue;
      final subCourt = subCourtDoc.data()!;

      final courtId = subCourt['court_id']?.toString() ?? '';
      print('=== courtId: $courtId');

      if (courtId.isEmpty) {
        print('=== SKIP: courtId rỗng');
        continue;
      }

      final courtDoc = await db.collection('courts').doc(courtId).get();
      print('=== Court exists: ${courtDoc.exists}');
      if (!courtDoc.exists) continue;
      final court = courtDoc.data()!;

      // 👇 Query user theo firebase_uid
      final userSnapshot = await db
          .collection('users')
          .where('firebase_uid', isEqualTo: post.hostId)
          .limit(1)
          .get();

      var hostName = 'Người dùng';
      String? hostAvatarUrl;
      double hostReliabilityScore = 100.0;
      if (userSnapshot.docs.isNotEmpty) {
        hostName = userSnapshot.docs.first.data()['full_name'] ?? 'Người dùng';
      }
      print('=== hostId: ${post.hostId}, hostName: $hostName');

      // 👇 Lấy danh sách members
      final membersSnapshot = await db
          .collection('match_members')
          .where('match_post_id', isEqualTo: post.matchPostId)
          .get();

      final memberIds =
          membersSnapshot.docs.map((doc) => doc['user_id'] as String).toList();

      results.add(MatchPostViewModel(
        matchPostId: post.matchPostId,
        hostId: post.hostId,
        hostName: hostName,
        hostAvatarUrl: hostAvatarUrl,
        hostReliabilityScore: hostReliabilityScore,
        title: post.title,
        courtName: court['name'] ?? '',
        subCourtName: subCourt['sub_court_name'] ?? '',
        bookingDate: bookingDate,
        startTime: booking['start_time'] ?? '',
        endTime: booking['end_time'] ?? '',
        slotsNeeded: post.slotsNeeded,
        status: post.status,
        skillLevel: post.skillLevel,
        memberIds: memberIds,
      ));
      print('=== ✅ Thành công: ${post.matchPostId}');
    } catch (e) {
      print('=== ❌ LỖI: $e');
      continue;
    }
  }

  results.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
  print('=== Tổng kết quả: ${results.length}');
  return results;
}

final communityPostsProvider =
    FutureProvider<List<MatchPostViewModel>>((ref) async {
  final db = FirebaseFirestore.instance;
  final now = DateTime.now();
  final sevenDaysLater = now.add(const Duration(days: 7));

  print('=== communityPostsProvider chạy');
  final postsSnapshot = await db
      .collection('match_posts')
      .where('status', whereIn: ['open', 'full']).get();
  print('=== match_posts count: ${postsSnapshot.docs.length}');

  return _fetchAndJoinPosts(db, postsSnapshot.docs, now, sevenDaysLater);
});

final myPostsProvider = FutureProvider<List<MatchPostViewModel>>((ref) async {
  final db = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;
  final now = DateTime.now();
  final sevenDaysLater = now.add(const Duration(days: 7));

  if (currentUser == null) return [];

  print('=== myPostsProvider chạy, firebaseUid: ${currentUser.uid}');

  // 👇 Lấy trận mình host
  final myHostedSnapshot = await db
      .collection('match_posts')
      .where('host_id', isEqualTo: currentUser.uid)
      .get();

  // 👇 Lấy trận mình join (từ match_members)
  final myMembershipsSnapshot = await db
      .collection('match_members')
      .where('user_id', isEqualTo: currentUser.uid)
      .get();

  final myJoinedMatchIds = myMembershipsSnapshot.docs
      .map((doc) => doc['match_post_id'] as String)
      .toList();

  // 👇 Lấy match_posts của những trận mình join
  late final QuerySnapshot<Map<String, dynamic>> myJoinedSnapshot;
  if (myJoinedMatchIds.isNotEmpty) {
    myJoinedSnapshot = await db
        .collection('match_posts')
        .where(FieldPath.documentId, whereIn: myJoinedMatchIds)
        .get();
  } else {
    myJoinedSnapshot = await db
        .collection('match_posts')
        .where('match_post_id', isEqualTo: 'nonexistent_id')
        .get();
  }

  // 👇 Merge cả 2 danh sách + bỏ trùng
  final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  final uniqueIds = <String>{};

  for (final doc in myHostedSnapshot.docs) {
    if (uniqueIds.add(doc.id)) allDocs.add(doc);
  }

  for (final doc in myJoinedSnapshot.docs) {
    if (uniqueIds.add(doc.id)) allDocs.add(doc);
  }

  print('=== my match_posts + joined count: ${allDocs.length}');

  return _fetchAndJoinPosts(db, allDocs, now, sevenDaysLater);
});

final filteredPostsProvider =
    FutureProvider<List<MatchPostViewModel>>((ref) async {
  final posts = await ref.watch(communityPostsProvider.future);
  final skillFilter = ref.watch(skillFilterProvider);

  // Lọc status 'full' ra khỏi "Tất cả trận"
  var filtered = posts.where((p) => p.status != 'full').toList();

  if (skillFilter == 'Tất cả') return filtered;
  return filtered.where((p) => p.skillLevel == skillFilter).toList();
});
