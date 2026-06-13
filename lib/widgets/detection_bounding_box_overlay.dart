import 'dart:math' as math;

import 'package:flutter/material.dart';

class DetectionBox {
  const DetectionBox({
    required this.rect,
    required this.label,
    required this.color,
  });

  final Rect rect;
  final String label;
  final Color color;
}

class DetectionBoundingBoxOverlay extends StatelessWidget {
  const DetectionBoundingBoxOverlay({
    super.key,
    required this.boxes,
    required this.imageSize,
  });

  final List<DetectionBox> boxes;
  final Size imageSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final displaySize = Size(constraints.maxWidth, constraints.maxHeight);
        return CustomPaint(
          size: displaySize,
          painter: _DetectionBoxPainter(
            boxes: boxes,
            imageSize: imageSize,
            displaySize: displaySize,
          ),
        );
      },
    );
  }
}

class _DetectionBoxPainter extends CustomPainter {
  _DetectionBoxPainter({
    required this.boxes,
    required this.imageSize,
    required this.displaySize,
  });

  final List<DetectionBox> boxes;
  final Size imageSize;
  final Size displaySize;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width == 0 || imageSize.height == 0) {
      return;
    }

    for (final box in boxes) {
      final mappedRect = _mapRect(box.rect);
      final borderPaint = Paint()
        ..color = box.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawRect(mappedRect, borderPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: box.label,
          style: TextStyle(
            color: box.color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            backgroundColor: Colors.black.withValues(alpha: 0.65),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelTop = math.max(
        0.0,
        mappedRect.top - textPainter.height - 4,
      );
      textPainter.paint(canvas, Offset(mappedRect.left, labelTop));
    }
  }

  Rect _mapRect(Rect sourceRect) {
    final scale = math.max(
      displaySize.width / imageSize.width,
      displaySize.height / imageSize.height,
    );
    final scaledWidth = imageSize.width * scale;
    final scaledHeight = imageSize.height * scale;
    final offsetX = (displaySize.width - scaledWidth) / 2;
    final offsetY = (displaySize.height - scaledHeight) / 2;

    return Rect.fromLTRB(
      sourceRect.left * scale + offsetX,
      sourceRect.top * scale + offsetY,
      sourceRect.right * scale + offsetX,
      sourceRect.bottom * scale + offsetY,
    );
  }

  @override
  bool shouldRepaint(covariant _DetectionBoxPainter oldDelegate) {
    return oldDelegate.boxes != boxes ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.displaySize != displaySize;
  }
}
