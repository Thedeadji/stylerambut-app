import 'dart:io';

import 'package:flutter/material.dart';

import '../data/hairstyle_catalog.dart';
import '../data/hairstyle_labels.dart';
import '../models/hairstyle_analysis_result.dart';
import '../models/history_entry.dart';
import '../services/history_store.dart';
import '../widgets/result_export_card.dart';
import '../utils/result_saver.dart';

class HistoryResultScreen extends StatefulWidget {
  const HistoryResultScreen({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  State<HistoryResultScreen> createState() => _HistoryResultScreenState();
}

class _HistoryResultScreenState extends State<HistoryResultScreen> {
  late HistoryEntry _entry;
  final GlobalKey _saveKey = GlobalKey();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  String get _formattedDate {
    final date = _entry.timestamp.toLocal();
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

  Future<void> _renameEntry() async {
    final controller = TextEditingController(text: _entry.resultLabel);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ganti nama hasil'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Masukkan nama baru'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty) return;

    final updated = HistoryEntry(
      id: _entry.id,
      result: _entry.result,
      style: _entry.style,
      timestamp: _entry.timestamp,
      resultLabel: newName,
    );
    HistoryStore.instance.update(_entry, updated);
    setState(() => _entry = updated);
  }

  void _deleteEntry() {
    HistoryStore.instance.remove(_entry);
    Navigator.of(context).pop();
  }

  void _saveEntry() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB732)),
        ),
      ),
    );

    try {
      final path = await ResultSaver.saveResultAsPng(
        repaintKey: _saveKey,
        entry: _entry,
        context: context,
      );

      if (mounted) Navigator.of(context).pop();

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gambar berhasil disimpan ke: $path'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan gambar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showHairstylePopup() {
    final key = _entry.style.toLowerCase().replaceAll(' ', '_');
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

    HairstyleCatalogItem item;
    if (standardKeys.contains(key)) {
      item = HairstyleCatalog.fromRecommendationKey(key);
    } else {
      item = HairstyleCatalogItem(
        id: key,
        title: HairstyleLabels.formatHairstyleName(_entry.style),
        description:
            'Gaya rambut pilihan Anda berdasarkan hasil deteksi wajah.',
      );
    }

    showDialog(
      context: context,
      builder: (context) => _HairstyleDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F2F2F),
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
            // Background decorative circles
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
                    // Header row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF333333),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Color(0xFFFFB732),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Result',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Main Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        children: [
                          // Card Header (Icon, Title, Date)
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB732),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.black,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _entry.resultLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    HairstyleLabels.formatHairstyleName(
                                      _entry.style,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formattedDate,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(
                            color: Colors.white12,
                            height: 1,
                            thickness: 1,
                          ),
                          const SizedBox(height: 20),

                          // Face Profile Avatar
                          CircleAvatar(
                            radius: 68,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Image.file(
                                File(_entry.result.imagePath),
                                width: 132,
                                height: 132,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.person,
                                      size: 72,
                                      color: Colors.black26,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(
                            color: Colors.white12,
                            height: 1,
                            thickness: 1,
                          ),
                          const SizedBox(height: 20),

                          // Analysis Results Section
                          _AnalysisResultsSection(result: _entry.result),
                          const SizedBox(height: 20),
                          const Divider(
                            color: Colors.white12,
                            height: 1,
                            thickness: 1,
                          ),
                          const SizedBox(height: 12),

                          // Show Hairstyle Text Button
                          TextButton(
                            onPressed: _showHairstylePopup,
                            child: const Text(
                              'Show Hairstyle',
                              style: TextStyle(
                                color: Color(0xFFFFB732),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Bottom Action Tiles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ActionTile(
                          label: 'Rename',
                          icon: Icons.edit,
                          onTap: _renameEntry,
                        ),
                        const SizedBox(width: 32),
                        _ActionTile(
                          label: 'Delete',
                          icon: Icons.delete,
                          onTap: _deleteEntry,
                        ),
                        const SizedBox(width: 32),
                        _ActionTile(
                          label: 'Save',
                          icon: Icons.save,
                          onTap: _saveEntry,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Positioned(
              left: -9999,
              child: RepaintBoundary(
                key: _saveKey,
                child: ResultExportCard(entry: _entry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisResultsSection extends StatelessWidget {
  const _AnalysisResultsSection({required this.result});

  final HairstyleAnalysisResult result;

  static const double _labelHeight = 36.0;

  static const _labelStyle = TextStyle(
    color: Color(0xFFFFB732),
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column (Labels and values)
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                Container(
                  height: _labelHeight,
                  alignment: Alignment.bottomLeft,
                  child: const Text('Tipe :', style: _labelStyle),
                ),
                const SizedBox(height: 8),
                _ValueBox(
                  text: HairstyleLabels.displayHairType(result.hairType.label),
                ),
              ],
            ),
          ),
          // Vertical divider
          Container(
            width: 1,
            color: Colors.white12,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Right Column (Akurasi Deteksi and values)
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
                const SizedBox(height: 16),
                const SizedBox(height: _labelHeight),
                const SizedBox(height: 8),
                _ValueBox(text: result.hairDensity.confidencePercent),
                const SizedBox(height: 16),
                const SizedBox(height: _labelHeight),
                const SizedBox(height: 8),
                _ValueBox(text: result.hairType.confidencePercent),
              ],
            ),
          ),
        ],
      ),
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
        border: Border.all(color: const Color(0xFFFFB732), width: 1.5),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB732),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HairstyleDialog extends StatelessWidget {
  const _HairstyleDialog({required this.item});

  final HairstyleCatalogItem item;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF333333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (item.imageAsset != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  item.imageAsset!,
                  width: 160,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const _HairstyleImagePlaceholder(),
                ),
              )
            else
              const _HairstyleImagePlaceholder(),
            const SizedBox(height: 20),
            Text(
              item.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 140,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB732),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HairstyleImagePlaceholder extends StatelessWidget {
  const _HairstyleImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.black38),
      ),
    );
  }
}
