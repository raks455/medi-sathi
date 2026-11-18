import 'package:flutter/material.dart';

/// The colors that change between light and dark mode.
class AppPalette {
  final Brightness brightness;
  final Color primary;
  final Color scaffold;
  final Color surface;
  final Color tertiary;
  final Color tertiaryLight;
  final Color textPrimary;
  final Color textSecondary;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.scaffold,
    required this.surface,
    required this.tertiary,
    required this.tertiaryLight,
    required this.textPrimary,
    required this.textSecondary,
  });

  /// Calm clinical blues with a soft rose accent on a cool off-white.
  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF3368A0), // medical blue
    scaffold: Color(0xFFF4F7FA), // cool off-white background
    surface: Colors.white,
    tertiary: Color(0xFFC8DFDB), // pale mint (borders, indicators)
    tertiaryLight: Color(0xFFE4EFEC),
    textPrimary: Color(0xFF1E3A56), // deep navy
    textSecondary: Color(0xFF5E7B8F), // muted blue-grey
  );

  /// The same palette on a deep navy night background.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF5B93CF), // lifted so it reads on dark surfaces
    scaffold: Color(0xFF0F1A24),
    surface: Color(0xFF182633),
    tertiary: Color(0xFF2B4352),
    tertiaryLight: Color(0xFF1F3340),
    textPrimary: Color(0xFFE6EEF5),
    textSecondary: Color(0xFF9DB2C2),
  );

  static AppPalette of(Brightness b) => b == Brightness.dark ? dark : light;
}

/// MediSathi colors.
///
/// The brand accents are constant. The surface and text colors follow the
/// active theme: [MediSathiApp] calls [use] whenever the theme brightness
/// changes and then rebuilds the widget tree.
class AppColors {
  AppColors._();

  static AppPalette _palette = AppPalette.light;

  static AppPalette get palette => _palette;
  static bool get isDark => _palette.brightness == Brightness.dark;

  /// Returns true when the palette actually changed.
  static bool use(Brightness brightness) {
    final next = AppPalette.of(brightness);
    if (identical(next, _palette)) return false;
    _palette = next;
    return true;
  }

  // ---- Constant brand accents ----
  static const icon = Color(0xFFDC9B9B); // dusty rose (icons, accents)
  static const secondary = Color(0xFF66A3BF); // soft sky blue
  static const error = Color(0xFFC0504D);
  static const success = Color(0xFF4E9A7B); // muted green (dose taken)
  static const warning = Color(0xFFC98A2B); // muted amber (dose due)

  static const List<Color> splashGradient = [
    Color(0xFF3368A0),
    Color(0xFF4F87B3),
    Color(0xFF66A3BF),
  ];

  // ---- Theme-dependent ----
  static Color get primary => _palette.primary;
  static Color get scaffold => _palette.scaffold;
  static Color get surface => _palette.surface;
  static Color get tertiary => _palette.tertiary;
  static Color get tertiaryLight => _palette.tertiaryLight;
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
}
