import 'dart:io';

import 'package:flutter/material.dart';

import '../models/appearance_detection_result.dart';
import '../services/face_detection_service.dart';
import '../widgets/detection_bounding_box_overlay.dart';
import 'process_image_screen.dart';

class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({super.key, required this.imagePath});

  final String imagePath;

  static const accentColor = Color(0xFFFFC107);
  static const panelColor = Color(0xFF111111);

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  final FaceDetectionService _faceDetectionService = FaceDetectionService();

  AppearanceDetectionResult? _result;
  bool _isDetecting = true;
  String? _errorMessage;
  String? _tempImagePath;

  @override
  void initState() {
    super.initState();
    _runDetection();
  }

  @override
  void dispose() {
    _faceDetectionService.dispose();
    if (_tempImagePath != null) {
      File(_tempImagePath!).delete().ignore();
    }
    super.dispose();
  }

  Future<void> _runDetection() async {
    try {
      final result = await _faceDetectionService.detect(widget.imagePath);
      if (!mounted) return;
      if (result.displayImagePath != widget.imagePath) {
        _tempImagePath = result.displayImagePath;
      }
      setState(() {
        _result = result;
        _isDetecting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
        _errorMessage = 'Gagal mendeteksi wajah';
      });
    }
  }

  String get _statusText {
    if (_isDetecting) {
      return 'Mendeteksi penampilan...';
    }
    if (_errorMessage != null || _result?.isDetected != true) {
      return 'tidak terdeteksi tampilan';
    }
    return 'Penampilan Terdeteksi';
  }

  String get _displayImagePath =>
      _result?.displayImagePath ?? widget.imagePath;

  List<DetectionBox> get _detectionBoxes {
    final result = _result;
    if (result == null || !result.isDetected) {
      return const [];
    }

    return [
      if (result.faceRect != null)
        DetectionBox(
          rect: result.faceRect!,
          label: 'wajah',
          color: ConfirmScreen.accentColor,
        ),
      if (result.hairRect != null)
        DetectionBox(
          rect: result.hairRect!,
          label: 'rambut',
          color: const Color(0xFF4FC3F7),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF2A2A2A),
                    child: Image.file(
                      File(_displayImagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Text(
                          'Gagal memuat foto',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  if (_result?.isDetected == true && _result!.imageSize != Size.zero)
                    DetectionBoundingBoxOverlay(
                      boxes: _detectionBoxes,
                      imageSize: _result!.imageSize,
                    ),
                  if (_isDetecting)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: ConfirmScreen.accentColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              color: ConfirmScreen.panelColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 1.5,
                    color: ConfirmScreen.accentColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      _statusText,
                      style: TextStyle(
                        color: _statusText == 'tidak terdeteksi tampilan'
                            ? Colors.white70
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Return',
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionButton(
                            label: 'Process',
                            onTap: _result?.isDetected == true
                                ? () {
                                    Navigator.push<void>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProcessImageScreen(
                                          imagePath: _displayImagePath,
                                          faceRect: _result!.faceRect!,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ConfirmScreen.accentColor.withValues(
        alpha: onTap == null ? 0.45 : 1,
      ),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
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
