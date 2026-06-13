import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/history_entry.dart';
import '../data/hairstyle_catalog.dart';

class ResultSaver {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check for photo library permission first on Android 13+
      var photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted) {
        return true;
      }

      // Also check standard storage permission
      var storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }

      // Request storage permission first
      storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }

      // If storage is denied, request photos permission (Android 13+)
      photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    }
    return true; // Non-Android platforms
  }

  static Future<String?> saveResultAsPng({
    required GlobalKey repaintKey,
    required HistoryEntry entry,
    required BuildContext context,
  }) async {
    try {
      // 1. Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Izin penyimpanan ditolak.');
      }

      // 2. Precache images used inside the ResultExportCard before capturing
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

      // Precache face photo
      final faceFile = File(entry.result.imagePath);
      if (await faceFile.exists()) {
        if (!context.mounted) return null;
        await precacheImage(FileImage(faceFile), context);
      }

      // Precache hairstyle catalog image if applicable
      if (standardKeys.contains(key)) {
        final item = HairstyleCatalog.fromRecommendationKey(key);
        if (item.imageAsset != null) {
          if (!context.mounted) return null;
          await precacheImage(AssetImage(item.imageAsset!), context);
        }
      }

      // Wait to ensure the images are fully drawn/rendered in the widget tree
      await Future.delayed(const Duration(milliseconds: 400));

      // 3. Find the RepaintBoundary render object
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Gagal menemukan objek gambar untuk disimpan.');
      }

      // 4. Capture the image
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal memproses data gambar.');
      }
      final pngBytes = byteData.buffer.asUint8List();

      // 5. Get DCIM directory path
      String? rootPath;
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final paths = extDir.path.split('/');
          final androidIndex = paths.indexOf('Android');
          if (androidIndex != -1) {
            rootPath = paths.sublist(0, androidIndex).join('/');
          }
        }
        rootPath ??= '/storage/emulated/0';
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        rootPath = docDir.path;
      }

      final saveDir = Directory('$rootPath/DCIM/StyleRambut Result');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // 6. Generate filename using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${saveDir.path}/stylerambut_$timestamp.png');

      // 7. Write to file
      await file.writeAsBytes(pngBytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving result: $e');
      rethrow;
    }
  }
}
