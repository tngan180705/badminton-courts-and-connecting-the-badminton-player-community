import 'package:badminton_app/data/models/user_model.dart';
import 'package:badminton_app/presentation/features/court/providers/user_repository_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state_provider.dart';

final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .where('firebase_uid', isEqualTo: user.uid)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) {
      return null;
    }

    final data = snapshot.docs.first.data();
    data['id'] = snapshot.docs.first.id;
    return data;
  });
});

final userByIdProvider =
    FutureProvider.family<UserModel?, String>((ref, String userId) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserById(userId);
});

final userStatsProvider = StreamProvider<Map<String, int>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  
  if (user == null) return Stream.value({'totalMatches': 0});

  final db = FirebaseFirestore.instance;

  return db
      .collection('match_members')
      .where('user_id', isEqualTo: user.uid)
      .snapshots()
      .asyncMap((memberSnap) async {
    final joinedCount = memberSnap.size;
    final hostedSnap = await db
        .collection('match_posts')
        .where('host_id', isEqualTo: user.uid)
        .get();
    
    return {'totalMatches': joinedCount + hostedSnap.size};
  });
});