import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/face_match_service.dart';

void main() {
  group('FaceMatchResult', () {
    test('fromMap creates correct result', () {
      final map = {'score': 85.0, 'matched': true};
      final result = FaceMatchResult.fromMap(map);

      expect(result.score, 85.0);
      expect(result.matched, true);
      expect(result.error, isNull);
    });

    test('fromMap handles int score', () {
      final map = {'score': 90, 'matched': true};
      final result = FaceMatchResult.fromMap(map);

      expect(result.score, 90.0);
      expect(result.matched, true);
    });

    test('fromMap handles missing fields', () {
      final result = FaceMatchResult.fromMap({});

      expect(result.score, 0);
      expect(result.matched, false);
      expect(result.error, isNull);
    });

    test('fromMap parses error field', () {
      final map = {
        'score': 0,
        'matched': false,
        'error': 'id_face_not_found',
      };
      final result = FaceMatchResult.fromMap(map);

      expect(result.score, 0);
      expect(result.matched, false);
      expect(result.error, 'id_face_not_found');
    });

    test('failure creates error result', () {
      final result = FaceMatchResult.failure('テストエラー');

      expect(result.score, 0);
      expect(result.matched, false);
      expect(result.error, 'テストエラー');
    });

    test('high score means matched', () {
      final map = {'score': 95.0, 'matched': true};
      final result = FaceMatchResult.fromMap(map);
      expect(result.matched, true);
    });

    test('low score means not matched', () {
      final map = {'score': 40.0, 'matched': false};
      final result = FaceMatchResult.fromMap(map);
      expect(result.matched, false);
    });
  });
}
