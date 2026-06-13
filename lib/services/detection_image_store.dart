import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Persists detection photos to app documents so history survives app restarts.
class DetectionImageStore {
  DetectionImageStore._();

  static final DetectionImageStore instance = DetectionImageStore._();

  static const _subdir = 'detection_images';

  Directory? _imagesDir;

  Future<Directory> _directory() async {
    if (_imagesDir != null) return _imagesDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_subdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _imagesDir = dir;
    return dir;
  }

  bool isPersistedPath(String path) {
    return path.contains('/$_subdir/') || path.contains('\\$_subdir\\');
  }

  Future<String> persist(String sourcePath) async {
    if (sourcePath.isEmpty || isPersistedPath(sourcePath)) {
      return sourcePath;
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      debugPrint('Detection image missing, cannot persist: $sourcePath');
      return sourcePath;
    }

    final dir = await _directory();
    final extension = _extensionFor(sourcePath);
    final destPath =
        '${dir.path}/detection_${DateTime.now().millisecondsSinceEpoch}$extension';

    await source.copy(destPath);
    return destPath;
  }

  Future<void> deleteIfPersisted(String imagePath) async {
    if (imagePath.isEmpty || !isPersistedPath(imagePath)) {
      return;
    }

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      debugPrint('Failed to delete detection image: $error');
    }
  }

  String _extensionFor(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex >= path.length - 1) {
      return '.jpg';
    }
    final ext = path.substring(dotIndex).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.webp'};
    return allowed.contains(ext) ? ext : '.jpg';
  }
}
