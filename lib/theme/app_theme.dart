import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String disp = 'DarkerGrotesque';
  static const String sans = 'DarkerGrotesque';
  static const String round = 'DarkerGrotesque';
  static const String mono = 'SpaceMono';

  static const double fontScale = 1.18;
  static const double monoScale = 1.08;

  static double scale(double size) => (size * fontScale).roundToDouble();
  static double scaleMono(double size) => (size * monoScale).roundToDouble();

  // Material 3 Expressive Shape Tokens
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 26.0;
  static const double radiusSheet = 32.0;

  static ThemeData get dark => darkTheme();
  static ThemeData get oled => oledTheme();
  static ThemeData get light => lightTheme();

  static ThemeData darkTheme([ColorScheme? dynamicScheme]) => _build(
        Brightness.dark,
        dynamicScheme != null ? GymColors.fromColorScheme(dynamicScheme, isDark: true) : GymColors.dark,
        dynamicScheme,
      );

  static ThemeData oledTheme([ColorScheme? dynamicScheme]) => _build(
        Brightness.dark,
        dynamicScheme != null
            ? GymColors.fromColorScheme(dynamicScheme, isDark: true).copyWith(
                pageBg: const Color(0xFF000000),
                bg: const Color(0xFF000000),
                bgRaised: const Color(0xFF121212),
                bgRaised2: const Color(0xFF1E1E1E),
                border: const Color(0xFF262626),
                navBg: const Color(0xE6000000),
              )
            : GymColors.oled,
        dynamicScheme,
      );

  static ThemeData lightTheme([ColorScheme? dynamicScheme]) => _build(
        Brightness.light,
        dynamicScheme != null ? GymColors.fromColorScheme(dynamicScheme, isDark: false) : GymColors.light,
        dynamicScheme,
      );

  static ThemeData _build(Brightness brightness, GymColors gc, [ColorScheme? dynamicScheme]) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: sans,
      colorScheme: dynamicScheme,
    );
    return base.copyWith(
      scaffoldBackgroundColor: gc.bg,
      colorScheme: (dynamicScheme ?? base.colorScheme).copyWith(
        surface: gc.bgRaised,
        primary: gc.accent,
        onPrimary: gc.onEmber,
        onSurface: gc.text,
        error: gc.danger,
      ),
      textTheme: Typography.material2021().englishLike.merge(base.textTheme).apply(
        fontFamily: sans,
        fontSizeFactor: fontScale,
        bodyColor: gc.text,
        displayColor: gc.text,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      dividerColor: gc.border,
      timePickerTheme: TimePickerThemeData(
        backgroundColor: gc.bgRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        hourMinuteColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? gc.accentSoft : gc.bgRaised2),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? gc.accent : gc.text),
        dayPeriodColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? gc.accentSoft : Colors.transparent),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? gc.accent : gc.textSecondary),
        dayPeriodBorderSide: BorderSide(color: gc.border),
        helpTextStyle: TextStyle(
            fontFamily: sans, fontSize: scale(12), fontWeight: FontWeight.w700, letterSpacing: 1.2, color: gc.textSecondary),
        entryModeIconColor: gc.textSecondary,
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: gc.textSecondary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: gc.accent),
      ),
      extensions: [gc],
    );
  }

  static TextStyle d(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double height = 1.0,
  }) =>
      TextStyle(
        fontFamily: disp,
        fontSize: scale(size),
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle f(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double height = 1.15,
  }) =>
      TextStyle(
        fontFamily: round,
        fontSize: scale(size),
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle s(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double height = 1.35,
  }) =>
      TextStyle(
        fontFamily: sans,
        fontSize: scale(size),
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle m(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double height = 1.15,
  }) =>
      TextStyle(
        fontFamily: mono,
        fontSize: scaleMono(size),
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
}
