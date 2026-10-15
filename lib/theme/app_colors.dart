import 'package:flutter/material.dart';

@immutable
class GymColors extends ThemeExtension<GymColors> {
  const GymColors({
    required this.pageBg,
    required this.bg,
    required this.bgRaised,
    required this.bgRaised2,
    required this.border,
    required this.navBg,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.ember,
    required this.emberDeep,
    required this.onEmber,
    required this.emberSoft,
    required this.emberShadow,
    required this.accent,
    required this.accentSoft,
    required this.brass,
    required this.sage,
    required this.sageSoft,
    required this.mutedFill,
    required this.heatEmpty,
    required this.info,
    required this.warn,
    required this.danger,
  });

  final Color pageBg;
  final Color bg;
  final Color bgRaised;
  final Color bgRaised2;
  final Color border;
  final Color navBg;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color ember;
  final Color emberDeep;
  final Color onEmber;
  final Color emberSoft;
  final Color emberShadow;
  final Color accent;
  final Color accentSoft;
  final Color brass;
  final Color sage;
  final Color sageSoft;
  final Color mutedFill;
  final Color heatEmpty;
  final Color info;
  final Color warn;
  final Color danger;

  static const dark = GymColors(
    pageBg: Color(0xFF121316),
    bg: Color(0xFF121316),
    bgRaised: Color(0xFF1E2026),
    bgRaised2: Color(0xFF282B33),
    border: Color(0xFF383B44),
    navBg: Color(0xD9121316),
    text: Color(0xFFE2E2E8),
    textSecondary: Color(0xFF9E9FA7),
    textTertiary: Color(0xFF6E7078),
    ember: Color(0xFFA8C7FA),
    emberDeep: Color(0xFF00325B),
    onEmber: Color(0xFF062E6F),
    emberSoft: Color(0x29A8C7FA),
    emberShadow: Color(0x80000000),
    accent: Color(0xFFA8C7FA),
    accentSoft: Color(0x29A8C7FA),
    brass: Color(0xFFC4D1E8),
    sage: Color(0xFF8CD4A2),
    sageSoft: Color(0x298CD4A2),
    mutedFill: Color(0xFF2E313A),
    heatEmpty: Color(0xFF24262E),
    info: Color(0xFF7FA8C9),
    warn: Color(0xFFE0B15A),
    danger: Color(0xFFF28B82),
  );

