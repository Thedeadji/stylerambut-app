class HairstyleLabels {
  static const faceClasses = ['Oval', 'Round', 'Square'];
  static const hairDensityClasses = ['medium', 'thick', 'thin'];
  static const hairTypeClasses = ['Straight', 'Wavy', 'curly'];

  static const faceModelAsset = 'assets/pretrainModel/mobilefacenet_best.tflite';
  static const hairDensityModelAsset =
      'assets/pretrainModel/efficientnet_best.tflite';
  static const hairTypeModelAsset =
      'assets/pretrainModel/efficientnet_type_best.keras.tflite';

  static String displayFaceShape(String label) => label;

  static String displayHairDensity(String label) {
    return switch (label.toLowerCase()) {
      'thin' => 'Tipis',
      'medium' => 'Sedang',
      'thick' => 'Tebal',
      'bald / no hair' => 'Botak',
      _ => label,
    };
  }

  static String displayHairType(String label) {
    return switch (label) {
      'Straight' => 'Lurus',
      'Wavy' => 'Bergelombang',
      'curly' => 'Keriting',
      'None' => '-',
      _ => label,
    };
  }

  static String formatHairstyleName(String key) {
    return key
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
