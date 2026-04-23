import 'package:flutter/material.dart';

class AppColors {
  // Palette chính theo thiết kế của bạn
  static const Color primary = Color(0xFF407F3E);    // Xanh đậm (Chủ đạo, Nút bấm)
  static const Color secondary = Color(0xFF8B9449);  // Xanh lá (Icon, Thứ chính)
  static const Color accent = Color(0xFFDBD46B);     // Vàng nhạt (Highlight)
  static const Color background = Color(0xFFE7E0C4); // Be nhạt (Nền app)
  static const Color error = Color(0xFFE68A8C);      // Hồng đỏ (Lỗi, Xóa)

  // Màu bổ trợ cho Text và UI Elements
  static const Color white = Colors.white;
  static const Color textPrimary = Color(0xFF2D2D2D);   // Chữ đen đậm
  static const Color textSecondary = Color(0xFF757575); // Chữ xám (Hint text)
  static const Color inputBorder = Color(0xFFD1CBB1);   // Viền ô nhập liệu

  // Mapping theo nghiệp vụ sân cầu lông
  static const Color courtAvailable = primary;
  static const Color courtBooked = error;
  static const Color courtSelected = accent;
  
  // Trạng thái kèo đấu (Match Status)
  static const Color matchOpen = primary;
  static const Color matchFull = textSecondary;
}