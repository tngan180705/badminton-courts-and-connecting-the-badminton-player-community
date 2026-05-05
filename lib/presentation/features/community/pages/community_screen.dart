import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../common_widgets/main_header.dart';
import '../../../common_widgets/main_footer.dart';
import '../widgets/match_card.dart';
import '../providers/community_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../widgets/post_match_bottom_sheet.dart';
import '../../../../data/models/match_post_view_model.dart';
import '../../../../core/constants/app_colors.dart';

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

    // Lấy đúng kiểu AsyncValue<List<MatchPostViewModel>>
    final AsyncValue<List<MatchPostViewModel>> postsAsync = currentTab == 1
        ? ref.watch(myPostsProvider)
        : ref.watch(filteredPostsProvider);

    final userName = userAsync.maybeWhen(
      data: (data) => data?['full_name'] ?? 'Người dùng',
      orElse: () => 'Người dùng',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5CA),
      appBar: MainHeader(userName: userName),
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

          // Dropdown filter trình độ
          Padding(
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
                              child:
                                  Text(s, style: const TextStyle(fontSize: 13)),
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
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTabBar(context, ref, currentTab),
          ),

          const SizedBox(height: 8),

          Expanded(
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
                        final MatchPostViewModel match = posts[index];
                        return MatchCard(
                          match: match,
                          onJoinPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã tham gia: ${match.title}'),
                              ),
                            );
                          },
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MainFooter(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: AI sau
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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

  Widget _buildTabBar(BuildContext context, WidgetRef ref, int currentTab) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTab(context, ref, 0, currentTab, 'Tất cả trận'),
        _buildTab(context, ref, 1, currentTab, 'Trận của tôi'),
        _buildTab(context, ref, 2, currentTab, '+ Đăng tin mới'),
      ],
    );
  }

  Widget _buildTab(
    BuildContext context,
    WidgetRef ref,
    int index,
    int currentTab,
    String label,
  ) {
    final isSelected = currentTab == index;

    final bgColor = index == 2
        ? const Color(0xFFDBD46B)
        : (isSelected ? const Color(0xFF407F3E) : Colors.white);

    final textColor = index == 2
        ? Colors.black87
        : (isSelected ? Colors.white : Colors.black54);

    final borderColor = index == 2
        ? const Color(0xFFDBD46B)
        : (isSelected ? const Color(0xFF407F3E) : Colors.grey[300]!);

    return GestureDetector(
      onTap: () {
        if (index == 2) {
          return;
        }
        //ref.read(communityTabProvider.notifier).state = index;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
