import 'dart:io';

import 'package:flutter/material.dart';

import '../data/hairstyle_catalog.dart';
import '../data/hairstyle_labels.dart';
import '../models/history_entry.dart';
import '../models/hairstyle_analysis_result.dart';
import '../services/history_store.dart';
import '../services/settings_store.dart';
import 'detection_screen.dart';

class HairstyleResultScreen extends StatefulWidget {
  const HairstyleResultScreen({super.key, required this.result});

  final HairstyleAnalysisResult result;

  static const accentColor = Color(0xFFFFB732);

  @override
  State<HairstyleResultScreen> createState() => _HairstyleResultScreenState();
}

class _HairstyleResultScreenState extends State<HairstyleResultScreen> {
  HistoryEntry? _savedEntry;
  late final List<HairstyleCatalogItem> _catalogItems;

  @override
  void initState() {
    super.initState();
    _catalogItems = HairstyleCatalog.fromRecommendations(
      widget.result.recommendations,
    );
  }

  Future<void> _saveSelectedStyleToHistory(String style) async {
    if (SettingsStore.instance.jedaHistoryEnabled) return;

    final alreadySaved = HistoryStore.instance.entries.value.any(
      (entry) =>
          entry.result.imagePath == widget.result.imagePath &&
          entry.style == style,
    );
    if (alreadySaved) return;

    final entry = HistoryEntry(
      result: widget.result,
      style: style,
      timestamp: DateTime.now(),
    );
    _savedEntry = await HistoryStore.instance.add(entry);
  }

  void _onSelectRecommendation(String style) async {
    await _saveSelectedStyleToHistory(style);

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/history',
        (route) => route.settings.name == '/home' || route.isFirst,
      );
    }
  }

  HairstyleAnalysisResult get _result => widget.result;

  static const backgroundColor = Color(0xFF2F2F2F);

  void _navigateToRetake(BuildContext context) async {
    if (_savedEntry != null) {
      await HistoryStore.instance.remove(_savedEntry!);
      _savedEntry = null;
    }

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DetectionScreen()),
      (route) {
        final name = route.settings.name;
        return name == '/home' || name == '/history' || route.isFirst;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3D3D3D), Color(0xFF212121)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              left: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              right: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Hasil Analisa Wajah Dan Rambut Kamu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SectionDivider(),
                    const SizedBox(height: 20),
                    _ProfileAvatar(imagePath: _result.imagePath),
                    const SizedBox(height: 20),
                    const _SectionDivider(),
                    const SizedBox(height: 20),
                    _AnalysisResultsSection(result: _result),
                    const SizedBox(height: 20),
                    const _SectionDivider(),
                    const SizedBox(height: 20),
                    const Text(
                      'Rekomendasi Yang Cocok Untuk Kamu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._catalogItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _RecommendationCard(
                          item: item,
                          onSelect: () => _onSelectRecommendation(item.title),
                        ),
                      ),
                    ),
                    _RetakePhotoCard(onTap: () => _navigateToRetake(context)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1.5, color: HairstyleResultScreen.accentColor);
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
        color: Colors.white,
      ),
      child: ClipOval(
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) =>
              const _AvatarPlaceholder(),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE8E8E8),
      child: Icon(Icons.person, size: 72, color: Colors.black45),
    );
  }
}

class _AnalysisResultsSection extends StatelessWidget {
  const _AnalysisResultsSection({required this.result});

  final HairstyleAnalysisResult result;

  static const double _labelHeight = 36.0;

  static const _labelStyle = TextStyle(
    color: HairstyleResultScreen.accentColor,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: _labelHeight,
                    alignment: Alignment.bottomLeft,
                    child: const Text('Wajah :', style: _labelStyle),
                  ),
                  const SizedBox(height: 8),
                  _ValueBox(
                    text: HairstyleLabels.displayFaceShape(
                      result.faceShape.label,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: _labelHeight,
                    alignment: Alignment.bottomCenter,
                    child: const Text(
                      'Akurasi\nDeteksi :',
                      textAlign: TextAlign.center,
                      style: _labelStyle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ValueBox(text: result.faceShape.confidencePercent),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: _labelHeight,
                    alignment: Alignment.bottomLeft,
                    child: const Text('Ketebalan :', style: _labelStyle),
                  ),
                  const SizedBox(height: 8),
                  _ValueBox(
                    text: HairstyleLabels.displayHairDensity(
                      result.hairDensity.label,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: _labelHeight),
                  const SizedBox(height: 8),
                  _ValueBox(text: result.hairDensity.confidencePercent),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: _labelHeight,
                    alignment: Alignment.bottomLeft,
                    child: const Text('Tipe :', style: _labelStyle),
                  ),
                  const SizedBox(height: 8),
                  _ValueBox(
                    text: HairstyleLabels.displayHairType(
                      result.hairType.label,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: _labelHeight),
                  const SizedBox(height: 8),
                  _ValueBox(text: result.hairType.confidencePercent),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HairstyleResultScreen.accentColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.onSelect});

  final HairstyleCatalogItem item;
  final VoidCallback onSelect;

  bool get _isPlainMessage => item.imageAsset == null && item.id.contains(' ');

  @override
  Widget build(BuildContext context) {
    if (_isPlainMessage) {
      return _ResultCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return _ResultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              child: item.imageAsset != null
                  ? Image.asset(
                      item.imageAsset!,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) =>
                          const _HairstyleImagePlaceholder(),
                    )
                  : const _HairstyleImagePlaceholder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _SelectButton(onTap: onSelect),
        ],
      ),
    );
  }
}

class _RetakePhotoCard extends StatelessWidget {
  const _RetakePhotoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ulangi Pengambilan Foto?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _SelectButton(onTap: onTap),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HairstyleResultScreen.accentColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: const Text(
            'Pilih',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _HairstyleImagePlaceholder extends StatelessWidget {
  const _HairstyleImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE8E8E8),
      child: Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.black38),
      ),
    );
  }
}
