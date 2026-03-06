import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/liveness_detection_service.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';
import 'package:sumple1/core/utils/logger.dart';

/// Liveness Detection 全画面ページ
/// 3チャレンジ完了後、ベストフレームを [context.pop(Uint8List)] で返却
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

  late List<LivenessChallenge> _challenges;
  int _currentChallengeIndex = 0;
  final List<bool> _completedChallenges = [false, false, false];

  Timer? _stepTimer;
  Timer? _globalTimer;
  int _stepTimeLeft = 10;
  bool _timedOut = false;
  bool _allCompleted = false;

  @override
  void initState() {
    super.initState();
    _livenessService = LivenessDetectionService();
    _challenges = _livenessService.generateChallenges();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) Navigator.pop(context);
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
        _startTimers();
      }
    } catch (e) {
      Logger.error('カメラ初期化に失敗', tag: 'LivenessDetection', error: e);
      if (mounted) Navigator.pop(context);
    }
  }

  void _startTimers() {
    // 各ステップ10秒
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

    // 全体30秒タイムアウト
    _globalTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && !_allCompleted) {
        _onTimeout();
      }
    });
  }

  void _onTimeout() {
    if (_allCompleted) return;
    setState(() => _timedOut = true);
    _stopProcessing();
  }

  void _startProcessing(CameraDescription camera) {
    _cameraController?.startImageStream((cameraImage) async {
      if (_isProcessing || _allCompleted || _timedOut) return;
      _isProcessing = true;

      try {
        final inputImage = _livenessService.convertCameraImage(cameraImage, camera);
        if (inputImage == null) {
          _isProcessing = false;
          return;
        }

        final result = await _livenessService.processFrame(
          inputImage,
          _challenges[_currentChallengeIndex],
        );

        if (!mounted) return;

        // ベストフレーム候補の更新
        if (result.faceDetected && result.frameScore > 0.6) {
          try {
            final xFile = await _cameraController?.takePicture();
            if (xFile != null) {
              final bytes = await xFile.readAsBytes();
              _livenessService.updateBestFrame(result.frameScore, bytes);
            }
          } catch (_) {
            // takePicture中にストリームが続く場合のエラーは無視
          }
        }

        if (result.challengeCompleted) {
          _onChallengeCompleted();
        }

        // UIメッセージ更新
        if (result.message != null && mounted) {
          setState(() {}); // メッセージ表示のためにリビルド
        }
      } catch (e) {
        Logger.warning('フレーム処理エラー', tag: 'LivenessDetection');
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _onChallengeCompleted() {
    if (!mounted) return;

    AppHaptics.success();
    setState(() {
      _completedChallenges[_currentChallengeIndex] = true;
    });

    if (_currentChallengeIndex < 2) {
      // 次のチャレンジへ
      _stepTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _currentChallengeIndex++;
          _stepTimeLeft = 10;
          _livenessService.resetBlinkState();
        });
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
      });
    } else {
      // 全チャレンジ完了
      _allCompleted = true;
      _stepTimer?.cancel();
      _globalTimer?.cancel();
      _stopProcessing();
      _returnBestFrame();
    }
  }

  Future<void> _returnBestFrame() async {
    // ベストフレームがない場合は最後に1枚撮影
    Uint8List? bestFrame = _livenessService.getBestFrame();
    if (bestFrame == null && _cameraController != null) {
      try {
        final xFile = await _cameraController!.takePicture();
        bestFrame = await xFile.readAsBytes();
      } catch (e) {
        Logger.warning('最終フレーム撮影に失敗', tag: 'LivenessDetection');
      }
    }

    if (bestFrame != null) {
      // 圧縮
      try {
        final image = img.decodeImage(bestFrame);
        if (image != null) {
          final resized = image.width > 1080
              ? img.copyResize(image, width: 1080)
              : image;
          bestFrame = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
        }
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.pop(context, bestFrame);
    }
  }

  void _stopProcessing() {
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
  }

  void _retry() {
    setState(() {
      _timedOut = false;
      _currentChallengeIndex = 0;
      _completedChallenges.fillRange(0, 3, false);
      _stepTimeLeft = 10;
      _allCompleted = false;
    });
    _livenessService.reset();
    _challenges = _livenessService.generateChallenges();

    if (_cameraController != null) {
      final camera = _cameraController!.description;
      _startProcessing(camera);
      _startTimers();
    }
  }

  String _getChallengeText(LivenessChallenge challenge) {
    switch (challenge) {
      case LivenessChallenge.turnRight:
        return context.l10n.liveness_turnRight;
      case LivenessChallenge.turnLeft:
        return context.l10n.liveness_turnLeft;
      case LivenessChallenge.blink:
        return context.l10n.liveness_blink;
    }
  }

  IconData _getChallengeIcon(LivenessChallenge challenge) {
    switch (challenge) {
      case LivenessChallenge.turnRight:
        return Icons.turn_right;
      case LivenessChallenge.turnLeft:
        return Icons.turn_left;
      case LivenessChallenge.blink:
        return Icons.visibility;
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _globalTimer?.cancel();
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
              : _allCompleted
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
          painter: _FaceGuidePainter(),
          size: Size.infinite,
        ),
        // 上部：タイトルと進捗
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
              const SizedBox(height: 12),
              // 進捗ドット
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final isCompleted = _completedChallenges[i];
                  final isCurrent = i == _currentChallengeIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.green
                          : isCurrent
                              ? Colors.white
                              : Colors.white30,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 8, color: Colors.white)
                        : null,
                  );
                }),
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
              // チャレンジアイコンとテキスト
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
                    Icon(
                      _getChallengeIcon(_challenges[_currentChallengeIndex]),
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _getChallengeText(_challenges[_currentChallengeIndex]),
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
            onPressed: () => Navigator.pop(context),
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
                onPressed: () => Navigator.pop(context),
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
