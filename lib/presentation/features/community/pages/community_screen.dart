import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../common_widgets/main_header.dart';
import '../../../common_widgets/main_footer.dart';
import '../widgets/match_card.dart';
import '../providers/community_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../widgets/post_match_bottom_sheet.dart';
import '../widgets/match_detail_dialog.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/match_post_view_model.dart';
import 'match_join_handler.dart';
import 'community_tab_bar.dart';
import '../../activity/pages/activity_screen.dart';
import '../../court/pages/home_screen.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  static const List<String> _skillLevels = [
    'Tất cả',
    'Mới bắt đầu',
    'Chơi ổn',
    'Chơi tốt',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(communityTabProvider);
    final skillFilter = ref.watch(skillFilterProvider);
    final userAsync = ref.watch(userDataProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final postsAsync = currentTab == 1
        ? ref.watch(myPostsProvider)
        : ref.watch(filteredPostsProvider);

    final userName = userAsync.maybeWhen(
      data: (data) => data?['full_name'] ?? 'Người dùng',
      orElse: () => 'Người dùng',
    );

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
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'TÌM ĐỒNG ĐỘI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF407F3E),
              ),
            ),
          ),
          _buildSkillFilter(ref, skillFilter),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CommunityTabBar(
              currentTab: currentTab,
              onTabChanged: (index) =>
                  ref.read(communityTabProvider.notifier).state = index,
              onPostPress: () => _openPostSheet(context),
            ),
          ),
          const SizedBox(height: 8),
          _buildPostsList(context, ref, postsAsync, currentTab, currentUserId),
        ],
      ),
      bottomNavigationBar: MainFooter(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ActivityScreen(),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPostSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildSkillFilter(WidgetRef ref, String skillFilter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: skillFilter,
              items: _skillLevels
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(skillFilterProvider.notifier).state = val;
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<MatchPostViewModel>> postsAsync,
    int currentTab,
    String currentUserId,
  ) {
    return Expanded(
      child: postsAsync.when(
        data: (posts) => posts.isEmpty
            ? Center(
                child: Text(
                  currentTab == 1
                      ? 'Bạn chưa có trận nào trong 7 ngày tới'
                      : 'Không có trận nào trong 7 ngày tới',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final match = posts[index];
                  final isMyPost = match.hostId == currentUserId ||
                      match.memberIds.contains(currentUserId);

                  return MatchCard(
                    match: match,
                    isMyPost: isMyPost,
                    onJoinPressed: !isMyPost
                        ? () => MatchJoinHandler.handleJoinMatch(
                            context, ref, match)
                        : null,
                    onDetailPressed: isMyPost
                        ? () => _showMatchDetail(context, match)
                        : null,
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  void _showMatchDetail(BuildContext context, MatchPostViewModel match) {
    showDialog(
      context: context,
      builder: (context) => MatchDetailDialog(match: match),
    );
  }

  void _openPostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PostMatchBottomSheet(),
    );
  }
}