  static const oled = GymColors(
    pageBg: Color(0xFF000000),
    bg: Color(0xFF000000),
    bgRaised: Color(0xFF121212),
    bgRaised2: Color(0xFF1E1E1E),
    border: Color(0xFF262626),
    navBg: Color(0xE6000000),
    text: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA0A0A0),
    textTertiary: Color(0xFF707070),
    ember: Color(0xFFA8C7FA),
    emberDeep: Color(0xFF00325B),
    onEmber: Color(0xFF062E6F),
    emberSoft: Color(0x29A8C7FA),
    emberShadow: Color(0x99000000),
    accent: Color(0xFFA8C7FA),
    accentSoft: Color(0x29A8C7FA),
    brass: Color(0xFFC4D1E8),
    sage: Color(0xFF8CD4A2),
    sageSoft: Color(0x298CD4A2),
    mutedFill: Color(0xFF1C1C1C),
    heatEmpty: Color(0xFF181818),
    info: Color(0xFF7FA8C9),
    warn: Color(0xFFE0B15A),
    danger: Color(0xFFF28B82),
  );

  static const light = GymColors(
    pageBg: Color(0xFFF8F9FF),
    bg: Color(0xFFF8F9FF),
    bgRaised: Color(0xFFEEF0F8),
    bgRaised2: Color(0xFFE2E4EC),
    border: Color(0xFFD0D3DE),
    navBg: Color(0xF2F8F9FF),
    text: Color(0xFF191C20),
    textSecondary: Color(0xFF43474E),
    textTertiary: Color(0xFF73777F),
    ember: Color(0xFF3865A8),
    emberDeep: Color(0xFFD6E3FF),
    onEmber: Color(0xFFFFFFFF),
    emberSoft: Color(0x1F3865A8),
    emberShadow: Color(0x1F191C20),
    accent: Color(0xFF3865A8),
    accentSoft: Color(0x1F3865A8),
    brass: Color(0xFF565F71),
    sage: Color(0xFF2A6A4E),
    sageSoft: Color(0x1F2A6A4E),
    mutedFill: Color(0xFFE2E4EC),
    heatEmpty: Color(0xFFDFE2EA),
    info: Color(0xFF3865A8),
    warn: Color(0xFF9A6A12),
    danger: Color(0xFFBA1A1A),
  );

  factory GymColors.fromColorScheme(ColorScheme s, {required bool isDark}) {
    if (isDark) {
      return GymColors(
        pageBg: s.surface,
        bg: s.surfaceContainerLowest,
        bgRaised: s.surfaceContainer,
        bgRaised2: s.surfaceContainerHigh,
        border: s.outlineVariant.withValues(alpha: 0.35),
        navBg: s.surface.withValues(alpha: 0.88),
        text: s.onSurface,
        textSecondary: s.onSurfaceVariant,
        textTertiary: s.outline,
        ember: s.primary,
        emberDeep: s.onPrimaryContainer,
        onEmber: s.onPrimary,
        emberSoft: s.primary.withValues(alpha: 0.18),
        emberShadow: s.shadow.withValues(alpha: 0.4),
        accent: s.primary,
        accentSoft: s.primary.withValues(alpha: 0.18),
        brass: s.secondary,
        sage: s.tertiary,
        sageSoft: s.tertiary.withValues(alpha: 0.22),
        mutedFill: s.surfaceContainerHighest,
        heatEmpty: s.onSurface.withValues(alpha: 0.09),
        info: s.primary,
        warn: const Color(0xFFE0B15A),
        danger: s.error,
      );
    } else {
      return GymColors(
        pageBg: s.surface,
        bg: s.surfaceContainerLowest,
        bgRaised: s.surfaceContainerLow,
        bgRaised2: s.surfaceContainer,
        border: s.outlineVariant.withValues(alpha: 0.40),
        navBg: s.surface.withValues(alpha: 0.92),
        text: s.onSurface,
        textSecondary: s.onSurfaceVariant,
        textTertiary: s.outline,
        ember: s.primary,
        emberDeep: s.primaryContainer,
        onEmber: s.onPrimary,
        emberSoft: s.primary.withValues(alpha: 0.14),
        emberShadow: s.shadow.withValues(alpha: 0.15),
        accent: s.primary,
        accentSoft: s.primary.withValues(alpha: 0.16),
        brass: s.secondary,
        sage: s.tertiary,
        sageSoft: s.tertiary.withValues(alpha: 0.18),
        mutedFill: s.surfaceContainerHighest,
        heatEmpty: s.onSurface.withValues(alpha: 0.07),
        info: s.primary,
        warn: const Color(0xFF9A6A12),
        danger: s.error,
      );
    }
  }

  @override
  GymColors copyWith({
    Color? pageBg,
    Color? bg,
    Color? bgRaised,
    Color? bgRaised2,
    Color? border,
    Color? navBg,
    Color? text,
    Color? textSecondary,
    Color? textTertiary,
    Color? ember,
    Color? emberDeep,
    Color? onEmber,
    Color? emberSoft,
    Color? emberShadow,
    Color? accent,
    Color? accentSoft,
    Color? brass,
    Color? sage,
    Color? sageSoft,
    Color? mutedFill,
    Color? heatEmpty,
    Color? info,
    Color? warn,
    Color? danger,
  }) {
    return GymColors(
      pageBg: pageBg ?? this.pageBg,
      bg: bg ?? this.bg,
      bgRaised: bgRaised ?? this.bgRaised,
      bgRaised2: bgRaised2 ?? this.bgRaised2,
      border: border ?? this.border,
      navBg: navBg ?? this.navBg,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      ember: ember ?? this.ember,
      emberDeep: emberDeep ?? this.emberDeep,
      onEmber: onEmber ?? this.onEmber,
      emberSoft: emberSoft ?? this.emberSoft,
      emberShadow: emberShadow ?? this.emberShadow,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      brass: brass ?? this.brass,
      sage: sage ?? this.sage,
      sageSoft: sageSoft ?? this.sageSoft,
      mutedFill: mutedFill ?? this.mutedFill,
      heatEmpty: heatEmpty ?? this.heatEmpty,
      info: info ?? this.info,
      warn: warn ?? this.warn,
      danger: danger ?? this.danger,
    );
  }

  @override
  GymColors lerp(GymColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return GymColors(
      pageBg: c(pageBg, other.pageBg),
      bg: c(bg, other.bg),
      bgRaised: c(bgRaised, other.bgRaised),
      bgRaised2: c(bgRaised2, other.bgRaised2),
      border: c(border, other.border),
      navBg: c(navBg, other.navBg),
      text: c(text, other.text),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      ember: c(ember, other.ember),
      emberDeep: c(emberDeep, other.emberDeep),
      onEmber: c(onEmber, other.onEmber),
      emberSoft: c(emberSoft, other.emberSoft),
      emberShadow: c(emberShadow, other.emberShadow),
      accent: c(accent, other.accent),
      accentSoft: c(accentSoft, other.accentSoft),
      brass: c(brass, other.brass),
      sage: c(sage, other.sage),
      sageSoft: c(sageSoft, other.sageSoft),
      mutedFill: c(mutedFill, other.mutedFill),
      heatEmpty: c(heatEmpty, other.heatEmpty),
      info: c(info, other.info),
      warn: c(warn, other.warn),
      danger: c(danger, other.danger),
    );
  }
}

extension GymColorsX on BuildContext {
  GymColors get gc => Theme.of(this).extension<GymColors>()!;
}
