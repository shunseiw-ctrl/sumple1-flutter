import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/referral_model.dart';

void main() {
  group('ReferralModel', () {
    final testDate = DateTime(2026, 3, 1, 10, 0, 0);

    test('コンストラクタで正しく生成される', () {
      final model = ReferralModel(
        code: 'ABC123',
        referrerUid: 'user-001',
        refereeUid: 'user-002',
        status: 'pending',
        rewardGranted: false,
        createdAt: testDate,
      );

      expect(model.code, 'ABC123');
      expect(model.referrerUid, 'user-001');
      expect(model.refereeUid, 'user-002');
      expect(model.status, 'pending');
      expect(model.rewardGranted, isFalse);
      expect(model.createdAt, testDate);
    });

    test('toMap で正しいマップが生成される', () {
      final model = ReferralModel(
        code: 'XYZ789',
        referrerUid: 'user-001',
        refereeUid: 'user-002',
        status: 'completed',
        rewardGranted: true,
        createdAt: testDate,
      );

      final map = model.toMap();

      expect(map['code'], 'XYZ789');
      expect(map['referrerUid'], 'user-001');
      expect(map['refereeUid'], 'user-002');
      expect(map['status'], 'completed');
      expect(map['rewardGranted'], isTrue);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap でモデルが正しく復元される', () {
      final map = {
        'code': 'DEF456',
        'referrerUid': 'user-A',
        'refereeUid': 'user-B',
        'status': 'completed',
        'rewardGranted': true,
        'createdAt': Timestamp.fromDate(testDate),
      };

      final model = ReferralModel.fromMap(map);

      expect(model.code, 'DEF456');
      expect(model.referrerUid, 'user-A');
      expect(model.refereeUid, 'user-B');
      expect(model.status, 'completed');
      expect(model.rewardGranted, isTrue);
      expect(model.createdAt, testDate);
    });

    test('equality が正しく動作する', () {
      final a = ReferralModel(
        code: 'ABC123',
        referrerUid: 'user-001',
        refereeUid: 'user-002',
        status: 'pending',
        rewardGranted: false,
        createdAt: testDate,
      );

      final b = ReferralModel(
        code: 'ABC123',
        referrerUid: 'user-001',
        refereeUid: 'user-002',
        status: 'pending',
        rewardGranted: false,
        createdAt: testDate,
      );

      final c = ReferralModel(
        code: 'DIFF00',
        referrerUid: 'user-001',
        refereeUid: 'user-002',
        status: 'pending',
        rewardGranted: false,
        createdAt: testDate,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
