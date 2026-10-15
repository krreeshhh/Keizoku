import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const double kSheetBlur = 14;

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = false,
}) {
  final nav = Navigator.of(context);
  return nav.push(_GlassSheetRoute<T>(
    builder: builder,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    shape: shape,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    modalBarrierColor: Colors.black.withValues(alpha: 0.32),
    capturedThemes: InheritedTheme.capture(from: context, to: nav.context),
    barrierLabel: MaterialLocalizations.of(context).scrimLabel,
  ));
}

class _GlassSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _GlassSheetRoute({
    required super.builder,
    required super.isScrollControlled,
    super.backgroundColor,
    super.shape,
    super.isDismissible,
    super.enableDrag,
    super.useSafeArea,
    super.modalBarrierColor,
    super.capturedThemes,
    super.barrierLabel,
  });

  @override
  Widget buildModalBarrier() => _BlurBarrier(animation: animation!, child: super.buildModalBarrier());
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final nav = Navigator.of(context);
  return nav.push(_GlassDialogRoute<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    themes: InheritedTheme.capture(from: context, to: nav.context),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  ));
}

class _GlassDialogRoute<T> extends DialogRoute<T> {
  _GlassDialogRoute({
    required super.context,
    required super.builder,
    super.barrierDismissible = true,
    super.barrierColor,
    super.themes,
    super.barrierLabel,
  });

  @override
  Widget buildModalBarrier() => _BlurBarrier(animation: animation!, child: super.buildModalBarrier());

  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondary, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1).animate(curved), child: child),
    );
  }
}

class _BlurBarrier extends StatelessWidget {
  const _BlurBarrier({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

class EdgeBlur extends StatelessWidget {
  const EdgeBlur({super.key, required this.height, this.top = true, this.sigma = 16, this.shade = 1});

  final double height;
  final bool top;
  final double sigma;
  final double shade;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                end: top ? Alignment.bottomCenter : Alignment.topCenter,
                colors: [
                  for (final a in const [1.0, 0.94, 0.78, 0.52, 0.26, 0.08, 0.0])
                    gc.bg.withValues(alpha: (a * shade).clamp(0.0, 1.0)),
                ],
                stops: const [0.0, 0.18, 0.38, 0.58, 0.76, 0.90, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 28,
    this.blur = 22,
    this.tint,
    this.padding,
  });

  final Widget child;
  final double radius;
  final double blur;
  final Color? tint;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final dark = gc.bg.computeLuminance() < 0.5;
    final shape = BorderRadius.circular(radius);
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: shape,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            color: tint ?? gc.navBg,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: dark ? 0.08 : 0.35),
                  Colors.white.withValues(alpha: 0),
                ],
                stops: const [0, 0.6],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.1 : 0.5),
                width: 0.8,
              ),
            ),
            child: padding == null ? child : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}
