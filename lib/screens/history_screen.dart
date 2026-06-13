import 'package:flutter/material.dart';

import '../data/hairstyle_labels.dart';
import '../models/history_entry.dart';
import '../services/history_store.dart';
import 'dashboard_screen.dart';
import 'history_result_screen.dart';
import '../widgets/result_export_card.dart';
import '../utils/result_saver.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GlobalKey _saveKey = GlobalKey();
  HistoryEntry? _entryToSave;
  bool _isSaving = false;

  String? _filterHairstyle;
  String? _filterFaceShape;
  String? _filterHairDensity;
  String _sortBy = 'newest';

  int get _activeFiltersCount {
    int count = 0;
    if (_filterHairstyle != null) count++;
    if (_filterFaceShape != null) count++;
    if (_filterHairDensity != null) count++;
    return count;
  }

  List<HistoryEntry> _getFilteredEntries(List<HistoryEntry> allEntries) {
    var result = List<HistoryEntry>.from(allEntries);
    if (_filterHairstyle != null) {
      result = result.where((e) => e.style == _filterHairstyle).toList();
    }
    if (_filterFaceShape != null) {
      result = result.where((e) => e.result.faceShape.label == _filterFaceShape).toList();
    }
    if (_filterHairDensity != null) {
      result = result.where((e) => e.result.hairDensity.label == _filterHairDensity).toList();
    }
    if (_sortBy == 'newest') {
      result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return result;
  }

  void _showFilters() async {
    final allEntries = HistoryStore.instance.entries.value;
    final availableHairstyles = allEntries.map((e) => e.style).toSet().toList();
    final availableFaceShapes = allEntries.map((e) => e.result.faceShape.label).toSet().toList();
    final availableHairDensities = allEntries.map((e) => e.result.hairDensity.label).toSet().toList();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        initialHairstyle: _filterHairstyle,
        initialFaceShape: _filterFaceShape,
        initialHairDensity: _filterHairDensity,
        initialSortBy: _sortBy,
        availableHairstyles: availableHairstyles,
        availableFaceShapes: availableFaceShapes,
        availableHairDensities: availableHairDensities,
      ),
    );

    if (result != null) {
      setState(() {
        _filterHairstyle = result['hairstyle'] as String?;
        _filterFaceShape = result['faceShape'] as String?;
        _filterHairDensity = result['hairDensity'] as String?;
        _sortBy = result['sortBy'] as String? ?? 'newest';
      });
    }
  }

  void _saveEntry(HistoryEntry entry) async {
    if (_isSaving) return;
    setState(() {
      _entryToSave = entry;
      _isSaving = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
        ),
      ),
    );

    try {
      final path = await ResultSaver.saveResultAsPng(
        repaintKey: _saveKey,
        entry: entry,
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
          _entryToSave = null;
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D3D3D),
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9CA8C2).withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9CA8C2).withValues(alpha: 0.08),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'assets/icon/settingbutton.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _showFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(120, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _activeFiltersCount > 0
                                  ? 'Filters ($_activeFiltersCount)'
                                  : 'Filters',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.tune, size: 16),
                          ],
                        ),
                      ),
                      if (_activeFiltersCount > 0) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filterHairstyle = null;
                              _filterFaceShape = null;
                              _filterHairDensity = null;
                              _sortBy = 'newest';
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<List<HistoryEntry>>(
                    valueListenable: HistoryStore.instance.entries,
                    builder: (context, entries, child) {
                      if (entries.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Belum ada riwayat deteksi. Hasil yang sudah dipilih akan muncul di sini.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      final filteredEntries = _getFilteredEntries(entries);

                      if (filteredEntries.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tidak ada riwayat deteksi yang sesuai dengan filter saat ini.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: filteredEntries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _HistoryRow(
                              entry: entry,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HistoryResultScreen(entry: entry),
                                  ),
                                );
                              },
                              onDelete: () {
                                HistoryStore.instance.remove(entry);
                              },
                              onSave: () => _saveEntry(entry),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Custom Floating Bottom Navigation matching dashboard
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 30, right: 30),
                child: SizedBox(
                  height: 76,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              offset: Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                splashColor: Colors.white24,
                                highlightColor: Colors.white10,
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => const DashboardScreen(),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                      settings: const RouteSettings(
                                        name: '/home',
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 10,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/icon/homebutton.png',
                                        width: 22,
                                        height: 22,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Menu',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 50),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                splashColor: Colors.white24,
                                highlightColor: Colors.white10,
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 10,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/icon/historybutton.png',
                                        width: 22,
                                        height: 22,
                                        color: const Color(0xFFFFC107),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'History',
                                        style: TextStyle(
                                          color: Color(0xFFFFC107),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        width: 28,
                                        height: 2,
                                        color: const Color(0xFFFFC107),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -10,
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/detection'),
                          child: Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFC107),
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFC107,
                                  ).withValues(alpha: 0.8),
                                  spreadRadius: 6,
                                  blurRadius: 18,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset('assets/icon/camerabutton.png'),
                                Image.asset('assets/icon/camerabutton.png'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_entryToSave != null)
              Positioned(
                left: -9999,
                child: RepaintBoundary(
                  key: _saveKey,
                  child: ResultExportCard(entry: _entryToSave!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.onTap,
    required this.onDelete,
    required this.onSave,
  });

  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSave;

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.black),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.resultLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    HairstyleLabels.formatHairstyleName(entry.style),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formattedDate,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSave,
              child: const Icon(Icons.save, color: Colors.white54),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: () {
                onDelete();
              },
              child: const Icon(Icons.delete, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    required this.initialHairstyle,
    required this.initialFaceShape,
    required this.initialHairDensity,
    required this.initialSortBy,
    required this.availableHairstyles,
    required this.availableFaceShapes,
    required this.availableHairDensities,
  });

  final String? initialHairstyle;
  final String? initialFaceShape;
  final String? initialHairDensity;
  final String initialSortBy;
  final List<String> availableHairstyles;
  final List<String> availableFaceShapes;
  final List<String> availableHairDensities;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _selectedHairstyle;
  String? _selectedFaceShape;
  String? _selectedHairDensity;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _selectedHairstyle = widget.initialHairstyle;
    _selectedFaceShape = widget.initialFaceShape;
    _selectedHairDensity = widget.initialHairDensity;
    _sortBy = widget.initialSortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter & Urutkan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Urutkan Tanggal',
                      style: TextStyle(
                        color: Color(0xFFFFC107),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildChoiceChip(
                          label: 'Terbaru',
                          isSelected: _sortBy == 'newest',
                          onSelected: (_) => setState(() => _sortBy = 'newest'),
                        ),
                        const SizedBox(width: 8),
                        _buildChoiceChip(
                          label: 'Terlama',
                          isSelected: _sortBy == 'oldest',
                          onSelected: (_) => setState(() => _sortBy = 'oldest'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (widget.availableHairstyles.isNotEmpty) ...[
                      const Text(
                        'Gaya Rambut',
                        style: TextStyle(
                          color: Color(0xFFFFC107),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChoiceChip(
                            label: 'Semua',
                            isSelected: _selectedHairstyle == null,
                            onSelected: (_) => setState(() => _selectedHairstyle = null),
                          ),
                          ...widget.availableHairstyles.map(
                            (style) => _buildChoiceChip(
                              label: HairstyleLabels.formatHairstyleName(style),
                              isSelected: _selectedHairstyle == style,
                              onSelected: (_) => setState(() => _selectedHairstyle = style),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (widget.availableFaceShapes.isNotEmpty) ...[
                      const Text(
                        'Bentuk Wajah',
                        style: TextStyle(
                          color: Color(0xFFFFC107),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChoiceChip(
                            label: 'Semua',
                            isSelected: _selectedFaceShape == null,
                            onSelected: (_) => setState(() => _selectedFaceShape = null),
                          ),
                          ...widget.availableFaceShapes.map(
                            (face) => _buildChoiceChip(
                              label: HairstyleLabels.displayFaceShape(face),
                              isSelected: _selectedFaceShape == face,
                              onSelected: (_) => setState(() => _selectedFaceShape = face),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (widget.availableHairDensities.isNotEmpty) ...[
                      const Text(
                        'Ketebalan Rambut',
                        style: TextStyle(
                          color: Color(0xFFFFC107),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChoiceChip(
                            label: 'Semua',
                            isSelected: _selectedHairDensity == null,
                            onSelected: (_) => setState(() => _selectedHairDensity = null),
                          ),
                          ...widget.availableHairDensities.map(
                            (density) => _buildChoiceChip(
                              label: HairstyleLabels.displayHairDensity(density),
                              isSelected: _selectedHairDensity == density,
                              onSelected: (_) => setState(() => _selectedHairDensity = density),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedHairstyle = null;
                        _selectedFaceShape = null;
                        _selectedHairDensity = null;
                        _sortBy = 'newest';
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Reset Semua',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'hairstyle': _selectedHairstyle,
                        'faceShape': _selectedFaceShape,
                        'hairDensity': _selectedHairDensity,
                        'sortBy': _sortBy,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFFFFC107),
      backgroundColor: const Color(0xFF444444),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFFFFC107) : Colors.white12,
          width: 1,
        ),
      ),
      showCheckmark: false,
    );
  }
}
