import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../data/models/match_post_model.dart';
import '../../../../data/models/match_post_view_model.dart';

import '../../auth/providers/auth_state_provider.dart';

/// =========================
/// FILTER PROVIDERS
/// =========================
final skillFilterProvider = StateProvider<String>((ref) => 'Tất cả');
final communityTabProvider = StateProvider<int>((ref) => 0);

/// =========================
/// =========================
Future<List<MatchPostViewModel>> _fetchAndJoinPosts(
  FirebaseFirestore db,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  DateTime now,
  DateTime sevenDaysLater,
) async {
  final nowDateOnly = DateTime(now.year, now.month, now.day);
  
  // Local caches to avoid redundant fetches in the same batch
  final subCourtCache = <String, DocumentSnapshot>{};
  final courtCache = <String, DocumentSnapshot>{};
  final userCache = <String, QuerySnapshot>{};
  final bookingCache = <String, DocumentSnapshot>{};

  final futures = docs.map((postDoc) async {
    try {
      final post = MatchPostModel.fromFirestore(postDoc.data(), postDoc.id);
      if (post.bookingId.isEmpty) return null;

      // 1. Fetch Booking (cached)
      if (!bookingCache.containsKey(post.bookingId)) {
        bookingCache[post.bookingId] = await db.collection('bookings').doc(post.bookingId).get();
      }
      final bookingSnap = bookingCache[post.bookingId]!;
      if (!bookingSnap.exists || bookingSnap.data() == null) return null;

      final booking = bookingSnap.data() as Map<String, dynamic>;
      final rawDate = booking['booking_date'];
      DateTime bookingDate;
      if (rawDate is Timestamp) {
        bookingDate = rawDate.toDate();
      } else if (rawDate is String) {
        bookingDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      } else {
        return null;
      }

      final bookingDateOnly = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
      if (bookingDateOnly.isBefore(nowDateOnly) || bookingDateOnly.isAfter(sevenDaysLater)) {
        return null;
      }

      // Check if match has ended (if today)
      if (bookingDateOnly.isAtSameMomentAs(nowDateOnly)) {
        final endTimeStr = booking['end_time']?.toString() ?? '00:00';
        final endParts = endTimeStr.split(':');
        if (endParts.length == 2) {
          final endHour = int.tryParse(endParts[0]) ?? 0;
          final endMin = int.tryParse(endParts[1]) ?? 0;
          final endDateTime = DateTime(now.year, now.month, now.day, endHour, endMin);
          if (now.isAfter(endDateTime)) {
            return null; // Match has ended
          }
        }
      }

      final subCourtId = booking['sub_court_id']?.toString() ?? '';
      if (subCourtId.isEmpty) return null;

      // 2. Fetch SubCourt & User & Members in parallel (with caching for SubCourt & User)
      final subCourtFuture = subCourtCache.containsKey(subCourtId) 
          ? Future.value(subCourtCache[subCourtId]) 
          : db.collection('sub_courts').doc(subCourtId).get();
          
      final userFuture = userCache.containsKey(post.hostId)
          ? Future.value(userCache[post.hostId])
          : db.collection('users').where('firebase_uid', isEqualTo: post.hostId).limit(1).get();
          
      final membersFuture = db.collection('match_members').where('match_post_id', isEqualTo: post.matchPostId).get();

      final results = await Future.wait([subCourtFuture, userFuture, membersFuture]);

      final subCourtSnap = results[0] as DocumentSnapshot;
      final userSnap = results[1] as QuerySnapshot;
      final membersSnap = results[2] as QuerySnapshot;

      // Update caches
      subCourtCache[subCourtId] = subCourtSnap;
      userCache[post.hostId] = userSnap;

      if (!subCourtSnap.exists || subCourtSnap.data() == null) return null;
      final subCourt = subCourtSnap.data() as Map<String, dynamic>;

      final courtId = subCourt['court_id']?.toString() ?? '';
      if (courtId.isEmpty) return null;

      // 3. Fetch Court (cached)
      if (!courtCache.containsKey(courtId)) {
        courtCache[courtId] = await db.collection('courts').doc(courtId).get();
      }
      final courtSnap = courtCache[courtId]!;
      if (!courtSnap.exists || courtSnap.data() == null) return null;
      final court = courtSnap.data() as Map<String, dynamic>;

      String hostName = 'Người dùng';
      String hostAvatar = '';
      double hostScore = 100.0; // Mặc định 5 sao (= 100 điểm)

      if (userSnap.docs.isNotEmpty) {
        final userData = userSnap.docs.first.data() as Map<String, dynamic>;
        hostName = userData['full_name'] ?? 'Người dùng';
        hostAvatar = userData['avatar_base64'] ?? '';

        // Tính trung bình số sao từ collection 'reviews'
        final reviewsSnap = await db
            .collection('reviews')
            .where('to_user_id', isEqualTo: post.hostId)
            .get();
        if (reviewsSnap.docs.isNotEmpty) {
          final total = reviewsSnap.docs.fold<int>(
            0,
            (sum, doc) => sum + ((doc.data()['rating_score'] as num?)?.toInt() ?? 5),
          );
          final avgStars = total / reviewsSnap.docs.length; // 1.0 – 5.0
          hostScore = avgStars * 20.0; // quy ra 100-điểm (để hiển thị trong MatchCard)
        } else {
          hostScore = 100.0; // chưa có đánh giá nào → 5 sao mặc định
        }
      }

      final memberIds = membersSnap.docs
          .map((e) => (e.data() as Map<String, dynamic>)['user_id']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();

      return MatchPostViewModel(
        matchPostId: post.matchPostId,
        hostId: post.hostId,
        hostName: hostName,
        hostAvatarBase64: hostAvatar,
        hostReliabilityScore: hostScore,
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
      );
    } catch (e) {
      print('❌ Error joining post data: $e');
      return null;
    }
  });

  final allResults = await Future.wait(futures);
  final results = allResults.whereType<MatchPostViewModel>().toList();

  results.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
  return results;
}

/// =========================
/// ALL POSTS (Real-time)
/// =========================
final communityPostsProvider = StreamProvider<List<MatchPostViewModel>>((ref) {
  final db = FirebaseFirestore.instance;
  final now = DateTime.now();
  final sevenDaysLater = now.add(const Duration(days: 7));

  return db
      .collection('match_posts')
      .where('status', whereIn: ['open', 'full'])
      .snapshots()
      .asyncMap((snapshot) => _fetchAndJoinPosts(
            db,
            snapshot.docs,
            now,
            sevenDaysLater,
          ));
});

/// =========================
/// MY POSTS (Real-time)
/// =========================
final myPostsProvider = StreamProvider<List<MatchPostViewModel>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  
  if (user == null) return Stream.value([]);
  
  final db = FirebaseFirestore.instance;
  final now = DateTime.now();
  final sevenDaysLater = now.add(const Duration(days: 7));

  // Combine hosted and joined posts streams
  final hostedStream = db
      .collection('match_posts')
      .where('host_id', isEqualTo: user.uid)
      .where('status', whereIn: ['open', 'full'])
      .snapshots();
      
  final joinedStream = db
      .collection('match_members')
      .where('user_id', isEqualTo: user.uid)
      .snapshots();

  return Stream.fromFuture(Future.value(null)).asyncExpand((_) async* {
    await for (final hostedSnap in hostedStream) {
      // For each hosted update, also get joined docs
      final memberSnap = await db
          .collection('match_members')
          .where('user_id', isEqualTo: user.uid)
          .get();
          
      final joinedIds = memberSnap.docs.map((e) => e['match_post_id'].toString()).toList();
      
      List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = [...hostedSnap.docs];
      final uniqueIds = hostedSnap.docs.map((d) => d.id).toSet();

      if (joinedIds.isNotEmpty) {
        final joinedSnap = await db
            .collection('match_posts')
            .where(FieldPath.documentId, whereIn: joinedIds)
            .get();
            
        for (final d in joinedSnap.docs) {
          if (uniqueIds.add(d.id)) {
            allDocs.add(d);
          }
        }
      }
      
      yield await _fetchAndJoinPosts(db, allDocs, now, sevenDaysLater);
    }
  });
});

/// =========================
/// FILTERED POSTS (Reactive)
/// =========================
final filteredPostsProvider = StreamProvider<List<MatchPostViewModel>>((ref) {
  final postsAsync = ref.watch(communityPostsProvider);
  final filter = ref.watch(skillFilterProvider);

  return postsAsync.when(
    data: (posts) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      // ✅ Lọc: Chỉ ẩn những trận đã đầy (status == 'full')
      // Cho phép hiện trận của mình tạo để đồng bộ dữ liệu
      final base = posts.where((p) => p.status != 'full').toList();
      
      if (filter == 'Tất cả') return Stream.value(base);
      return Stream.value(base.where((p) => p.skillLevel == filter).toList());
    },
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
  );
});