import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sumple1/core/utils/logger.dart';

/// Liveness チャレンジの種類
enum LivenessChallenge { turnRight, turnLeft, blink }

/// Liveness チャレンジの判定結果
class LivenessChallengeResult {
  final LivenessChallenge challenge;
  final bool completed;

  const LivenessChallengeResult({
    required this.challenge,
    this.completed = false,
  });
}

/// ベストフレームのスコアリング結果
class FrameScore {
  final double score;
  final Uint8List? imageBytes;

  const FrameScore({required this.score, this.imageBytes});
}

/// ML Kit ベースの Liveness Detection サービス
class LivenessDetectionService {
  final FaceDetector _faceDetector;
  final Random _random = Random();

  // まばたき検出用の状態
  bool _eyesWereOpen = true;

  // ベストフレーム
  double _bestScore = -1;
  Uint8List? _bestFrame;

  LivenessDetectionService({FaceDetector? faceDetector})
      : _faceDetector = faceDetector ??
            FaceDetector(
              options: FaceDetectorOptions(
                enableClassification: true,
                enableTracking: true,
                performanceMode: FaceDetectorMode.fast,
              ),
            );

  /// 3つのチャレンジをランダム順で生成
  List<LivenessChallenge> generateChallenges() {
    final challenges = [
      LivenessChallenge.turnRight,
      LivenessChallenge.turnLeft,
      LivenessChallenge.blink,
    ];
    challenges.shuffle(_random);
    return challenges;
  }

  /// CameraImage を InputImage に変換
  InputImage? convertCameraImage(CameraImage cameraImage, CameraDescription camera) {
    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
    if (format == null) return null;

    // iOS: bgra8888, Android: nv21
    final planes = cameraImage.planes;
    if (planes.isEmpty) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation rotation;
    switch (sensorOrientation) {
      case 0:
        rotation = InputImageRotation.rotation0deg;
        break;
      case 90:
        rotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        rotation = InputImageRotation.rotation180deg;
        break;
      case 270:
        rotation = InputImageRotation.rotation270deg;
        break;
      default:
        rotation = InputImageRotation.rotation0deg;
    }

    return InputImage.fromBytes(
      bytes: planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(
          cameraImage.width.toDouble(),
          cameraImage.height.toDouble(),
        ),
        rotation: rotation,
        format: format,
        bytesPerRow: planes.first.bytesPerRow,
      ),
    );
  }

  /// フレームを処理してチャレンジ判定
  Future<LivenessFrameResult> processFrame(
    InputImage inputImage,
    LivenessChallenge currentChallenge,
  ) async {
    try {
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return LivenessFrameResult(
          faceDetected: false,
          challengeCompleted: false,
          message: 'no_face',
        );
      }

      if (faces.length > 1) {
        return LivenessFrameResult(
          faceDetected: true,
          challengeCompleted: false,
          message: 'multiple_faces',
        );
      }

      final face = faces.first;
      final headY = face.headEulerAngleY ?? 0;
      final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
      final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;

      // チャレンジ判定
      bool completed = false;
      switch (currentChallenge) {
        case LivenessChallenge.turnRight:
          completed = headY < -20;
          break;
        case LivenessChallenge.turnLeft:
          completed = headY > 20;
          break;
        case LivenessChallenge.blink:
          final eyesClosed = leftEyeOpen < 0.3 && rightEyeOpen < 0.3;
          if (_eyesWereOpen && eyesClosed) {
            completed = true;
          }
          _eyesWereOpen = leftEyeOpen > 0.5 && rightEyeOpen > 0.5;
          break;
      }

      // ベストフレーム候補スコア計算（正面度 × 目の開き度）
      final frontalScore = 1.0 - (headY.abs() / 45.0).clamp(0.0, 1.0);
      final eyeScore = ((leftEyeOpen + rightEyeOpen) / 2.0).clamp(0.0, 1.0);
      final totalScore = frontalScore * 0.5 + eyeScore * 0.5;

      return LivenessFrameResult(
        faceDetected: true,
        challengeCompleted: completed,
        frameScore: totalScore,
      );
    } catch (e) {
      Logger.error('フレーム処理に失敗', tag: 'LivenessDetection', error: e);
      return LivenessFrameResult(
        faceDetected: false,
        challengeCompleted: false,
        message: 'error',
      );
    }
  }

  /// ベストフレームを更新
  void updateBestFrame(double score, Uint8List imageBytes) {
    if (score > _bestScore) {
      _bestScore = score;
      _bestFrame = imageBytes;
    }
  }

  /// ベストフレームを取得
  Uint8List? getBestFrame() => _bestFrame;

  /// まばたき状態をリセット
  void resetBlinkState() {
    _eyesWereOpen = true;
  }

  /// 全状態をリセット
  void reset() {
    _eyesWereOpen = true;
    _bestScore = -1;
    _bestFrame = null;
  }

  /// リソースを解放
  void dispose() {
    _faceDetector.close();
  }
}

/// フレーム処理結果
class LivenessFrameResult {
  final bool faceDetected;
  final bool challengeCompleted;
  final double frameScore;
  final String? message;

  const LivenessFrameResult({
    required this.faceDetected,
    required this.challengeCompleted,
    this.frameScore = 0,
    this.message,
  });
}
