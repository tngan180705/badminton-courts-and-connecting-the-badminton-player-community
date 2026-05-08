import 'package:badminton_app/presentation/features/profile/pages/profile_screen.dart';
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
final userActivitiesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('bookings')
      .where('player_id', isEqualTo: user.uid)
      .snapshots()
      .asyncMap((snapshot) async {
    final activities = <Map<String, dynamic>>[];
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final subCourtId = data['sub_court_id'] as String;
      
      // Fetch sub-court and court info
      final subCourtDoc = await FirebaseFirestore.instance
          .collection('sub_courts')
          .doc(subCourtId)
          .get();
      
      if (subCourtDoc.exists) {
        final subCourtData = subCourtDoc.data()!;
        final courtId = subCourtData['court_id'] as String;
        
        final courtDoc = await FirebaseFirestore.instance
            .collection('courts')
            .doc(courtId)
            .get();
        
        if (courtDoc.exists) {
          final courtData = courtDoc.data()!;
          data['sub_court_name'] = subCourtData['name'];
          data['court_name'] = courtData['name'];
        }
      }
      
      data['id'] = doc.id;
      activities.add(data);
    }
    
    return activities;
  });
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
    
    final nowStr = DateFormat('HH:mm - EEEE, dd/MM/yyyy', 'vi_VN').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5CA), // Match the background in image
      appBar: const MainHeader(),
      body: SafeArea(
        child: Column(
          children: [
            /// UPDATE TIME
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    'Cập nhật lúc: $nowStr',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              'HOẠT ĐỘNG',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A6136), // Darker green for title
              ),
            ),
            const SizedBox(height: 16),

            /// TABS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF4A6136),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF4A6136),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
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
                  final upcoming = activities.where((a) {
                    final date = (a['booking_date'] as Timestamp).toDate();
                    final status = a['status'] as String;
                    return status == 'confirmed' && date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
                  }).toList();

                  final finished = activities.where((a) {
                    final date = (a['booking_date'] as Timestamp).toDate();
                    final status = a['status'] as String;
                    return status == 'confirmed' && date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                  }).toList();

                  final cancelled = activities.where((a) => a['status'] == 'cancelled').toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActivityList(upcoming),
                      _buildActivityList(finished),
                      _buildActivityList(cancelled),
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              ),
            );
          }

          else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityScreen(),
              ),
            );
          }

          else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF4A6136),
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildActivityList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Không có hoạt động nào'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return ActivityCard(data: list[index]);
      },
    );
  }
}
