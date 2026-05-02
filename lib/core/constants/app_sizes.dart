import 'package:flutter/material.dart';

class AppSizes {
  // --- Padding & Margin ---
  static const double screenPadding = 20.0;
  static const double cardPadding = 16.0;

  // --- Spacing (Khoảng cách giữa các phần tử) ---
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXL = 40.0;

  // --- Radius (Bo góc) ---
  static const double radiusM = 12.0;
  static const double radiusL = 15.0;
  static const double radiusXL = 28.0;

  // --- Button & Input ---
  static const double buttonHeight = 55.0;
  static const double iconSize = 22.0;

  // --- Helper Widgets cho khoảng cách ---
  static const SizedBox hSmall = SizedBox(height: spaceSmall);
  static const SizedBox hMedium = SizedBox(height: spaceMedium);
  static const SizedBox hLarge = SizedBox(height: spaceLarge);
  static const SizedBox wSmall = SizedBox(width: spaceSmall);
  static const SizedBox wMedium = SizedBox(width: spaceMedium);
}
