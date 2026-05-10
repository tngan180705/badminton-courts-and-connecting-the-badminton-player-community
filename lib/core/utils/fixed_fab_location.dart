import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A custom FloatingActionButtonLocation that stays docked at the center
/// and does NOT move up when a SnackBar is shown.
class FixedCenterDockedFabLocation extends FloatingActionButtonLocation {
  const FixedCenterDockedFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;
    
    final double contentBottom = scaffoldGeometry.contentBottom;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    
    double fabY = contentBottom - (fabHeight / 2.0);
    
    final double maxFabY = scaffoldGeometry.scaffoldSize.height - fabHeight;
    if (fabY > maxFabY) {
      fabY = maxFabY;
    }
    
    return Offset(fabX, fabY);
  }

  @override
  String toString() => 'FloatingActionButtonLocation.fixedCenterDocked';
}
