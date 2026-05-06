import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/match_post_view_model.dart';
import '../providers/community_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchJoinHandler {
  static Future<String> _generateMatchMemberId() async {
    final db = FirebaseFirestore.instance;
    final snapshot = await db.collection('match_members').get();

    int maxNum = 0;
    for (final doc in snapshot.docs) {
      final id = doc.id;
      if (id.startsWith('MM_')) {
        final numStr = id.replaceFirst('MM_', '');
        final num = int.tryParse(numStr) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }

    final nextNum = maxNum + 1;
    return 'MM_${nextNum.toString().padLeft(3, '0')}';
  }

  static Future<void> handleJoinMatch(
    BuildContext context,
    WidgetRef ref,
    MatchPostViewModel match,
  ) async {
    final db = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser!;

    try {
      final memberId = await _generateMatchMemberId(); // 👈 generate ID

      if (match.slotsNeeded <= 1) {
        // Add member
        await db.collection('match_members').doc(memberId).set({
          // 👈 dùng memberId
          'match_post_id': match.matchPostId,
          'user_id': currentUser.uid,
          'joined_at': Timestamp.now(),
        });

        // Update slots
        await db.collection('match_posts').doc(match.matchPostId).update({
          'slots_needed': 0,
          'status': 'full',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đủ thành viên')),
        );
      } else {
        // Add member
        await db.collection('match_members').doc(memberId).set({
          // 👈 dùng memberId
          'match_post_id': match.matchPostId,
          'user_id': currentUser.uid,
          'joined_at': Timestamp.now(),
        });

        // Decrement slots
        await db.collection('match_posts').doc(match.matchPostId).update({
          'slots_needed': match.slotsNeeded - 1,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Còn thiếu ${match.slotsNeeded - 1} người'),
          ),
        );
      }

      // Invalidate providers
      ref.invalidate(communityPostsProvider);
      ref.invalidate(filteredPostsProvider);
      ref.invalidate(myPostsProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
}
