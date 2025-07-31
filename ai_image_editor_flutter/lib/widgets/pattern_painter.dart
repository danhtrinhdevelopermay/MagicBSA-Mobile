import 'package:flutter/material.dart';
import 'dart:math' as math;

class PatternPainter extends CustomPainter {
  final Color color;
  final Animation<double>? animation;

  PatternPainter({
    required this.color,
    this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double animationValue = animation?.value ?? 0.0;
    final double spacing = 20.0;
    final double offset = animationValue * spacing;

    // Draw diagonal lines pattern
    for (double i = -spacing; i < size.width + spacing; i += spacing) {
      final double x = i + offset;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }

    // Draw dots pattern
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing * 2) {
      for (double y = 0; y < size.height; y += spacing * 2) {
        final double opacity = (math.sin(animationValue * 2 * math.pi + x / 20) + 1) / 2;
        dotPaint.color = color.withOpacity(opacity * 0.3);
        canvas.drawCircle(
          Offset(x + spacing + offset % spacing, y + spacing),
          2.0,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return animation != null;
  }
}