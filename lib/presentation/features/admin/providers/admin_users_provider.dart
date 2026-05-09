import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────
// STREAM: Tất cả users, realtime
// ─────────────────────────────────────────────

final adminUsersStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final db = FirebaseFirestore.instance;

  return db
      .collection('users')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snap) {
    return snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['id'] = d.id;

      // Normalise created_at → DateTime
      final raw = m['created_at'];
      if (raw is Timestamp) {
        m['created_at'] = raw.toDate();
      }
      return m;
    }).toList();
  });
});

// ─────────────────────────────────────────────
// FUTURE: Lịch sử booking của 1 user
// ─────────────────────────────────────────────

final userBookingsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final db = FirebaseFirestore.instance;

  final snap = await db
      .collection('bookings')
      .where('user_id', isEqualTo: userId)
      .orderBy('created_at', descending: true)
      .limit(20)
      .get();

  return snap.docs.map((d) {
    final m = Map<String, dynamic>.from(d.data());
    m['id'] = d.id;
    final raw = m['created_at'];
    if (raw is Timestamp) m['created_at'] = raw.toDate();
    return m;
  }).toList();
});

// ─────────────────────────────────────────────
// FUTURE: Lịch sử giao dịch của 1 user
// ─────────────────────────────────────────────

final userTransactionsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final db = FirebaseFirestore.instance;

  final snap = await db
      .collection('transactions')
      .where('user_id', isEqualTo: userId)
      .orderBy('created_at', descending: true)
      .limit(20)
      .get();

  return snap.docs.map((d) {
    final m = Map<String, dynamic>.from(d.data());
    m['id'] = d.id;
    final raw = m['created_at'];
    if (raw is Timestamp) m['created_at'] = raw.toDate();
    return m;
  }).toList();
});