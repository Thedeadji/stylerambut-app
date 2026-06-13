import 'dart:math';

import 'hairstyle_labels.dart';

class HairstyleCatalogItem {
  const HairstyleCatalogItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageAsset,
    this.imageAssets = const [],
  });

  final String id;
  final String title;
  final String description;
  final String? imageAsset;
  final List<String> imageAssets;

  List<String> get allImages {
    if (imageAssets.isNotEmpty) {
      return imageAssets;
    }
    if (imageAsset != null) {
      return [imageAsset!];
    }
    return const [];
  }
}

class HairstyleCatalog {
  static const supportedStyleKeys = [
    'pompadour',
    'quiff',
    'slick_back',
    'textured_crop',
    'comb_over',
    'curly_top',
    'undercut',
    'side_part',
    'french_crop',
    'buzz_cut',
    'faux_hawk',
  ];

  static const _descriptions = <String, String>{
    'pompadour':
        'Gaya klasik dengan volume tinggi di bagian atas dan sisi yang lebih rapi, cocok menonjolkan bentuk wajah oval.',
    'quiff':
        'Rambut ditinggikan ke depan dengan transisi fade di sisi, memberi kesan modern dan tegas.',
    'slick_back':
        'Rambut disisir ke belakang dengan tampilan rapi dan elegan, ideal untuk penampilan formal.',
    'textured_crop':
        'Potongan pendek dengan tekstur berlapis di atas kepala, praktis dan tetap stylish.',
    'comb_over':
        'Rambut disisir menyamping dengan garis rapi, menyeimbangkan proporsi wajah bulat.',
    'curly_top':
        'Volume ikal atau keriting di bagian atas dengan sisi yang lebih pendek untuk tampilan dinamis.',
    'undercut':
        'Kontras kuat antara sisi sangat pendek dan bagian atas lebih panjang, sangat populer untuk gaya maskulin.',
    'side_part':
        'Garis belahan jelas dengan sisi rapi, memberi kesan profesional dan bersih.',
    'french_crop':
        'Potongan pendek dengan fringe di dahi, cocok untuk rambut tipis hingga sedang.',
    'buzz_cut':
        'Potongan sangat pendek dan merata, minimal perawatan dengan tampilan tegas.',
    'crew_cut':
        'Varian pendek dengan sedikit volume di atas, serbaguna untuk berbagai bentuk wajah.',
    'faux_hawk':
        'Puncak lebih tinggi dengan sisi fade, memberi kesan berani tanpa ekstrem.',
  };

  static HairstyleCatalogItem fromRecommendationKey(String key) {
    if (key.contains(' ') || key.toLowerCase().contains('rekomendasi')) {
      return HairstyleCatalogItem(id: key, title: key, description: key);
    }

    final item = itemForKey(key);
    final images = item.imageAssets;
    if (images.isEmpty) {
      return item;
    }

    return HairstyleCatalogItem(
      id: item.id,
      title: item.title,
      description: item.description,
      imageAsset: images[_random.nextInt(images.length)],
      imageAssets: images,
    );
  }

  static HairstyleCatalogItem itemForKey(String key) {
    final images = _imageAssetsFor(key);

    return HairstyleCatalogItem(
      id: key,
      title: HairstyleLabels.formatHairstyleName(key),
      description:
          _descriptions[key] ??
          'Gaya rambut yang direkomendasikan berdasarkan hasil analisis wajah dan rambut Anda.',
      imageAsset: images.isNotEmpty ? images.first : null,
      imageAssets: images,
    );
  }

  static List<HairstyleCatalogItem> allSupportedStyles() {
    return supportedStyleKeys.map(itemForKey).toList();
  }

  static List<String> _imageAssetsFor(String key) {
    final count = _styleImageCounts[key];
    if (count == null || count <= 0) {
      return const [];
    }

    return List.generate(
      count,
      (index) => 'assets/image/hairstyle/$key/$key${index + 1}.jpg',
    );
  }

  static final Random _random = Random();

  static const Map<String, int> _styleImageCounts = {
    'pompadour': 3,
    'quiff': 3,
    'slick_back': 3,
    'textured_crop': 3,
    'comb_over': 3,
    'curly_top': 3,
    'undercut': 3,
    'side_part': 3,
    'french_crop': 3,
    'buzz_cut': 3,
    'faux_hawk': 3,
  };

  static List<HairstyleCatalogItem> fromRecommendations(
    List<String> recommendations,
  ) {
    return recommendations.map(fromRecommendationKey).toList();
  }
}
