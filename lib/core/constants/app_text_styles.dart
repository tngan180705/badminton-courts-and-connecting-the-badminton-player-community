import 'package:flutter/material.dart';
import 'app_colors.dart'; // Sử dụng AppColors từ constants [cite: 24]

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Roboto';

  // Headings theo đúng màu Primary của dự án
  static const heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
}
