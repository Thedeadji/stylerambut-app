import 'dart:io';
import 'package:flutter/material.dart';
import '../models/history_entry.dart';
import '../data/hairstyle_labels.dart';
import '../data/hairstyle_catalog.dart';

class ResultExportCard extends StatelessWidget {
  const ResultExportCard({
    super.key,
    required this.entry,
  });

  final HistoryEntry entry;

  String get _formattedDate {
    final date = entry.timestamp.toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour >= 12 ? 'pm' : 'am';
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}, $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final key = entry.style.toLowerCase().replaceAll(' ', '_');
    final standardKeys = [
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
      'crew_cut',
      'faux_hawk',
    ];

    String? hairstyleImageAsset;
    if (standardKeys.contains(key)) {
      final item = HairstyleCatalog.fromRecommendationKey(key);
      hairstyleImageAsset = item.imageAsset;
    }

    return Container(
      width: 400,
      height: 700,
      decoration: const BoxDecoration(
        color: Color(0xFF3D3D3D),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Date/Time text at the top center
          Text(
            _formattedDate,
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 24),

          // 2. Circular Face Profile Avatar
          Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: ClipOval(
              child: Image.file(
                File(entry.result.imagePath),
                width: 136,
                height: 136,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[700],
                  child: const Icon(
                    Icons.person,
                    size: 72,
                    color: Colors.white30,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),

          // 3. Recommended Hairstyle Image
          Container(
            width: 160,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black26, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: hairstyleImageAsset != null
                  ? Image.asset(
                      hairstyleImageAsset,
                      width: 160,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _ImagePlaceholder(),
                    )
                  : const _ImagePlaceholder(),
            ),
          ),
          const Spacer(),

          // 4. Grid of 4 Analysis boxes (Wajah, Ketebalan, Tipe, Gaya Rambut)
          Table(
            children: [
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 16),
                    child: _GridItem(
                      label: 'Wajah :',
                      value: HairstyleLabels.displayFaceShape(
                        entry.result.faceShape.label,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 16),
                    child: _GridItem(
                      label: 'Ketebalan :',
                      value: HairstyleLabels.displayHairDensity(
                        entry.result.hairDensity.label,
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _GridItem(
                      label: 'Tipe :',
                      value: HairstyleLabels.displayHairType(
                        entry.result.hairType.label,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _GridItem(
                      label: 'Gaya Rambut :',
                      value: HairstyleLabels.formatHairstyleName(entry.style),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFB732),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 180,
      color: const Color(0xFFE8E8E8),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.black38,
        ),
      ),
    );
  }
}
