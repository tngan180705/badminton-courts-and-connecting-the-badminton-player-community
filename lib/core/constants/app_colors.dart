import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF407F3E);
  static const Color secondary = Color(0xFF8B9449);
  static const Color accent = Color(0xFFDBD46B);
  static const Color background = Color(0xFFE7E0C4);
  static const Color error = Color(0xFFE68A8C);

  static const Color white = Colors.white;
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color inputBorder = Color(0xFFD1CBB1);

  static const Color courtAvailable = primary;
  static const Color courtBooked = error;
  static const Color courtSelected = accent;

  static const Color matchOpen = primary;
  static const Color matchFull = textSecondary;

  static const Color courtReserved = Color(0xFFEB8A8A);
  static const Color homeBackground = Color(0xFFE5E5CA);
}

/// 🔥 FIX REPLACEMENT CHO withOpacity (CI SAFE)
extension ColorX on Color {
  Color withAlphaValue(double opacity) {
    return withValues(alpha: opacity);
  }
}
