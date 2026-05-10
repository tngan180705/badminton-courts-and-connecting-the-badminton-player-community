import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionInfoCard extends StatelessWidget {
  final Map<String, dynamic> transactionData;

  const TransactionInfoCard({super.key, required this.transactionData});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final createdAt = (transactionData['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dateFormatter = DateFormat('HH:mm - dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Chờ duyệt',
                        style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      dateFormatter.format(createdAt),
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE5E5CA),
                      child: Icon(Icons.receipt_long, color: Color(0xFF4A6136)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking ID: ${transactionData['booking_id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Nội dung: ${transactionData['transfer_content'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Số tiền:', style: TextStyle(color: Colors.black54)),
                    Text(
                      '${currencyFormatter.format(transactionData['amount'] ?? 0)} đ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4A6136)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Button
          InkWell(
            onTap: () => _approveTransaction(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF4A6136),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Center(
                child: Text(
                  'Xác nhận đã nhận tiền',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveTransaction(BuildContext context) async {
    final db = FirebaseFirestore.instance;
    final bookingId = transactionData['booking_id'];
    final transactionId = transactionData['id'];

    try {
      // Use a batch for atomicity
      final batch = db.batch();

      // 1. Update Transaction
      batch.update(db.collection('transactions').doc(transactionId), {
        'status': 'confirmed',
      });

      // 2. Update Booking
      batch.update(db.collection('bookings').doc(bookingId), {
        'status': 'confirmed',
      });

      // 3. Find associated Match Post and update its status
      final matchPostQuery = await db.collection('match_posts')
          .where('booking_id', isEqualTo: bookingId)
          .get();
      
      for (var doc in matchPostQuery.docs) {
        batch.update(doc.reference, {
          'status': 'open',
        });
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận giao dịch thành công')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
}
