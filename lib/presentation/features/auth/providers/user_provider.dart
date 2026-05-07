import 'package:badminton_app/data/models/user_model.dart';
import 'package:badminton_app/presentation/features/court/providers/user_repository_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;

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

    return snapshot.docs.first.data();
  });
});
final userByIdProvider =
    FutureProvider.family<UserModel?, String>((ref, String userId) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserById(userId);
});