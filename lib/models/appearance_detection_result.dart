import 'dart:ui';

class AppearanceDetectionResult {
  const AppearanceDetectionResult({
    required this.isDetected,
    required this.displayImagePath,
    required this.imageSize,
    this.faceRect,
    this.hairRect,
  });

  final bool isDetected;
  final String displayImagePath;
  final Size imageSize;
  final Rect? faceRect;
  final Rect? hairRect;
}
