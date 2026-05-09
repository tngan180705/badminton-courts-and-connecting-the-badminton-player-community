import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  Future<List<BookingModel>> getBookingsByUserId(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('player_id', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> createBooking(BookingModel booking) async {
    await _firestore.collection(_collection).add(booking.toFirestore());
  }

  Future<int> getTotalBookings() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ getTotalBookings error: $e');
      return 0;
    }
  }

  /// Lọc booking có booking_date đúng ngày hôm nay
  Future<int> getTodayBookings() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfNextDay = DateTime(now.year, now.month, now.day + 1);

      final snapshot = await _firestore
          .collection(_collection)
          .where(
            'booking_date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'booking_date',
            isLessThan: Timestamp.fromDate(startOfNextDay),
          )
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ getTodayBookings error: $e');
      return 0;
    }
  }
}