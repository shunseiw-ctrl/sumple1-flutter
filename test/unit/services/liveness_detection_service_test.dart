import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/liveness_detection_service.dart';

void main() {
  group('LivenessDetectionService', () {
    // FaceDetectorはネイティブプラットフォームに依存するため、
    // dispose()を呼ばずにロジックのみテスト

    test('generateChallenges returns 3 challenges', () {
      final service = LivenessDetectionService();
      final challenges = service.generateChallenges();

      expect(challenges.length, 3);
      expect(challenges.contains(LivenessChallenge.turnRight), true);
      expect(challenges.contains(LivenessChallenge.turnLeft), true);
      expect(challenges.contains(LivenessChallenge.blink), true);
    });

    test('generateChallenges shuffles order', () {
      final service = LivenessDetectionService();
      // 複数回生成して、少なくとも1回は異なる順序であることを確認
      final orders = <String>[];
      for (int i = 0; i < 20; i++) {
        final challenges = service.generateChallenges();
        orders.add(challenges.map((c) => c.name).join(','));
      }
      // 20回中すべて同じ順序は極めて低確率
      final uniqueOrders = orders.toSet();
      expect(uniqueOrders.length, greaterThan(1));
    });

    test('updateBestFrame keeps highest score', () {
      final service = LivenessDetectionService();
      final bytes1 = Uint8List.fromList([1, 2, 3]);
      final bytes2 = Uint8List.fromList([4, 5, 6]);
      final bytes3 = Uint8List.fromList([7, 8, 9]);

      service.updateBestFrame(0.5, bytes1);
      expect(service.getBestFrame(), bytes1);

      service.updateBestFrame(0.8, bytes2);
      expect(service.getBestFrame(), bytes2);

      // 低スコアは無視
      service.updateBestFrame(0.3, bytes3);
      expect(service.getBestFrame(), bytes2);
    });

    test('reset clears best frame and state', () {
      final service = LivenessDetectionService();
      final bytes = Uint8List.fromList([1, 2, 3]);

      service.updateBestFrame(0.9, bytes);
      expect(service.getBestFrame(), isNotNull);

      service.reset();
      expect(service.getBestFrame(), isNull);
    });
  });

  group('LivenessFrameResult', () {
    test('creates with correct defaults', () {
      const result = LivenessFrameResult(
        faceDetected: true,
        challengeCompleted: false,
      );

      expect(result.faceDetected, true);
      expect(result.challengeCompleted, false);
      expect(result.frameScore, 0);
      expect(result.message, isNull);
    });

    test('creates with custom values', () {
      const result = LivenessFrameResult(
        faceDetected: false,
        challengeCompleted: false,
        frameScore: 0.75,
        message: 'no_face',
      );

      expect(result.faceDetected, false);
      expect(result.frameScore, 0.75);
      expect(result.message, 'no_face');
    });
  });

  group('LivenessChallengeResult', () {
    test('creates with correct values', () {
      const result = LivenessChallengeResult(
        challenge: LivenessChallenge.blink,
        completed: true,
      );

      expect(result.challenge, LivenessChallenge.blink);
      expect(result.completed, true);
    });

    test('default completed is false', () {
      const result = LivenessChallengeResult(
        challenge: LivenessChallenge.turnRight,
      );

      expect(result.completed, false);
    });
  });
}
