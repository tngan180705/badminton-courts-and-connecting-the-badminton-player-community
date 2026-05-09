import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final db = FirebaseFirestore.instance;

  return Stream.fromFuture(Future.wait([
    db.collection('users').get(),
    db.collection('sub_courts').get(),
    db.collection('bookings').get(),
    db.collection('transactions').where('status', isEqualTo: 'confirmed').get(),
  ])).asyncExpand((results) async* {
    // This is just to get initial counts, but we want it to react to changes.
    // A better way is to listen to each collection.
    
    final usersStream = db.collection('users').snapshots();
    final subCourtsStream = db.collection('sub_courts').snapshots();
    final bookingsStream = db.collection('bookings').snapshots();
    final transactionsStream = db.collection('transactions').where('status', isEqualTo: 'confirmed').snapshots();

    yield* Stream.fromFuture(Future.value(null)).asyncExpand((_) async* {
      // Use Rx.combineLatest if available, but for now we can just yield on any update
      // Actually simpler to just listen to them individually if we don't have RxDart
      // For now, let's keep it simple with snapshots.
    });
  });
});

// A simpler way to get combined stats
final adminStatsStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final db = FirebaseFirestore.instance;
  
  return db.collection('bookings').snapshots().asyncMap((_) async {
    final users = await db.collection('users').get();
    final subCourts = await db.collection('sub_courts').get();
    final bookings = await db.collection('bookings').get();
    
    // Calculate total revenue from confirmed transactions
    final transactions = await db.collection('transactions')
        .where('status', isEqualTo: 'confirmed')
        .get();
        
    double totalRevenue = 0;
    for (var doc in transactions.docs) {
      totalRevenue += (doc.data()['amount'] ?? 0).toDouble();
    }

    // Get today's bookings count
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final todayBookings = await db.collection('bookings')
        .where('created_at', isGreaterThanOrEqualTo: todayStart)
        .where('created_at', isLessThan: todayEnd)
        .get();

    return {
      'userCount': users.size,
      'courtCount': subCourts.size,
      'bookingCount': bookings.size,
      'totalRevenue': totalRevenue,
      'todayBookingCount': todayBookings.size,
    };
  });
});

final allUsersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance.collection('users').snapshots().map((snap) {
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  });
});

final pendingTransactionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('transactions')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snap) {
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  });
});

final adminBookingsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance.collection('bookings')
      .orderBy('booking_date', descending: false)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        
        // Sort by start_time as well
        list.sort((a, b) {
          DateTime dateA;
          final rawA = a['booking_date'];
          if (rawA is Timestamp) {
            dateA = rawA.toDate();
          } else if (rawA is String) {
            if (rawA.contains('/')) {
              final parts = rawA.split('/');
              dateA = parts.length == 3 ? DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0])) : DateTime.now();
            } else {
              dateA = DateTime.tryParse(rawA) ?? DateTime.now();
            }
          } else {
            dateA = DateTime.now();
          }

          DateTime dateB;
          final rawB = b['booking_date'];
          if (rawB is Timestamp) {
            dateB = rawB.toDate();
          } else if (rawB is String) {
            if (rawB.contains('/')) {
              final parts = rawB.split('/');
              dateB = parts.length == 3 ? DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0])) : DateTime.now();
            } else {
              dateB = DateTime.tryParse(rawB) ?? DateTime.now();
            }
          } else {
            dateB = DateTime.now();
          }

          final cmp = dateA.compareTo(dateB);
          if (cmp != 0) return cmp;
          
          final timeA = a['start_time']?.toString() ?? '00:00';
          final timeB = b['start_time']?.toString() ?? '00:00';
          return timeA.compareTo(timeB);
        });
        
        return list;
      });
});

final subCourtsListProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance.collection('sub_courts').snapshots().map((snap) {
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  });
});

final userNameProvider = FutureProvider.family<String, String>((ref, userId) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .where('firebase_uid', isEqualTo: userId)
      .limit(1)
      .get();
  if (snap.docs.isNotEmpty) {
    return snap.docs.first.data()['full_name'] ?? 'Khách lạ';
  }
  return 'Khách lạ';
});

final subCourtNameProvider = FutureProvider.family<String, String>((ref, subCourtId) async {
  final doc = await FirebaseFirestore.instance.collection('sub_courts').doc(subCourtId).get();
  return doc.data()?['sub_court_name'] ?? 'Sân $subCourtId';
});
