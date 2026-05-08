import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/review_model.dart';
import '../providers/review_provider.dart';
import '../../auth/providers/user_provider.dart';

class ReviewMemberDialog extends ConsumerStatefulWidget {
  final String bookingId;

  const ReviewMemberDialog({super.key, required this.bookingId});

  @override
  ConsumerState<ReviewMemberDialog> createState() => _ReviewMemberDialogState();
}

class _ReviewMemberDialogState extends ConsumerState<ReviewMemberDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _selectedMember;

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    final db = FirebaseFirestore.instance;
    final members = <Map<String, dynamic>>[];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) return [];

    // Lấy danh sách những người đã bị đánh giá trong trận này
    final reviewedSnap = await db.collection('reviews')
        .where('booking_id', isEqualTo: widget.bookingId)
        .where('from_user_id', isEqualTo: currentUserId)
        .get();
    
    final reviewedUserIds = reviewedSnap.docs.map((d) => d['to_user_id'] as String).toSet();

    // 1. Lấy match_post từ bookingId
    final matchSnapshot = await db
        .collection('match_posts')
        .where('booking_id', isEqualTo: widget.bookingId)
        .limit(1)
        .get();

    if (matchSnapshot.docs.isEmpty) {
      // Nếu không có match_post, lấy player_id từ booking
      final bookingDoc = await db.collection('bookings').doc(widget.bookingId).get();
      if (bookingDoc.exists) {
        final userId = bookingDoc.data()?['player_id']; 
        if (userId != null && userId != currentUserId && !reviewedUserIds.contains(userId)) {
          final userSnap = await db.collection('users').where('firebase_uid', isEqualTo: userId).limit(1).get();
          if (userSnap.docs.isNotEmpty) {
            final u = userSnap.docs.first.data();
            members.add({...u, 'isHost': true});
          }
        }
      }
      return members;
    }

    final matchPostId = matchSnapshot.docs.first.id;
    final matchPostData = matchSnapshot.docs.first.data();
    final hostId = matchPostData['host_id'];

    // 2. Lấy thông tin host (nếu không phải mình và chưa đánh giá)
    if (hostId != currentUserId && !reviewedUserIds.contains(hostId)) {
      final hostSnap = await db.collection('users').where('firebase_uid', isEqualTo: hostId).limit(1).get();
      if (hostSnap.docs.isNotEmpty) {
        final h = hostSnap.docs.first.data();
        members.add({...h, 'isHost': true});
      }
    }

    // 3. Lấy thông tin thành viên (trừ mình)
    final membersSnap = await db
        .collection('match_members')
        .where('match_post_id', isEqualTo: matchPostId)
        .get();

    for (var doc in membersSnap.docs) {
      final userId = doc.data()['user_id'];
      if (userId == hostId || userId == currentUserId || reviewedUserIds.contains(userId)) continue; 
      
      final userSnap = await db.collection('users').where('firebase_uid', isEqualTo: userId).limit(1).get();
      if (userSnap.docs.isNotEmpty) {
        final u = userSnap.docs.first.data();
        members.add({...u, 'isHost': false});
      }
    }

    return members;
  }

  Future<void> _submitReview() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thành viên để đánh giá')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung đánh giá')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final userData = ref.read(userDataProvider).value;
      
      final review = ReviewModel(
        reviewId: '',
        fromUserId: currentUser.uid,
        toUserId: _selectedMember!['firebase_uid'],
        bookingId: widget.bookingId,
        ratingScore: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        fromUserName: userData?['full_name'] ?? 'Người dùng',
        fromUserAvatar: userData?['avatar_base64'],
      );

      final repo = ref.read(reviewRepositoryProvider);
      await repo.addPlayerReview(review);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi đánh giá thành viên!'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Đánh giá thành viên',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            if (_selectedMember == null) ...[
              const Text('Chọn thành viên bạn muốn đánh giá:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchMembers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text('Bạn đã đánh giá tất cả thành viên trong trận này, hoặc không có thành viên nào khác.', textAlign: TextAlign.center,),
                    );
                  }

                  final members = snapshot.data!;

                  return SizedBox(
                    height: 200, // Fixed height for list
                    child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (member['avatar_base64'] != null && member['avatar_base64'].isNotEmpty)
                                ? MemoryImage(base64Decode(member['avatar_base64']))
                                : null,
                            child: (member['avatar_base64'] == null || member['avatar_base64'].isEmpty)
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Text(member['full_name'] ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(member['isHost'] ? 'Chủ sân' : 'Thành viên', style: const TextStyle(fontSize: 12)),
                          onTap: () {
                            setState(() => _selectedMember = member);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ] else ...[
              // Đã chọn thành viên -> Hiện form đánh giá
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: (_selectedMember!['avatar_base64'] != null && _selectedMember!['avatar_base64'].isNotEmpty)
                        ? MemoryImage(base64Decode(_selectedMember!['avatar_base64']))
                        : null,
                    child: (_selectedMember!['avatar_base64'] == null || _selectedMember!['avatar_base64'].isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đang đánh giá:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        Text(_selectedMember!['full_name'] ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: () => setState(() => _selectedMember = null),
                    tooltip: 'Đổi người khác',
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung đánh giá...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
              ),
            ],

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 10),
                if (_selectedMember != null)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Gửi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
