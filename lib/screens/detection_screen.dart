import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'confirm_screen.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen>
    with WidgetsBindingObserver {
  final List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _disposed = false;
  FlashMode _flashMode = FlashMode.off;
  String? _cameraError;
  int _selectedCameraIndex = 0;
  bool _isTakingPicture = false;
  bool _isSwitchingCamera = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    final controller = _cameraController;
    if (controller != null) {
      _cameraController = null;
      controller.dispose().catchError((Object e) {
        debugPrint('Error disposing camera controller: $e');
      });
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isSwitchingCamera || _isTakingPicture) {
      return;
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.paused) {
      _pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      _resumeCamera();
    }
  }

  Future<void> _pauseCamera() async {
    final controller = _cameraController;
    if (controller == null) return;
    _cameraController = null;
    setState(() => _isInitialized = false);
    try {
      await controller.pausePreview();
    } catch (_) {
      // ignore if preview is already stopped or not available
    }
    try {
      await controller.dispose();
    } catch (e) {
      debugPrint('Error disposing camera controller in pause: $e');
    }
  }

  Future<void> _resumeCamera() async {
    if (_cameras.isEmpty || _isSwitchingCamera) return;
    await _createCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _initializeCamera() async {
    // Brief delay to allow camera resources from any previous screen to be
    // fully released. Prevents CameraX "No supported surface combination"
    // errors on Android when navigating back via pushAndRemoveUntil.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _disposed) return;
    try {
      final cameras = await availableCameras();
      if (!mounted || _disposed) return;
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'Kamera tidak tersedia';
        });
        return;
      }
      _cameras.addAll(cameras);
      _selectedCameraIndex = _indexForLens(CameraLensDirection.back);
      await _createCameraController(_cameras[_selectedCameraIndex]);
    } on CameraException catch (exception) {
      setState(() {
        _cameraError = exception.description ?? exception.code;
      });
    } catch (error) {
      setState(() {
        _cameraError = error.toString();
      });
    }
  }

  int _indexForLens(CameraLensDirection direction) {
    final index = _cameras.indexWhere(
      (camera) => camera.lensDirection == direction,
    );
    return index >= 0 ? index : 0;
  }

  int _nextCameraIndex() {
    if (_cameras.length < 2) {
      return _selectedCameraIndex;
    }

    final current = _cameras[_selectedCameraIndex];
    final targetDirection = current.lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    return _indexForLens(targetDirection);
  }

  bool get _isFrontCamera =>
      _cameras.isNotEmpty &&
      _cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front;

  ImageFormatGroup _imageFormatFor(CameraDescription camera) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ImageFormatGroup.bgra8888;
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        camera.lensDirection == CameraLensDirection.front) {
      // JPEG preview sering hang pada kamera depan Android.
      return ImageFormatGroup.yuv420;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return ImageFormatGroup.jpeg;
    }
    return ImageFormatGroup.yuv420;
  }

  ResolutionPreset _resolutionFor(CameraDescription camera) {
    if (camera.lensDirection == CameraLensDirection.front) {
      return ResolutionPreset.low;
    }
    return ResolutionPreset.medium;
  }

  Future<void> _createCameraController(CameraDescription camera) async {
    final previousController = _cameraController;
    _cameraController = null;

    if (mounted) {
      setState(() {
        _isInitialized = false;
        _cameraError = null;
      });
    }

    if (previousController != null) {
      try {
        await previousController.dispose();
      } catch (e) {
        debugPrint('Error disposing previous camera controller: $e');
      }
    }
    if (!mounted) return;

    final controller = CameraController(
      camera,
      _resolutionFor(camera),
      enableAudio: false,
      imageFormatGroup: _imageFormatFor(camera),
    );

    try {
      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw CameraException('initTimeout', 'Kamera tidak merespons');
        },
      );
      if (!mounted) {
        try {
          await controller.dispose();
        } catch (e) {
          debugPrint('Error disposing camera controller after unmount: $e');
        }
        return;
      }

      if (camera.lensDirection == CameraLensDirection.back) {
        try {
          await controller.setFlashMode(_flashMode);
        } catch (_) {
          _flashMode = FlashMode.off;
          try {
            await controller.setFlashMode(FlashMode.off);
          } catch (_) {
            // Flash tidak didukung pada perangkat ini.
          }
        }
      } else {
        _flashMode = FlashMode.off;
      }

      setState(() {
        _cameraController = controller;
        _isInitialized = true;
        _cameraError = null;
      });
    } on CameraException catch (exception) {
      try {
        await controller.dispose();
      } catch (e) {
        debugPrint('Error disposing camera controller after exception: $e');
      }
      if (!mounted) return;
      setState(() {
        _cameraError = exception.description ?? exception.code;
        _isInitialized = false;
      });
    } catch (error) {
      try {
        await controller.dispose();
      } catch (e) {
        debugPrint('Error disposing camera controller after error: $e');
      }
      if (!mounted) return;
      setState(() {
        _cameraError = error.toString();
        _isInitialized = false;
      });
    }
  }

  FlashMode _nextFlashMode(FlashMode current) {
    // On some Android devices, always/torch flash modes cause CameraX hangs
    // or ANR conditions. Use only the safer off <-> auto cycle.
    switch (current) {
      case FlashMode.off:
        return FlashMode.auto;
      case FlashMode.auto:
      case FlashMode.always:
      case FlashMode.torch:
        return FlashMode.off;
    }
  }

  Color _flashIconColor() {
    switch (_flashMode) {
      case FlashMode.off:
        return Colors.white;
      case FlashMode.auto:
      case FlashMode.always:
      case FlashMode.torch:
        return const Color(0xFFFFC107).withValues(alpha: 0.65);
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || _isFrontCamera) {
      if (_isFrontCamera && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash tidak tersedia pada kamera depan'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Prevent changing flash while capturing or switching camera —
    // toggling flash during these operations can destabilize the controller.
    if (_isTakingPicture || _isSwitchingCamera) {
      return;
    }
    final nextMode = _nextFlashMode(_flashMode);
    try {
      await _cameraController!.setFlashMode(nextMode);
      if (!mounted) return;
      setState(() {
        _flashMode = nextMode;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash tidak tersedia pada kamera ini'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 ||
        _isSwitchingCamera ||
        _isTakingPicture ||
        _cameraController == null) {
      return;
    }

    _isSwitchingCamera = true;
    try {
      _selectedCameraIndex = _nextCameraIndex();
      await _createCameraController(_cameras[_selectedCameraIndex]);
    } finally {
      if (mounted) {
        setState(() => _isSwitchingCamera = false);
      }
    }
  }

  Future<void> _openConfirmScreen(String imagePath) async {
    final controller = _cameraController;
    if (controller != null) {
      _cameraController = null;
      setState(() => _isInitialized = false);
      try {
        await controller.pausePreview();
      } catch (_) {
        // ignore if preview is already paused
      }
      try {
        await controller.dispose();
      } catch (e) {
        debugPrint('Error disposing camera controller in openConfirmScreen: $e');
      }
    }

    if (!mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ConfirmScreen(imagePath: imagePath)),
    );

    if (!mounted || _disposed) return;
    if (_cameras.isNotEmpty) {
      await _createCameraController(_cameras[_selectedCameraIndex]);
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_cameraController!.value.isTakingPicture || _isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final picture = await _cameraController!.takePicture();
      if (!mounted) return;
      await _openConfirmScreen(picture.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengambil foto'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isTakingPicture) return;

    setState(() => _isTakingPicture = true);

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (!mounted || image == null) return;

      await _openConfirmScreen(image.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka galeri'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  }

  Widget _buildCameraPreview() {
    if (_cameraError != null) {
      return Center(
        child: Text(
          _cameraError!,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!_isInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFC107)),
      );
    }

    Widget preview = CameraPreview(_cameraController!);
    if (_isFrontCamera) {
      preview = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: preview,
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 1,
          height: _cameraController!.value.previewSize?.width ?? 1,
          child: preview,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF111111).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap:
                      (_cameraController == null ||
                          _isFrontCamera ||
                          _isTakingPicture ||
                          _isSwitchingCamera)
                      ? null
                      : _toggleFlash,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/icon/cameralightning_icon.png',
                      width: 24,
                      height: 24,
                      color:
                          (_cameraController == null ||
                              _isFrontCamera ||
                              _isTakingPicture ||
                              _isSwitchingCamera)
                          ? Colors.white38
                          : _flashIconColor(),
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _isSwitchingCamera ? null : _switchCamera,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/icon/camerarotate_icon.png',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFF111111).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Container(height: 1.5, color: const Color(0xFFFFC107)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _pickFromGallery,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/icon/cameramedia_icon.png',
                                    width: 24,
                                    height: 24,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Media',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 120),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/icon/outline_return.png',
                                    width: 24,
                                    height: 24,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Return',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -34,
            child: GestureDetector(
              onTap: _isTakingPicture ? null : _takePicture,
              child: Opacity(
                opacity: _isTakingPicture ? 0.6 : 1,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFC107),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isTakingPicture
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : Image.asset(
                            'assets/icon/camerabutton.png',
                            width: 34,
                            height: 34,
                            color: Colors.black,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildCameraPreview()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(bottom: false, child: _buildTopBar()),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(top: false, child: _buildBottomBar()),
          ),
        ],
      ),
    );
  }
}
