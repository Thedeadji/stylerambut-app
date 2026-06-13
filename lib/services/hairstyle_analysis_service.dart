import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../data/hairstyle_labels.dart';
import '../data/hairstyle_recommendations.dart';
import '../models/hairstyle_analysis_result.dart';
import '../utils/image_crop_utils.dart';
import '../utils/model_preprocess.dart';

enum AnalysisPipelineStep {
  landmarks,
  faceShape,
  hairDensity,
  hairType,
  preparing,
}

typedef AnalysisProgressCallback = void Function(AnalysisPipelineStep step);

class HairstyleAnalysisService {
  static const _baldStdDevThreshold = 49.0;

  Future<HairstyleAnalysisResult> analyze({
    required String imagePath,
    required Rect faceRect,
    AnalysisProgressCallback? onStepStarted,
    AnalysisProgressCallback? onStepCompleted,
  }) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw Exception('Gagal membaca gambar untuk analisis.');
    }

    final image = img.bakeOrientation(decoded);
    final faceCrop = ImageCropUtils.cropFace(image, faceRect);
    final hairCrop = ImageCropUtils.cropHairRegion(image, faceRect);

    onStepStarted?.call(AnalysisPipelineStep.landmarks);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    onStepCompleted?.call(AnalysisPipelineStep.landmarks);

    onStepStarted?.call(AnalysisPipelineStep.faceShape);
    final facePrediction = await _runModel(
      assetPath: HairstyleLabels.faceModelAsset,
      input: ModelPreprocess.mobileFaceNet(faceCrop),
      labels: HairstyleLabels.faceClasses,
    );
    onStepCompleted?.call(AnalysisPipelineStep.faceShape);

    final isBald = ImageCropUtils.hairRegionStdDev(hairCrop) < _baldStdDevThreshold;

    ClassificationPrediction hairDensityPrediction;
    ClassificationPrediction hairTypePrediction;
    List<String> recommendations;

    if (isBald) {
      onStepStarted?.call(AnalysisPipelineStep.hairDensity);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      onStepCompleted?.call(AnalysisPipelineStep.hairDensity);

      onStepStarted?.call(AnalysisPipelineStep.hairType);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      onStepCompleted?.call(AnalysisPipelineStep.hairType);

      hairDensityPrediction = const ClassificationPrediction(
        label: 'Bald / No Hair',
        confidence: 100,
      );
      hairTypePrediction = const ClassificationPrediction(
        label: 'None',
        confidence: 100,
      );
      recommendations = const [
        'Tidak ada rekomendasi gaya rambut untuk kepala botak.',
      ];
    } else {
      onStepStarted?.call(AnalysisPipelineStep.hairDensity);
      final hairInput = ModelPreprocess.efficientNet(hairCrop);
      hairDensityPrediction = await _runModel(
        assetPath: HairstyleLabels.hairDensityModelAsset,
        input: hairInput,
        labels: HairstyleLabels.hairDensityClasses,
      );
      onStepCompleted?.call(AnalysisPipelineStep.hairDensity);

      onStepStarted?.call(AnalysisPipelineStep.hairType);
      hairTypePrediction = await _runModel(
        assetPath: HairstyleLabels.hairTypeModelAsset,
        input: hairInput,
        labels: HairstyleLabels.hairTypeClasses,
      );
      onStepCompleted?.call(AnalysisPipelineStep.hairType);

      recommendations = HairstyleRecommendations.get(
        facePrediction.label,
        hairDensityPrediction.label,
        hairTypePrediction.label,
      );
    }

    onStepStarted?.call(AnalysisPipelineStep.preparing);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    onStepCompleted?.call(AnalysisPipelineStep.preparing);

    return HairstyleAnalysisResult(
      imagePath: imagePath,
      faceShape: facePrediction,
      hairDensity: hairDensityPrediction,
      hairType: hairTypePrediction,
      recommendations: recommendations,
      isBald: isBald,
    );
  }

  Future<ClassificationPrediction> _runModel({
    required String assetPath,
    required Float32List input,
    required List<String> labels,
  }) async {
    final interpreter = await Interpreter.fromAsset(assetPath);
    try {
      final inputTensor = interpreter.getInputTensor(0);
      final outputTensor = interpreter.getOutputTensor(0);
      final shapedInput = _alignInputToTensorShape(inputTensor.shape, input);
      final inputBuffer = _reshapeInput(inputTensor.shape, shapedInput);
      final outputBuffer = _createOutputBuffer(outputTensor.shape);

      interpreter.run(inputBuffer, outputBuffer);

      final probabilities = _flattenOutput(outputBuffer);
      final normalized = _toProbabilities(probabilities);
      final index = _argMax(normalized);
      final confidence = normalized[index] * 100;

      return ClassificationPrediction(
        label: labels[index],
        confidence: confidence,
      );
    } finally {
      interpreter.close();
    }
  }

  Float32List _alignInputToTensorShape(List<int> shape, Float32List nhwcInput) {
    if (shape.length != 4 || shape[1] != 3) {
      return nhwcInput;
    }

    final height = shape[2];
    final width = shape[3];
    final nchw = Float32List(height * width * 3);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        for (var c = 0; c < 3; c++) {
          nchw[(c * height * width) + (y * width) + x] =
              nhwcInput[((y * width) + x) * 3 + c];
        }
      }
    }

    return nchw;
  }

  Object _reshapeInput(List<int> shape, Float32List flatInput) {
    if (shape.length == 4) {
      final batch = shape[0];
      final dim1 = shape[1];
      final dim2 = shape[2];
      final dim3 = shape[3];

      if (dim3 == 3) {
        return List.generate(batch, (_) {
          return List.generate(dim1, (y) {
            return List.generate(dim2, (x) {
              final base = ((y * dim2) + x) * 3;
              return List<double>.generate(
                3,
                (c) => flatInput[base + c],
              );
            });
          });
        });
      }

      if (dim1 == 3) {
        final channels = dim1;
        final height = dim2;
        final width = dim3;
        return List.generate(batch, (_) {
          return List.generate(channels, (c) {
            return List.generate(height, (y) {
              return List.generate(width, (x) {
                final index = (c * height * width) + (y * width) + x;
                return flatInput[index];
              });
            });
          });
        });
      }
    }

    if (shape.length == 3) {
      final height = shape[0];
      final width = shape[1];
      final channels = shape[2];
      return List.generate(height, (y) {
        return List.generate(width, (x) {
          final base = ((y * width) + x) * channels;
          return List<double>.generate(
            channels,
            (c) => flatInput[base + c],
          );
        });
      });
    }

    throw UnsupportedError('Unsupported input tensor shape: $shape');
  }

  Object _createOutputBuffer(List<int> shape) {
    final size = shape.fold<int>(1, (value, dim) => value * dim);
    if (shape.length == 2) {
      return [List<double>.filled(shape[1], 0)];
    }
    if (shape.length == 1) {
      return [List<double>.filled(size, 0)];
    }
    return List<double>.filled(size, 0);
  }

  List<double> _flattenOutput(Object output) {
    if (output is List<double>) {
      return output;
    }
    if (output is List && output.isNotEmpty && output.first is List) {
      return (output.first as List).cast<double>();
    }
    if (output is List<num>) {
      return output.map((value) => value.toDouble()).toList();
    }
    throw UnsupportedError('Unsupported output buffer type: ${output.runtimeType}');
  }

  List<double> _toProbabilities(List<double> values) {
    final sum = values.fold<double>(0, (total, value) => total + value);
    if (sum > 0.99 && sum < 1.01) {
      return values;
    }
    return _softmax(values);
  }

  List<double> _softmax(List<double> values) {
    final maxValue = values.reduce(math.max);
    final exps = values.map((value) => math.exp(value - maxValue)).toList();
    final sum = exps.fold<double>(0, (total, value) => total + value);
    return exps.map((value) => value / sum).toList();
  }

  int _argMax(List<double> values) {
    var bestIndex = 0;
    var bestValue = values.first;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > bestValue) {
        bestValue = values[i];
        bestIndex = i;
      }
    }
    return bestIndex;
  }
}
