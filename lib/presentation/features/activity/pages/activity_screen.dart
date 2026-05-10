import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../common_widgets/main_header.dart';
import '../../../common_widgets/main_footer.dart';
import '../../auth/providers/user_provider.dart';
import '../../community/pages/community_screen.dart';
import '../../court/pages/home_screen.dart';
import '../widgets/activity_card.dart';
import '../../profile/pages/profile_screen.dart';
import '../../auth/providers/auth_state_provider.dart';
import '../../../../core/utils/fixed_fab_location.dart';
import '../../ai/pages/ai_chat_screen.dart';

/// Helper to fetch details for a list of bookings
Future<List<Map<String, dynamic>>> _fetchDetails(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
  final activities = <Map<String, dynamic>>[];
  final db = FirebaseFirestore.instance;

  for (var doc in docs) {
    final data = doc.data();
    final subCourtId = data['sub_court_id'] as String;

    // Fetch sub-court and court info
    final subCourtDoc = await db.collection('sub_courts').doc(subCourtId).get();

    if (subCourtDoc.exists) {
      final subCourtData = subCourtDoc.data()!;
      final courtId = subCourtData['court_id'] as String;

      final courtDoc = await db.collection('courts').doc(courtId).get();

      if (courtDoc.exists) {
        final courtData = courtDoc.data()!;
        data['sub_court_name'] = subCourtData['sub_court_name'] ?? 'Sân chưa đặt tên';
        data['court_name'] = courtData['name'];
      }
    }

    // Fetch host phone number
    final hostId = data['player_id'] as String;
    final hostDoc = await db.collection('users').where('firebase_uid', isEqualTo: hostId).limit(1).get();
    if (hostDoc.docs.isNotEmpty) {
      data['host_phone'] = hostDoc.docs.first.data()['phone'] ?? '';
    }

    data['id'] = doc.id;
    activities.add(data);
  }
  return activities;
}

/// Stream for bookings where user is the player
final directBookingsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('player_id', isEqualTo: user.uid)
      .snapshots()
      .asyncMap((snap) => _fetchDetails(snap.docs));
});

/// Stream for bookings where user joined as a member
final joinedBookingsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);

  final db = FirebaseFirestore.instance;

  return db
      .collection('match_members')
      .where('user_id', isEqualTo: user.uid)
      .snapshots()
      .asyncMap((snap) async {
    final activities = <Map<String, dynamic>>[];
    for (var memberDoc in snap.docs) {
      final matchPostId = memberDoc['match_post_id'] as String;
      final postDoc = await db.collection('match_posts').doc(matchPostId).get();
      
      if (postDoc.exists) {
        final bookingId = postDoc['booking_id'] as String;
        final bookingDoc = await db.collection('bookings').doc(bookingId).get();
        
        if (bookingDoc.exists) {
          final data = bookingDoc.data()!;
          final subCourtId = data['sub_court_id'] as String;

          final subCourtDoc = await db.collection('sub_courts').doc(subCourtId).get();
          if (subCourtDoc.exists) {
            final subCourtData = subCourtDoc.data()!;
            final courtId = subCourtData['court_id'] as String;
            final courtDoc = await db.collection('courts').doc(courtId).get();
            if (courtDoc.exists) {
              final courtData = courtDoc.data()!;
              data['sub_court_name'] = subCourtData['sub_court_name'] ?? 'Sân chưa đặt tên';
              data['court_name'] = courtData['name'];
            }
          }
          // Fetch host phone number
          final hostId = data['player_id'] as String;
          final hostDocSnap = await db.collection('users').where('firebase_uid', isEqualTo: hostId).limit(1).get();
          if (hostDocSnap.docs.isNotEmpty) {
            data['host_phone'] = hostDocSnap.docs.first.data()['phone'] ?? '';
          }

          data['id'] = bookingDoc.id;
          activities.add(data);
        }
      }
    }
    return activities;
  });
});

/// Combined provider
final userActivitiesProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final direct = ref.watch(directBookingsProvider);
  final joined = ref.watch(joinedBookingsProvider);

  if (direct is AsyncError) return direct;
  if (joined is AsyncError) return joined;
  if (direct is AsyncLoading || joined is AsyncLoading) return const AsyncLoading();

  final all = [...direct.value!, ...joined.value!];
  // Sort by date descending
  all.sort((a, b) => (b['booking_date'] as Timestamp).compareTo(a['booking_date'] as Timestamp));
  
  // Remove duplicates (if any)
  final seenIds = <String>{};
  final unique = all.where((a) => seenIds.add(a['id'] as String)).toList();
  
  return AsyncValue.data(unique);
});

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDataProvider);
    final activitiesAsync = ref.watch(userActivitiesProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5CA),
      appBar: userAsync.when(
        data: (data) => MainHeader(
          userName: data?['full_name'] ?? 'Người dùng',
          avatarBase64: data?['avatar_base64'],
        ),
        loading: () => const MainHeader(userName: '...'),
        error: (_, __) => const MainHeader(userName: 'Người dùng'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'HOẠT ĐỘNG',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6136),
              ),
            ),
            const SizedBox(height: 16),

            /// TAB BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: const Color(0xFF4A6136),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Sắp tới'),
                    Tab(text: 'Kết thúc'),
                    Tab(text: 'Đã hủy'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// TAB VIEWS
            Expanded(
              child: activitiesAsync.when(
                data: (activities) {
                  final now = DateTime.now();

                    final upcoming = activities.where((a) {
                      final date = (a['booking_date'] as Timestamp).toDate();
                      final status = a['status'] as String;
                      final endTime = a['end_time'] as String? ?? '00:00';
                      
                      final isUpcomingStatus = status == 'confirmed' || status == 'ongoing' || status == 'cancellation_pending';
                      
                      try {
                        final endParts = endTime.split(':');
                        final endDateTime = DateTime(date.year, date.month, date.day, int.parse(endParts[0]), int.parse(endParts[1]));
                        return isUpcomingStatus && endDateTime.isAfter(now);
                      } catch (e) {
                        return isUpcomingStatus && date.isAfter(now.subtract(const Duration(days: 1)));
                      }
                    }).toList();

                  final finished = activities.where((a) {
                    final date = (a['booking_date'] as Timestamp).toDate();
                    final status = a['status'] as String;
                    final endTime = a['end_time'] as String? ?? '00:00';

                    try {
                      final endParts = endTime.split(':');
                      final endDateTime = DateTime(date.year, date.month, date.day, int.parse(endParts[0]), int.parse(endParts[1]));
                      return status == 'confirmed' && endDateTime.isBefore(now);
                    } catch (e) {
                      return status == 'confirmed' && date.isBefore(now.subtract(const Duration(days: 1)));
                    }
                  }).toList();

                  final cancelled = activities.where((a) => a['status'] == 'cancelled').toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActivityList(upcoming, 'upcoming'),
                      _buildActivityList(finished, 'finished'),
                      _buildActivityList(cancelled, 'cancelled'),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Lỗi: $err')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MainFooter(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunityScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiChatScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: const FixedCenterDockedFabLocation(),
    );
  }

  Widget _buildActivityList(List<Map<String, dynamic>> list, String category) {
    if (list.isEmpty) {
      return const Center(child: Text('Không có hoạt động nào'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return ActivityCard(
          data: list[index],
          category: category,
        );
      },
    );
  }
}
