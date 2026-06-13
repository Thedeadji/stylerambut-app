import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../models/appearance_detection_result.dart';

class FaceDetectionService {
  FaceDetectionService()
    : _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableContours: true,
          enableLandmarks: true,
        ),
      );

  final FaceDetector _faceDetector;

  Future<AppearanceDetectionResult> detect(String imagePath) async {
    final prepared = await _prepareImage(imagePath);
    final inputImage = InputImage.fromFilePath(prepared.path);

    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) {
      return AppearanceDetectionResult(
        isDetected: false,
        displayImagePath: prepared.path,
        imageSize: prepared.size,
      );
    }

    final face = _selectPrimaryFace(faces);
    final faceRect = _toUiRect(face.boundingBox, prepared.size);
    final hairRect = _estimateHairRect(face, faceRect, prepared.size);

    return AppearanceDetectionResult(
      isDetected: true,
      displayImagePath: prepared.path,
      imageSize: prepared.size,
      faceRect: faceRect,
      hairRect: hairRect,
    );
  }

  Future<void> dispose() => _faceDetector.close();

  Face _selectPrimaryFace(List<Face> faces) {
    if (faces.length == 1) {
      return faces.first;
    }

    faces.sort((a, b) {
      final areaA = a.boundingBox.width * a.boundingBox.height;
      final areaB = b.boundingBox.width * b.boundingBox.height;
      return areaB.compareTo(areaA);
    });
    return faces.first;
  }

  Rect _toUiRect(Rect box, Size imageSize) {
    return Rect.fromLTRB(
      box.left.clamp(0, imageSize.width),
      box.top.clamp(0, imageSize.height),
      box.right.clamp(0, imageSize.width),
      box.bottom.clamp(0, imageSize.height),
    );
  }

  /// ML Kit tidak punya deteksi rambut — kotak ini estimasi visual dari
  /// landmark/kontur wajah: dagu (bawah) hingga area rambut di atas dahi.
  Rect _estimateHairRect(Face face, Rect faceRect, Size imageSize) {
    var hairTop = faceRect.top - faceRect.height * 0.25;
    var hairBottom = faceRect.bottom;

    final contour = face.contours[FaceContourType.face];
    if (contour != null && contour.points.isNotEmpty) {
      final ys = contour.points.map((point) => point.y.toDouble());
      final minY = ys.reduce(math.min);
      final maxY = ys.reduce(math.max);
      hairTop = math.min(hairTop, minY - faceRect.height * 0.15);
      hairBottom = math.max(hairBottom, maxY);
    }

    final mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth];
    if (mouthBottom != null) {
      hairBottom = math.max(
        hairBottom,
        mouthBottom.position.y.toDouble() + faceRect.height * 0.06,
      );
    }

    final hairWidth = faceRect.width * 1.2;
    final centerX = faceRect.center.dx;

    return Rect.fromLTRB(
      (centerX - hairWidth / 2).clamp(0.0, imageSize.width),
      hairTop.clamp(0.0, imageSize.height),
      (centerX + hairWidth / 2).clamp(0.0, imageSize.width),
      hairBottom.clamp(0.0, imageSize.height),
    );
  }

  Future<_PreparedImage> _prepareImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return _PreparedImage(
        path: imagePath,
        size: await _readImageSize(imagePath),
        isTemporary: false,
      );
    }

    final oriented = img.bakeOrientation(decoded);
    final size = Size(oriented.width.toDouble(), oriented.height.toDouble());

    if (oriented == decoded) {
      return _PreparedImage(path: imagePath, size: size, isTemporary: false);
    }

    final tempPath =
        '${Directory.systemTemp.path}/mlkit_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(tempPath).writeAsBytes(img.encodeJpg(oriented, quality: 92));

    return _PreparedImage(path: tempPath, size: size, isTemporary: true);
  }

  Future<Size> _readImageSize(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return Size.zero;
    }
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }
}

class _PreparedImage {
  const _PreparedImage({
    required this.path,
    required this.size,
    required this.isTemporary,
  });

  final String path;
  final Size size;
  final bool isTemporary;
}
