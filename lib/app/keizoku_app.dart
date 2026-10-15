import 'package:dynamic_color/dynamic_color.dart' show DynamicColorBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/l10n.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';

class KeizokuApp extends StatefulWidget {
  const KeizokuApp({super.key});

  static const maxTextScale = 1.15;

  @override
  State<KeizokuApp> createState() => _KeizokuAppState();
}

class _KeizokuAppState extends State<KeizokuApp> {
  var _look = (fit.themePref, fit.themeMode, fit.oled, fit.locale, fit.materialYou);

  @override
  void initState() {
    super.initState();
    fit.addListener(_watch);
  }

  @override
  void dispose() {
    fit.removeListener(_watch);
    super.dispose();
  }

  void _watch() {
    final look = (fit.themePref, fit.themeMode, fit.oled, fit.locale, fit.materialYou);
    if (look != _look) setState(() => _look = look);
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic = _look.$5;
        final light = AppTheme.lightTheme(useDynamic ? lightDynamic : null);
        final dark = fit.isOled
            ? AppTheme.oledTheme(useDynamic ? darkDynamic : null)
            : AppTheme.darkTheme(useDynamic ? darkDynamic : null);

        return MaterialApp(
          title: 'Keizoku',
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: dark,
          themeMode: _look.$2,
          locale: _look.$4,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: KeizokuApp.maxTextScale,
            child: _ButtonNavScrim(child: child!),
          ),
          home: const AppShell(),
        );
      },
    );
  }
}

class _ButtonNavScrim extends StatelessWidget {
  const _ButtonNavScrim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bar = MediaQuery.viewPaddingOf(context).bottom;
    final buttons = MediaQuery.systemGestureInsetsOf(context).left == 0;
    return Stack(
      children: [
        child,
        if (buttons && bar > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bar,
            child: IgnorePointer(child: ColoredBox(color: context.gc.bg)),
          ),
      ],
    );
  }
}
