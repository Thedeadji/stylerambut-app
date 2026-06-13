import 'dart:math' as math;
import 'dart:ui';

import 'package:image/image.dart' as img;

class ImageCropUtils {
  static img.Image cropFace(img.Image image, Rect faceRect) {
    final x = faceRect.left.round().clamp(0, image.width - 1);
    final y = faceRect.top.round().clamp(0, image.height - 1);
    final width = faceRect.width.round().clamp(1, image.width - x);
    final height = faceRect.height.round().clamp(1, image.height - y);

    return img.copyCrop(
      image,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  static img.Image cropHairRegion(img.Image image, Rect faceRect) {
    final x = faceRect.left.round();
    final y = faceRect.top.round();
    final width = faceRect.width.round();
    final height = faceRect.height.round();

    final expandTop = (height * 0.6).round();
    final expandSide = (width * 0.25).round();

    final xHair = math.max(0, x - expandSide);
    final yHair = math.max(0, y - expandTop);
    final wHair = math.min(image.width - xHair, width + (2 * expandSide));
    final hHair = math.min(image.height - yHair, height + expandTop);

    return img.copyCrop(
      image,
      x: xHair,
      y: yHair,
      width: wHair.clamp(1, image.width - xHair),
      height: hHair.clamp(1, image.height - yHair),
    );
  }

  static double hairRegionStdDev(img.Image hairCrop) {
    final gray = img.grayscale(hairCrop);
    var sum = 0.0;
    var sumSq = 0.0;
    final count = gray.width * gray.height;
    if (count == 0) {
      return 0;
    }

    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        final value = gray.getPixel(x, y).r.toDouble();
        sum += value;
        sumSq += value * value;
      }
    }

    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    return math.sqrt(variance.clamp(0, double.infinity));
  }
}
