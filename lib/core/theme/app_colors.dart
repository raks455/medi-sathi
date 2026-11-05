import 'package:flutter/material.dart';

/// MediSathi palette: calm clinical blues with a soft rose accent on cream.
class AppColors {
  AppColors._();

  // ---- Brand palette ----
  static const icon = Color(0xFFDC9B9B);       // dusty rose (icons, accents)
  static const primary = Color(0xFF3368A0);    // medical blue
  static const secondary = Color(0xFF66A3BF);  // soft sky blue
  static const tertiary = Color(0xFFC8DFDB);   // pale mint
  static const scaffold = Color(0xFFF2EFE7);   // warm cream background

  // ---- Derived ----
  static const surface = Colors.white;
  static const tertiaryLight = Color(0xFFE4EFEC);
  static const textPrimary = Color(0xFF1E3A56);   // deep navy
  static const textSecondary = Color(0xFF5E7B8F); // muted blue-grey
  static const error = Color(0xFFC0504D);

  static const List<Color> splashGradient = [
    Color(0xFF3368A0),
    Color(0xFF4F87B3),
    Color(0xFF66A3BF),
  ];
}
