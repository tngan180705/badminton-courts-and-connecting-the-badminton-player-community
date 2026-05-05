import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state_provider.dart';

final userDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return doc.data();
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
