class TransactionModel {
  final String transactionId; // Prefix: TX_
  final String userId;
  final String? bookingId;
  final double amount;
  final String type; // coc, thanh toán, hoàn tiền, rút tiền
  final String paymentType; // full_payment, deposit
  final String paymentMethod; // ck, tiền mặt
  final String status; // pending, confirmed, rejected
  final String transferContent; // Nội dung chuyển khoản (không dấu)
  final DateTime createdAt;

  TransactionModel({
    required this.transactionId,
    required this.userId,
    this.bookingId,
    required this.amount,
    required this.type,
    required this.paymentType,
    required this.paymentMethod,
    required this.status,
    required this.transferContent,
    required this.createdAt,
  });

  factory TransactionModel.fromFirestore(Map<String, dynamic> json, String id) {
    return TransactionModel(
      transactionId: id,
      userId: json['user_id'] ?? '',
      bookingId: json['booking_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'payment',
      paymentType: json['payment_type'] ?? 'full_payment',
      paymentMethod: json['payment_method'] ?? 'Chuyển khoản ngân hàng',
      status: json['status'] ?? 'pending',
      transferContent: json['transfer_content'] ?? '',
      createdAt: (json['created_at'] != null)
          ? json['created_at'].toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'booking_id': bookingId,
      'amount': amount,
      'type': type,
      'payment_type': paymentType,
      'payment_method': paymentMethod,
      'status': status,
      'transfer_content': transferContent,
      'created_at': createdAt,
    };
  }
}
