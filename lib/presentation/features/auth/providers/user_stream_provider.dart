import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final userByFirebaseUidProvider =
    StreamProvider.family<Map<String, dynamic>?, String>(
  (ref, firebaseUid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;

      return data;
    });
  },
);