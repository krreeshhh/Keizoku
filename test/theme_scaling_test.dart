import 'package:flutter_test/flutter_test.dart';
import 'package:keizoku/theme/app_theme.dart';

void main() {
  group('AppTheme Font Scaling', () {
    test('theme scale proof matches target calibrations', () {
      expect(AppTheme.f(10).fontSize, 12.0);
      expect(AppTheme.f(14).fontSize, 17.0);
      expect(AppTheme.f(20).fontSize, 24.0);
      expect(AppTheme.d(30).fontSize, 35.0);
    });

    test('proportional font scaling (+18%) scales d, f, and s', () {
      expect(AppTheme.d(10).fontSize, 12.0);
      expect(AppTheme.f(10).fontSize, 12.0);
      expect(AppTheme.s(10).fontSize, 12.0);

      expect(AppTheme.f(14).fontSize, 17.0);
      expect(AppTheme.f(15).fontSize, 18.0);
      expect(AppTheme.f(16).fontSize, 19.0);
      expect(AppTheme.f(19).fontSize, 22.0);
      expect(AppTheme.f(26).fontSize, 31.0);
    });

    test('monospace font scaling (+8%) scales m', () {
      expect(AppTheme.m(10).fontSize, 11.0);
      expect(AppTheme.m(18).fontSize, 19.0);
      expect(AppTheme.m(20).fontSize, 22.0);
      expect(AppTheme.m(36).fontSize, 39.0);
    });

    test('theme data text theme applies fontScale factor and font family', () {
      for (final theme in [AppTheme.dark, AppTheme.oled, AppTheme.light]) {
        expect(theme.textTheme.bodyMedium?.fontFamily, AppTheme.sans);
        expect(theme.textTheme.bodyMedium?.fontSize, (14.0 * 1.18));
        expect(theme.textTheme.titleLarge?.fontSize, (22.0 * 1.18));
        expect(theme.timePickerTheme.helpTextStyle?.fontSize, AppTheme.scale(12));
        expect(theme.timePickerTheme.helpTextStyle?.fontSize, 14.0);
      }
    });
  });
}
