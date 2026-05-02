import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../data/models/court_model.dart';
import '../pages/court_detail_screen.dart';

class CourtCard extends StatelessWidget {
  final CourtModel court;
  const CourtCard({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    // XỬ LÝ TÊN FILE:
    // 1. .trim() để xóa khoảng trắng thừa ở cuối tên (Firestore của bạn đang bị dư dấu cách)
    // 2. Chuyển chữ thường, xóa dấu cách giữa, đổi 'â' thành 'a'
    String fileName = court.name
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('â', 'a');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CourtDetailScreen(court: court)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusL)),
                child: Image.asset(
                  'assets/images/$fileName.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    // Thử tìm file .png nếu không có .jpg
                    return Image.asset(
                      'assets/images/$fileName.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, _, __) => Container(
                        color: Colors.grey[100],
                        width: double.infinity,
                        // Dùng Center để icon không bị kéo giãn theo chiều dọc
                        child: const Center(
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey, size: 40),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.spaceSmall),
              child: Column(
                children: [
                  Text(
                    court.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "150k/giờ", // Bạn có thể thay bằng court.price nếu có
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
