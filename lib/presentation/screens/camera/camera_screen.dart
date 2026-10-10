import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/ocr/ocr_service.dart';
import '../../../presentation/providers/expense_providers.dart';
import '../review/review_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _flashEnabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No cameras found');
        return;
      }

      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    setState(() => _flashEnabled = !_flashEnabled);
    await _controller!.setFlashMode(
      _flashEnabled ? FlashMode.torch : FlashMode.off,
    );
  }

  Future<void> _handleTapToFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_controller == null) return;
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    try {
      await _controller!.setFocusPoint(offset);
      await _controller!.setExposurePoint(offset);
    } catch (_) {}
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || _isCapturing) return;
    setState(() => _isCapturing = true);

    // Haptic feedback
    HapticFeedback.mediumImpact();

    try {
      final xFile = await _controller!.takePicture();
      if (!mounted) return;

      ref.read(ocrProvider.notifier).setProcessing(true);

      final parsedData = await OcrService.instance.processImage(xFile);
      ref.read(ocrProvider.notifier).setParsedData(xFile.path, parsedData);

      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewScreen(imagePath: xFile.path),
          ),
        );
      }
    } catch (e) {
      ref.read(ocrProvider.notifier).setError(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // ─── Camera Preview ───────────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: (details) =>
                  _handleTapToFocus(details, constraints),
              child: CameraPreview(_controller!),
            );
          },
        ),

        // ─── Crop Overlay Frame ───────────────────────────────────────────
        const _CropOverlayFrame(),

        // ─── Top Controls ─────────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircularButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const Text(
                  'Scan Receipt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _CircularButton(
                  icon: _flashEnabled ? Icons.flash_on : Icons.flash_off,
                  activeColor: _flashEnabled ? AppColors.warning : null,
                  onTap: _toggleFlash,
                ),
              ],
            ),
          ),
        ),

        // ─── Bottom Controls ──────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomControls(
            isCapturing: _isCapturing,
            onCapture: _captureAndProcess,
            onGallery: _pickFromGallery,
          ),
        ),
      ],
    );
  }

  Future<void> _pickFromGallery() async {
    // Use image_picker to pick from gallery
    try {
      // Implementing via image_picker
      final imagePicker = await _showGalleryPicker();
      if (imagePicker == null) return;

      ref.read(ocrProvider.notifier).setProcessing(true);
      final imageFile = XFile(imagePicker);
      final parsedData = await OcrService.instance.processImage(imageFile);
      ref.read(ocrProvider.notifier).setParsedData(imagePicker, parsedData);

      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewScreen(imagePath: imagePicker),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<String?> _showGalleryPicker() async {
    // Use image_picker package
    try {
      final picker = await _pickImage();
      return picker;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    return xFile?.path;
  }
}

// ─── Crop Overlay Frame (CustomPainter) ───────────────────────────────────────

class _CropOverlayFrame extends StatelessWidget {
  const _CropOverlayFrame();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _OverlayPainter());
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dim overlay
    final dimPaint = Paint()..color = Colors.black.withAlpha(100);

    final frameW = w * 0.88;
    final frameH = h * 0.40;
    final frameLeft = (w - frameW) / 2;
    final frameTop = (h - frameH) / 2 - 20;

    final frameRect = Rect.fromLTWH(frameLeft, frameTop, frameW, frameH);
    final frameRRect = RRect.fromRectAndRadius(frameRect, const Radius.circular(16));

    // Punch hole through dim
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, w, h))
      ..addRRect(frameRRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    // Corner brackets
    const cornerLen = 28.0;
    const cornerThick = 3.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = cornerThick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final corners = [
      // Top-left
      [frameLeft, frameTop + cornerLen, frameLeft, frameTop, frameLeft + cornerLen, frameTop],
      // Top-right
      [frameLeft + frameW - cornerLen, frameTop, frameLeft + frameW, frameTop, frameLeft + frameW, frameTop + cornerLen],
      // Bottom-left
      [frameLeft, frameTop + frameH - cornerLen, frameLeft, frameTop + frameH, frameLeft + cornerLen, frameTop + frameH],
      // Bottom-right
      [frameLeft + frameW - cornerLen, frameTop + frameH, frameLeft + frameW, frameTop + frameH, frameLeft + frameW, frameTop + frameH - cornerLen],
    ];

    for (final c in corners) {
      final path = Path()
        ..moveTo(c[0], c[1])
        ..lineTo(c[2], c[3])
        ..lineTo(c[4], c[5]);
      canvas.drawPath(path, cornerPaint);
    }

    // Animated scan line hint text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Align receipt within frame',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: w);
    textPainter.paint(
      canvas,
      Offset((w - textPainter.width) / 2, frameTop + frameH + 16),
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) => false;
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? activeColor;

  const _CircularButton({
    required this.icon,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: activeColor ?? Colors.white, size: 22),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final bool isCapturing;
  final VoidCallback onCapture;
  final VoidCallback onGallery;

  const _BottomControls({
    required this.isCapturing,
    required this.onCapture,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withAlpha(200)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          GestureDetector(
            onTap: onGallery,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.photo_library, color: Colors.white),
            ),
          ),

          // Capture button
          GestureDetector(
            onTap: isCapturing ? null : onCapture,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isCapturing ? 72 : 76,
              height: isCapturing ? 72 : 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCapturing ? AppColors.backgroundCard : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(120),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: isCapturing
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primary,
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),

          // Placeholder spacer
          const SizedBox(width: 50),
        ],
      ),
    );
  }
}
