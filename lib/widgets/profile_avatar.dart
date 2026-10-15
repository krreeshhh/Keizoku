import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../state/fit_state.dart';
import '../theme/app_colors.dart';

const kDefaultBanner = AssetImage('assets/img/banner_default.jpg');

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final bytes = fit.profilePhoto;
    if (bytes != null) {
      return Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: gc.accentSoft, shape: BoxShape.circle),
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: gc.border),
        ),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        shape: BoxShape.circle,
        border: Border.all(color: gc.accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gc.accent.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _AvatarOutlinePainter(color: gc.accent.withValues(alpha: 0.28)),
          ),
          Icon(
            PhosphorIconsRegular.user,
            size: size * 0.52,
            color: gc.accent,
          ),
        ],
      ),
    );
  }
}

class _AvatarOutlinePainter extends CustomPainter {
  _AvatarOutlinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Inner concentric guide ring
    canvas.drawCircle(center, radius * 0.78, paint);

    // Decorative corner ticks
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + math.pi / 4;
      final p1 = center + Offset(math.cos(angle) * (radius - 2), math.sin(angle) * (radius - 2));
      final p2 = center + Offset(math.cos(angle) * (radius - 6), math.sin(angle) * (radius - 6));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(_AvatarOutlinePainter old) => old.color != color;
}

class DefaultOutlineBanner extends StatelessWidget {
  const DefaultOutlineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: gc.bgRaised),
        CustomPaint(
          size: Size.infinite,
          painter: _BannerOutlinePainter(
            accent: gc.accent,
            border: gc.border,
            bgRaised2: gc.bgRaised2,
          ),
        ),
      ],
    );
  }
}

class _BannerOutlinePainter extends CustomPainter {
  _BannerOutlinePainter({
    required this.accent,
    required this.border,
    required this.bgRaised2,
  });

  final Color accent;
  final Color border;
  final Color bgRaised2;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Subtle isometric / geometric wireframe grid
    final gridPaint = Paint()
      ..color = border.withValues(alpha: 0.45)
      ..strokeWidth = 0.8;

    const step = 28.0;
    for (double x = 0; x <= w + h; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x - h * 0.6, h), gridPaint);
    }
    for (double y = 0; y <= h; y += step * 0.75) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Athletic energy contour waves in accent color
    final path = Path();
    path.moveTo(0, h * 0.72);
    path.cubicTo(w * 0.25, h * 0.45, w * 0.45, h * 0.85, w * 0.75, h * 0.38);
    path.quadraticBezierTo(w * 0.9, h * 0.22, w, h * 0.3);

    final wavePaint = Paint()
      ..color = accent.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawPath(path, wavePaint);

    final path2 = Path();
    path2.moveTo(0, h * 0.82);
    path2.cubicTo(w * 0.3, h * 0.6, w * 0.55, h * 0.92, w * 0.82, h * 0.5);
    path2.quadraticBezierTo(w * 0.92, h * 0.38, w, h * 0.42);

    final wavePaint2 = Paint()
      ..color = accent.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(path2, wavePaint2);

    // 3. Modern geometric cross / dot nodes
    final nodePaint = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    for (double x = step * 2; x < w; x += step * 3) {
      final ny = (h * 0.3) + math.sin(x / 40) * 20;
      canvas.drawCircle(Offset(x, ny), 2.2, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_BannerOutlinePainter old) =>
      old.accent != accent || old.border != border;
}
