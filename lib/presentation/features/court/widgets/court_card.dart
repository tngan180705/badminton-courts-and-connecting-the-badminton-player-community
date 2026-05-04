import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/sub_court_model.dart';

class CourtCard extends StatelessWidget {
  final SubCourtModel subCourt;
  final String courtName; // Tên cửa hàng để hiển thị
  final VoidCallback? onTap;

  const CourtCard({
    super.key,
    required this.subCourt,
    required this.courtName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Tạo tên file ảnh từ tên sân con (vd: "san1.jpg")
    final fileName = subCourt.subCourtName
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('â', 'a');

    return GestureDetector(
      onTap: onTap,
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
            // Ảnh sân
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusL)),
                child: Image.asset(
                  'assets/images/$fileName.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[100],
                    width: double.infinity,
                    child: const Center(
                      child: Icon(Icons.sports_tennis,
                          color: AppColors.secondary, size: 40),
                    ),
                  ),
                ),
              ),
            ),

            // Thông tin
            Padding(
              padding: const EdgeInsets.all(AppSizes.spaceSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subCourt.subCourtName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    courtName,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Badge trạng thái
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: subCourt.isActive
                          ? AppColors.courtAvailable.withOpacity(0.1)
                          : AppColors.courtBooked.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subCourt.isActive ? 'Hoạt động' : 'Tạm đóng',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: subCourt.isActive
                            ? AppColors.courtAvailable
                            : AppColors.courtBooked,
                      ),
                    ),
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
