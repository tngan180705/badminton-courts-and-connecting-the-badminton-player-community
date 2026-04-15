class TransactionModel {
  final String transactionId; // Prefix: TX_
  final String userId;
  final String? bookingId; // Nullable cho trường hợp nạp/rút tiền
  final double amount;
  final String type; // deposit, payment, refund, withdraw
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  TransactionModel({
    required this.transactionId,
    required this.userId,
    this.bookingId,
    required this.amount,
    required this.type,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  // Chuyển từ Firestore JSON sang Object Flutter
  factory TransactionModel.fromFirestore(Map<String, dynamic> json, String id) {
    return TransactionModel(
      transactionId: id,
      userId: json['user_id'] ?? '',
      bookingId: json['booking_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'payment',
      paymentMethod: json['payment_method'] ?? 'cash',
      status: json['status'] ?? 'pending',
      createdAt: (json['created_at'] != null)
          ? json['created_at'].toDate()
          : DateTime.now(),
    );
  }

  // Chuyển từ Object Flutter sang JSON để lưu lên Firebase
  // Hàm này sẽ giúp TransactionRepository hết báo lỗi gạch đỏ
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'booking_id': bookingId, // Sẽ lưu là null nếu không có ID
      'amount': amount,
      'type': type,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt,
    };
  }
}
