import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/liveness_detection_service.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';
import 'package:sumple1/core/utils/logger.dart';

/// Liveness Detection 全画面ページ
/// まばたき検出完了後、ベストフレームを [context.pop(Uint8List)] で返却
class LivenessDetectionPage extends StatefulWidget {
  const LivenessDetectionPage({super.key});

  @override
  State<LivenessDetectionPage> createState() => _LivenessDetectionPageState();
}

class _LivenessDetectionPageState extends State<LivenessDetectionPage> {
  CameraController? _cameraController;
  late LivenessDetectionService _livenessService;
  bool _isInitialized = false;
  bool _isProcessing = false;

  Timer? _stepTimer;
  int _stepTimeLeft = 15;
  bool _timedOut = false;
  bool _completed = false;

  static const _faceGuidePainter = _FaceGuidePainter();

  @override
  void initState() {
    super.initState();
    _livenessService = LivenessDetectionService();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) context.pop();
        return;
      }

      // フロントカメラ
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _startProcessing(frontCamera);
        _startTimer();
      }
    } catch (e) {
      Logger.error('カメラ初期化に失敗', tag: 'LivenessDetection', error: e);
      if (mounted) context.pop();
    }
  }

  void _startTimer() {
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _stepTimeLeft--);
      if (_stepTimeLeft <= 0) {
        timer.cancel();
        _onTimeout();
      }
    });
  }

  void _onTimeout() {
    if (_completed) return;
    setState(() => _timedOut = true);
    _stopProcessing();
  }

  void _startProcessing(CameraDescription camera) {
    _cameraController?.startImageStream((cameraImage) async {
      if (_isProcessing || _completed || _timedOut) return;
      _isProcessing = true;

      try {
        final inputImage = _livenessService.convertCameraImage(cameraImage, camera);
        if (inputImage == null) {
          _isProcessing = false;
          return;
        }

        final result = await _livenessService.processFrame(
          inputImage,
          LivenessChallenge.blink,
        );

        if (!mounted) return;

        if (result.challengeCompleted) {
          _onChallengeCompleted();
        }
      } catch (e) {
        Logger.warning('フレーム処理エラー', tag: 'LivenessDetection');
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _onChallengeCompleted() async {
    if (!mounted || _completed) return;

    AppHaptics.success();
    setState(() => _completed = true);
    _stepTimer?.cancel();

    // ストリームを停止してからtakePictureを呼ぶ
    await _stopProcessing();
    // ストリーム完全停止を待つ
    await Future.delayed(const Duration(milliseconds: 500));

    await _returnBestFrame();
  }

  Future<void> _returnBestFrame() async {
    Uint8List? bestFrame;

    // ストリーム停止後に1枚撮影
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final xFile = await _cameraController!.takePicture();
        bestFrame = await xFile.readAsBytes();
        Logger.info('自撮り撮影成功', tag: 'LivenessDetection',
            data: {'size': '${(bestFrame.length / 1024).toStringAsFixed(0)} KB'});
      } catch (e) {
        Logger.warning('自撮り撮影に失敗', tag: 'LivenessDetection', data: {'error': '$e'});
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      context.pop(bestFrame);
    }
  }

  Future<void> _stopProcessing() async {
    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}
  }

  Future<void> _retry() async {
    _stepTimer?.cancel();
    setState(() {
      _timedOut = false;
      _stepTimeLeft = 15;
      _completed = false;
    });
    _livenessService.reset();

    if (_cameraController != null) {
      final camera = _cameraController!.description;
      _startProcessing(camera);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _livenessService.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _timedOut
              ? _buildTimeoutScreen()
              : _completed
                  ? _buildCompletedScreen()
                  : _buildCameraScreen(),
    );
  }

  Widget _buildCameraScreen() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // カメラプレビュー
        Center(child: CameraPreview(_cameraController!)),
        // 楕円形の顔ガイド
        CustomPaint(
          painter: _faceGuidePainter,
          size: Size.infinite,
        ),
        // 上部：タイトル
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                context.l10n.liveness_title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // 下部：チャレンジ指示
        Positioned(
          bottom: 60,
          left: 24,
          right: 24,
          child: Column(
            children: [
              // タイマー
              Text(
                '$_stepTimeLeft',
                style: TextStyle(
                  color: _stepTimeLeft <= 3 ? Colors.red : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              // チャレンジテキスト
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        context.l10n.liveness_blink,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 閉じるボタン
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          Text(
            context.l10n.liveness_completed,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutScreen() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_off, color: Colors.orange, size: 64),
              const SizedBox(height: 16),
              Text(
                context.l10n.liveness_timeout,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.common_retry),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  context.l10n.common_cancel,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 楕円形の顔ガイド描画
class _FaceGuidePainter extends CustomPainter {
  const _FaceGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black54;
    final ovalWidth = size.width * 0.65;
    final ovalHeight = ovalWidth * 1.3;
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 30),
      width: ovalWidth,
      height: ovalHeight,
    );

    // 背景をくり抜き
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bgPaint);

    // 楕円の枠線
    final borderPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
