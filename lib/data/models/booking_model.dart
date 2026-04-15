class BookingModel {
  final String bookingId; // Prefix: BK_
  final String playerId;
  final String subCourtId;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final double totalPrice;
  final String paymentMethod;
  final bool checkInStatus; // Thống nhất dùng camelCase ở đây
  final DateTime createdAt;

  BookingModel({
    required this.bookingId,
    required this.playerId,
    required this.subCourtId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalPrice,
    required this.paymentMethod,
    required this.checkInStatus,
    required this.createdAt,
  });

  // Chuyển từ Firestore JSON sang Object Flutter
  factory BookingModel.fromFirestore(Map<String, dynamic> json, String id) {
    return BookingModel(
      bookingId: id,
      playerId: json['player_id'] ?? '',
      subCourtId: json['sub_court_id'] ?? '',
      bookingDate: (json['booking_date'] != null)
          ? json['booking_date'].toDate()
          : DateTime.now(),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? 'pending',
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? 'cash',
      checkInStatus:
          json['check_in_status'] ?? false, // Đọc từ snake_case của DB
      createdAt: (json['created_at'] != null)
          ? json['created_at'].toDate()
          : DateTime.now(),
    );
  }

  // Chuyển từ Object Flutter sang JSON để đẩy lên Firebase (Hàm này giúp hết lỗi Repository)
  Map<String, dynamic> toFirestore() {
    return {
      'player_id': playerId,
      'sub_court_id': subCourtId,
      'booking_date': bookingDate,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'total_price': totalPrice,
      'payment_method': paymentMethod,
      'check_in_status': checkInStatus, // Đẩy lên DB dạng snake_case
      'created_at': createdAt,
    };
  }
}
