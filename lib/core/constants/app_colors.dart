import 'package:flutter/material.dart';

class AppColors {
  // Palette chính [cite: 19]
  static const Color primary = Color(0xFF407F3E); // Xanh đậm
  static const Color secondary = Color(0xFF8B9449); // Xanh lá
  static const Color accent = Color(0xFFDBD46B); // Vàng nhạt
  static const Color background = Color(0xFFE7E0C4); // Be nhạt
  static const Color error = Color(0xFFE68A8C); // Hồng đỏ

  // Mapping màu theo nghiệp vụ cầu lông [cite: 26]
  static const Color courtAvailable = primary;
  static const Color courtBooked = error;
  static const Color courtSelected = accent;
}
