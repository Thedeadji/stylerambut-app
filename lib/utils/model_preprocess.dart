import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ModelPreprocess {
  static Float32List mobileFaceNet(img.Image crop) {
    final resized = img.copyResize(crop, width: 112, height: 112, interpolation: img.Interpolation.linear);
    final input = Float32List(112 * 112 * 3);
    var index = 0;

    for (var y = 0; y < 112; y++) {
      for (var x = 0; x < 112; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = pixel.r / 255.0;
        input[index++] = pixel.g / 255.0;
        input[index++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  static Float32List efficientNet(img.Image crop) {
    final resized = img.copyResize(crop, width: 224, height: 224, interpolation: img.Interpolation.linear);
    final input = Float32List(224 * 224 * 3);
    var index = 0;

    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[index++] = pixel.r.toDouble();
        input[index++] = pixel.g.toDouble();
        input[index++] = pixel.b.toDouble();
      }
    }

    return input;
  }
}
