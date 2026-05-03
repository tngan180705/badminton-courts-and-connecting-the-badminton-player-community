import 'package:badminton_app/data/models/court_model.dart';
import 'package:badminton_app/presentation/features/admin/court_management/pages/add_edit_court_screen.dart';
import 'package:badminton_app/presentation/features/admin/court_management/providers/admin_court_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Thêm thư viện này để định dạng tiền

class AdminCourtCard extends ConsumerWidget {
  final CourtModel court;

  const AdminCourtCard({super.key, required this.court});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Định dạng tiền tệ: 50000 -> 50.000
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN HÌNH ẢNH ---
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: court.imageUrl.startsWith('assets/')
                    ? Image.asset(
                        court.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported, size: 40),
                      )
                    : Image.network(
                        court.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 40),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // --- PHẦN THÔNG TIN ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Hiển thị Địa chỉ
                  _buildInfoRow(
                      Icons.location_on_outlined, "Địa chỉ: ${court.address}"),

                  // Hiển thị Giá tiền (đã format)
                  _buildInfoRow(Icons.payments_outlined,
                      "Giá: ${currencyFormatter.format(court.pricePerHour)}đ/h"),

                  // HIỂN THỊ GIỜ HOẠT ĐỘNG (Phần bạn muốn thêm)
                  _buildInfoRow(Icons.access_time,
                      "Giờ: ${court.openTime} - ${court.closeTime}"),
                ],
              ),
            ),

            // --- PHẦN NÚT THAO TÁC ---
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditCourtScreen(court: court),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _showDeleteDialog(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Hàm phụ để tạo các dòng thông tin nhỏ kèm icon
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có muốn xóa sân "${court.name}" không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await ref
                  .read(adminCourtActionProvider.notifier)
                  .removeCourt(court.courtId);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
