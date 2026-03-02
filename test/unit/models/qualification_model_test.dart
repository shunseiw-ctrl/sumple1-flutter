import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/qualification_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('QualificationModel', () {
    test('fromMap で正しく生成される', () {
      final data = TestFixtures.qualificationData();
      final model = QualificationModel.fromMap('qual-001', data);

      expect(model.id, 'qual-001');
      expect(model.uid, 'worker-001');
      expect(model.name, '内装仕上げ施工技能士');
      expect(model.category, 'interior');
      expect(model.verificationStatus, 'pending');
    });

    test('toMap で正しく変換される', () {
      final data = TestFixtures.qualificationData(
        certPhotoUrl: 'https://example.com/cert.jpg',
        expiryDate: '2026-12-31',
      );
      final model = QualificationModel.fromMap('qual-001', data);
      final map = model.toMap();

      expect(map['uid'], 'worker-001');
      expect(map['name'], '内装仕上げ施工技能士');
      expect(map['certPhotoUrl'], 'https://example.com/cert.jpg');
      expect(map['expiryDate'], '2026-12-31');
    });

    test('isVerified / isPending が正しく動作する', () {
      final pending = QualificationModel.fromMap(
          'q1', TestFixtures.qualificationData(verificationStatus: 'pending'));
      expect(pending.isPending, isTrue);
      expect(pending.isVerified, isFalse);

      final approved = QualificationModel.fromMap(
          'q2', TestFixtures.qualificationData(verificationStatus: 'approved'));
      expect(approved.isVerified, isTrue);
      expect(approved.isPending, isFalse);
    });

    test('isExpired が正しく動作する', () {
      final notExpired = QualificationModel.fromMap(
          'q1', TestFixtures.qualificationData(expiryDate: '2099-12-31'));
      expect(notExpired.isExpired, isFalse);

      final expired = QualificationModel.fromMap(
          'q2', TestFixtures.qualificationData(expiryDate: '2020-01-01'));
      expect(expired.isExpired, isTrue);

      final noExpiry = QualificationModel.fromMap(
          'q3', TestFixtures.qualificationData());
      expect(noExpiry.isExpired, isFalse);
    });
  });
}
