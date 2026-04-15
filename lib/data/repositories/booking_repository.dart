import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  // Lấy danh sách đặt sân của một User (Prefix: BK_)
  Future<List<BookingModel>> getBookingsByUserId(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('player_id', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // Tạo đơn đặt sân mới
  Future<void> createBooking(BookingModel booking) async {
    await _firestore.collection(_collection).add(booking.toFirestore());
  }
}
