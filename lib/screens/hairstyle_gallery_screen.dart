import 'package:flutter/material.dart';

import '../data/hairstyle_catalog.dart';

class HairstyleGalleryScreen extends StatelessWidget {
  const HairstyleGalleryScreen({super.key});

  static const _backgroundColor = Color(0xFF3D3D3D);
  static const _cardColor = Color(0xFF333333);
  static const _accentColor = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final styles = HairstyleCatalog.allSupportedStyles();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  offset: const Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: _accentColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Gaya Rambut',
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Jelajahi gaya rambut yang disediakan oleh sistem.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: styles.length,
                    itemBuilder: (context, index) {
                      final item = styles[index];
                      return _HairstyleGridTile(
                        item: item,
                        onTap: () => _showHairstyleDetail(context, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHairstyleDetail(BuildContext context, HairstyleCatalogItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => _HairstyleDetailDialog(item: item),
    );
  }
}

class _HairstyleGridTile extends StatelessWidget {
  const _HairstyleGridTile({required this.item, required this.onTap});

  final HairstyleCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 8),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HairstyleDetailDialog extends StatelessWidget {
  const _HairstyleDetailDialog({required this.item});

  final HairstyleCatalogItem item;

  @override
  Widget build(BuildContext context) {
    final images = item.allImages;
    final isWide = MediaQuery.sizeOf(context).width >= 560;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWide ? 720 : 420,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isWide
              ? _buildWideLayout(context, images)
              : _buildCompactLayout(context, images),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, List<String> images) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageStrip(images),
          const SizedBox(height: 18),
          _buildInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, List<String> images) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _buildImageStrip(images, imageHeight: 260),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 6,
          child: _buildInfoSection(context),
        ),
      ],
    );
  }

  Widget _buildImageStrip(List<String> images, {double imageHeight = 180}) {
    if (images.isEmpty) {
      return SizedBox(
        height: imageHeight,
        child: const _HairstyleImagePlaceholder(),
      );
    }

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          images.first,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) =>
              const _HairstyleImagePlaceholder(),
        ),
      );
    }

    return SizedBox(
      height: imageHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 0.82,
              child: Image.asset(
                images[index],
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) =>
                    const _HairstyleImagePlaceholder(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Pria',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item.description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kembali',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HairstyleImagePlaceholder extends StatelessWidget {
  const _HairstyleImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8E8E8),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 40, color: Colors.black38),
    );
  }
}
