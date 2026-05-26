import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:access_mobile/shared/themes/theme.dart';

class ScoreRing extends StatelessWidget {
  final double score;
  final String label;
  const ScoreRing({super.key, required this.score, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 110,
      height: 110,
      child: CustomPaint(
        painter: RingPainter(score, trackColor: colors.border),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  const RingPainter(this.progress, {required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = const LinearGradient(colors: [kAccent, kCyan]).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  @override
  bool shouldRepaint(RingPainter old) =>
      old.progress != progress || old.trackColor != trackColor;
}
