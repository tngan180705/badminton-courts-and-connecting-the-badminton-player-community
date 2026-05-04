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

      final hostDoc = await db.collection('users').doc(post.hostId).get();
      final hostName = hostDoc.data()?['full_name'] ?? 'Người dùng';
      print('=== hostName: $hostName');

      results.add(MatchPostViewModel(
        matchPostId: post.matchPostId,
        hostId: post.hostId,
        hostName: hostName,
        title: post.title,
        courtName: court['name'] ?? '',
        subCourtName: subCourt['sub_court_name'] ?? '',
        bookingDate: bookingDate,
        startTime: booking['start_time'] ?? '',
        endTime: booking['end_time'] ?? '',
        slotsNeeded: post.slotsNeeded,
        status: post.status,
        skillLevel: post.skillLevel,
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
      .where('status', isEqualTo: 'open')
      .get();
  print('=== match_posts count: ${postsSnapshot.docs.length}');

  return _fetchAndJoinPosts(db, postsSnapshot.docs, now, sevenDaysLater);
});

final myPostsProvider = FutureProvider<List<MatchPostViewModel>>((ref) async {
  final db = FirebaseFirestore.instance;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final now = DateTime.now();
  final sevenDaysLater = now.add(const Duration(days: 7));

  print('=== myPostsProvider chạy, userId: $currentUserId');
  final postsSnapshot = await db
      .collection('match_posts')
      .where('status', isEqualTo: 'open')
      .where('host_id', isEqualTo: currentUserId)
      .get();
  print('=== my match_posts count: ${postsSnapshot.docs.length}');

  return _fetchAndJoinPosts(db, postsSnapshot.docs, now, sevenDaysLater);
});

// 👇 Đổi thành FutureProvider để đồng kiểu với myPostsProvider
final filteredPostsProvider =
    FutureProvider<List<MatchPostViewModel>>((ref) async {
  final posts = await ref.watch(communityPostsProvider.future);
  final skillFilter = ref.watch(skillFilterProvider);

  if (skillFilter == 'Tất cả') return posts;
  return posts.where((p) => p.skillLevel == skillFilter).toList();
});
