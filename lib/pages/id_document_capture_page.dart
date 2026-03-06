import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/image_upload_service.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';
import 'package:sumple1/core/utils/logger.dart';

/// 身分証カメラ撮影ページ（ガイド枠付き）
/// [side] で表面('front')・裏面('back')を切り替え
class IdDocumentCapturePage extends StatefulWidget {
  final String side;

  const IdDocumentCapturePage({super.key, required this.side});

  @override
  State<IdDocumentCapturePage> createState() => _IdDocumentCapturePageState();
}

class _IdDocumentCapturePageState extends State<IdDocumentCapturePage> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;

  static const _cardGuidePainter = _CardGuidePainter();
  bool get _isFront => widget.side == 'front';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.idCapture_noCameraAvailable)),
          );
          context.pop();
        }
        return;
      }

      // バックカメラを使用（身分証撮影）
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      Logger.error('カメラ初期化に失敗', tag: 'IdDocumentCapture', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.idCapture_cameraInitFailed)),
        );
        context.pop();
      }
    }
  }

  Future<void> _capture() async {
    if (_isCapturing || _controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isCapturing = true);

    try {
      final xFile = await _controller!.takePicture();
      final bytes = await xFile.readAsBytes();

      // 1MB以下に圧縮
      final compressed = ImageUploadService.compressImageBytes(
        bytes,
        maxSizeBytes: 1024 * 1024,
      );

      AppHaptics.success();
      if (mounted) {
        context.pop(compressed);
      }
    } catch (e) {
      Logger.error('撮影に失敗', tag: 'IdDocumentCapture', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.idCapture_captureFailed)),
        );
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(context.l10n.idCapture_title),
        elevation: 0,
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              fit: StackFit.expand,
              children: [
                // カメラプレビュー
                Center(child: CameraPreview(_controller!)),
                // ガイドオーバーレイ
                CustomPaint(
                  painter: _cardGuidePainter,
                  size: Size.infinite,
                ),
                // 指示テキスト
                Positioned(
                  top: 16,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isFront
                          ? context.l10n.idCapture_instruction
                          : context.l10n.idCapture_backInstruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // シャッターボタン
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isCapturing ? null : _capture,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: _isCapturing ? Colors.grey : Colors.white24,
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// カードガイド枠描画（ISO CR-80比率 1.586:1）
class _CardGuidePainter extends CustomPainter {
  const _CardGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 半透明黒の背景
    final bgPaint = Paint()..color = Colors.black54;

    // カードサイズ計算（画面幅の85%）
    final cardWidth = size.width * 0.85;
    final cardHeight = cardWidth / 1.586; // ISO CR-80 アスペクト比
    final cardRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: cardWidth,
      height: cardHeight,
    );

    // 背景（カード部分をくり抜き）
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cardRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bgPaint);

    // 角マーカー
    final markerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const markerLen = 24.0;
    const r = 12.0;

    // 左上
    canvas.drawLine(
      Offset(cardRect.left, cardRect.top + r + markerLen),
      Offset(cardRect.left, cardRect.top + r),
      markerPaint,
    );
    canvas.drawLine(
      Offset(cardRect.left + r, cardRect.top),
      Offset(cardRect.left + r + markerLen, cardRect.top),
      markerPaint,
    );

    // 右上
    canvas.drawLine(
      Offset(cardRect.right, cardRect.top + r + markerLen),
      Offset(cardRect.right, cardRect.top + r),
      markerPaint,
    );
    canvas.drawLine(
      Offset(cardRect.right - r, cardRect.top),
      Offset(cardRect.right - r - markerLen, cardRect.top),
      markerPaint,
    );

    // 左下
    canvas.drawLine(
      Offset(cardRect.left, cardRect.bottom - r - markerLen),
      Offset(cardRect.left, cardRect.bottom - r),
      markerPaint,
    );
    canvas.drawLine(
      Offset(cardRect.left + r, cardRect.bottom),
      Offset(cardRect.left + r + markerLen, cardRect.bottom),
      markerPaint,
    );

    // 右下
    canvas.drawLine(
      Offset(cardRect.right, cardRect.bottom - r - markerLen),
      Offset(cardRect.right, cardRect.bottom - r),
      markerPaint,
    );
    canvas.drawLine(
      Offset(cardRect.right - r, cardRect.bottom),
      Offset(cardRect.right - r - markerLen, cardRect.bottom),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
