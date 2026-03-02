import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/force_update_service.dart';

void main() {
  group('ForceUpdateService', () {
    group('isLessThan', () {
      test('1.0.0 < 1.1.0 is true', () {
        expect(ForceUpdateService.isLessThan('1.0.0', '1.1.0'), isTrue);
      });

      test('1.2.0 > 1.1.9 is false', () {
        expect(ForceUpdateService.isLessThan('1.2.0', '1.1.9'), isFalse);
      });

      test('1.0.0 = 1.0.0 is false', () {
        expect(ForceUpdateService.isLessThan('1.0.0', '1.0.0'), isFalse);
      });

      test('0.9.9 < 1.0.0 is true', () {
        expect(ForceUpdateService.isLessThan('0.9.9', '1.0.0'), isTrue);
      });

      test('2.0.0 > 1.9.9 is false', () {
        expect(ForceUpdateService.isLessThan('2.0.0', '1.9.9'), isFalse);
      });
    });

    group('checkForUpdate (with fake Firestore)', () {
      test('returns upToDate when document does not exist', () async {
        final db = FakeFirebaseFirestore();
        final service = ForceUpdateService(db: db);

        final result = await service.checkForUpdate();
        expect(result, ForceUpdateResult.upToDate);
      });
    });
  });
}
