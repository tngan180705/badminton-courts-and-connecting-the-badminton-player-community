import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider to listen to real-time updates for any user's profile
final userProfileProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, userId) {
  if (userId.isEmpty) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('users')
      .where('firebase_uid', isEqualTo: userId)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isNotEmpty ? snap.docs.first.data() : null);
});
