class ClassificationPrediction {
  const ClassificationPrediction({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence;

  String get confidencePercent => '${confidence.toStringAsFixed(2)}%';

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
    };
  }

  factory ClassificationPrediction.fromMap(Map<String, dynamic> map) {
    return ClassificationPrediction(
      label: map['label'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HairstyleAnalysisResult {
  const HairstyleAnalysisResult({
    required this.imagePath,
    required this.faceShape,
    required this.hairDensity,
    required this.hairType,
    required this.recommendations,
    this.isBald = false,
  });

  final String imagePath;
  final ClassificationPrediction faceShape;
  final ClassificationPrediction hairDensity;
  final ClassificationPrediction hairType;
  final List<String> recommendations;
  final bool isBald;

  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'faceShape': faceShape.toMap(),
      'hairDensity': hairDensity.toMap(),
      'hairType': hairType.toMap(),
      'recommendations': recommendations,
      'isBald': isBald,
    };
  }

  factory HairstyleAnalysisResult.fromMap(Map<String, dynamic> map) {
    return HairstyleAnalysisResult(
      imagePath: map['imagePath'] as String? ?? '',
      faceShape: ClassificationPrediction.fromMap(
        Map<String, dynamic>.from(map['faceShape'] ?? {}),
      ),
      hairDensity: ClassificationPrediction.fromMap(
        Map<String, dynamic>.from(map['hairDensity'] ?? {}),
      ),
      hairType: ClassificationPrediction.fromMap(
        Map<String, dynamic>.from(map['hairType'] ?? {}),
      ),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      isBald: map['isBald'] as bool? ?? false,
    );
  }

  HairstyleAnalysisResult copyWith({String? imagePath}) {
    return HairstyleAnalysisResult(
      imagePath: imagePath ?? this.imagePath,
      faceShape: faceShape,
      hairDensity: hairDensity,
      hairType: hairType,
      recommendations: recommendations,
      isBald: isBald,
    );
  }
}
