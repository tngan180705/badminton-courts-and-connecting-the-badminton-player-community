import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_post_model.dart';
import '../models/match_member_model.dart';

class MatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy danh sách các kèo đang mở
  Future<List<MatchPostModel>> getOpenMatchPosts() async {
    final snapshot = await _firestore
        .collection('match_posts')
        .where('status', isEqualTo: 'open')
        .get();
    return snapshot.docs
        .map((doc) => MatchPostModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // Tham gia vào một kèo
  Future<void> joinMatch(MatchMemberModel member) async {
    await _firestore.collection('match_members').add(member.toFirestore());
  }
}
