import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

class MemberListDialog extends StatelessWidget {
  final String bookingId;

  const MemberListDialog({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách thành viên',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Chưa có thành viên nào tham gia'),
                  );
                }

                final members = snapshot.data!;

                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.secondary.withOpacity(0.3),
                          backgroundImage: (member['avatar_base64'] != null && member['avatar_base64'].isNotEmpty)
                              ? MemoryImage(base64Decode(member['avatar_base64']))
                              : null,
                          child: (member['avatar_base64'] == null || member['avatar_base64'].isEmpty)
                              ? const Icon(Icons.person, color: AppColors.secondary)
                              : null,
                        ),
                        title: Text(
                          member['full_name'] ?? 'Người dùng',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(member['isHost'] ? 'Chủ sân' : 'Thành viên'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ((member['reliability_score'] ?? 100) / 100 * 5).toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                          ],
                        ),
                        onTap: () {
                          _showUserDetail(context, member);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    final db = FirebaseFirestore.instance;
    final members = <Map<String, dynamic>>[];

    // 1. Find the match post for this booking
    final matchSnapshot = await db
        .collection('match_posts')
        .where('booking_id', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (matchSnapshot.docs.isEmpty) {
      // If no match post, maybe just show the host (the one who booked)
      final bookingDoc = await db.collection('bookings').doc(bookingId).get();
      if (bookingDoc.exists) {
        final userId = bookingDoc.data()?['user_id'];
        if (userId != null) {
          final userSnap = await db.collection('users').where('firebase_uid', isEqualTo: userId).limit(1).get();
          if (userSnap.docs.isNotEmpty) {
            final u = userSnap.docs.first.data();
            members.add({
              ...u,
              'isHost': true,
            });
          }
        }
      }
      return members;
    }

    final matchPostId = matchSnapshot.docs.first.id;
    final matchPostData = matchSnapshot.docs.first.data();
    final hostId = matchPostData['host_id'];

    // 2. Fetch host
    final hostSnap = await db.collection('users').where('firebase_uid', isEqualTo: hostId).limit(1).get();
    if (hostSnap.docs.isNotEmpty) {
      final h = hostSnap.docs.first.data();
      members.add({
        ...h,
        'isHost': true,
      });
    }

    // 3. Fetch joined members
    final membersSnap = await db
        .collection('match_members')
        .where('match_post_id', isEqualTo: matchPostId)
        .get();

    for (var doc in membersSnap.docs) {
      final userId = doc.data()['user_id'];
      if (userId == hostId) continue; // Skip if host is also in match_members (shouldn't be based on logic usually)
      
      final userSnap = await db.collection('users').where('firebase_uid', isEqualTo: userId).limit(1).get();
      if (userSnap.docs.isNotEmpty) {
        final u = userSnap.docs.first.data();
        members.add({
          ...u,
          'isHost': false,
        });
      }
    }

    return members;
  }

  void _showUserDetail(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.secondary.withOpacity(0.3),
              backgroundImage: (user['avatar_base64'] != null && user['avatar_base64'].isNotEmpty)
                  ? MemoryImage(base64Decode(user['avatar_base64']))
                  : null,
              child: (user['avatar_base64'] == null || user['avatar_base64'].isEmpty)
                  ? const Icon(Icons.person, color: AppColors.secondary, size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user['full_name'] ?? 'Người dùng',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ((user['reliability_score'] ?? 100) / 100 * 5).toStringAsFixed(1),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                const Text('(Độ tin cậy)', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailItem(Icons.phone, 'Số điện thoại', user['phone'] ?? 'Chưa cập nhật'),
            _buildDetailItem(Icons.email, 'Email', user['email'] ?? 'Chưa cập nhật'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Đóng', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }
}
