import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  // Constructor riêng tư để ngăn việc khởi tạo class này [cite: 13]
  AppTheme._();

  static final ThemeData light = ThemeData(
    useMaterial3: true, // Bắt buộc sử dụng Material 3
    // Sử dụng màu Primary từ AppColors
    primaryColor: AppColors.primary,

    // Màu nền mặc định cho toàn bộ màn hình là màu Be nhạt [cite: 31]
    scaffoldBackgroundColor: AppColors.background,

    // Cấu hình font chữ từ file AppTextStyles
    fontFamily: AppTextStyles.fontFamily,

    // Định nghĩa bảng màu hệ thống (ColorScheme)
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      surface: Colors.white,
    ),

    // Bạn có thể thêm các cấu hình TextTheme hoặc ButtonTheme tại đây
    // đảm bảo sử dụng các hằng số từ AppTextStyles
  );
}
