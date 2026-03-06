import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/identity_verification_model.dart';

void main() {
  group('IdentityVerificationModel', () {
    test('fromMap creates correct model', () {
      final map = {
        'uid': 'user1',
        'idPhotoUrl': 'https://example.com/id.jpg',
        'selfieUrl': 'https://example.com/selfie.jpg',
        'documentType': 'drivers_license',
        'status': 'pending',
        'submittedAt': DateTime(2025, 1, 1),
      };

      final model = IdentityVerificationModel.fromMap(map);
      expect(model.uid, 'user1');
      expect(model.idPhotoUrl, 'https://example.com/id.jpg');
      expect(model.selfieUrl, 'https://example.com/selfie.jpg');
      expect(model.documentType, 'drivers_license');
      expect(model.status, 'pending');
    });

    test('toMap produces correct map', () {
      final model = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
        documentType: 'my_number',
        status: 'approved',
        reviewedBy: 'admin1',
      );

      final map = model.toMap();
      expect(map['uid'], 'user1');
      expect(map['documentType'], 'my_number');
      expect(map['status'], 'approved');
      expect(map['reviewedBy'], 'admin1');
    });

    test('equality works correctly', () {
      final a = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
      );
      final b = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
      );
      final c = IdentityVerificationModel(
        uid: 'user2',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith creates modified copy', () {
      final original = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
        status: 'pending',
      );

      final modified = original.copyWith(status: 'approved', reviewedBy: 'admin1');
      expect(modified.status, 'approved');
      expect(modified.reviewedBy, 'admin1');
      expect(modified.uid, 'user1');
      expect(original.status, 'pending');
    });

    // --- eKYC新フィールドテスト ---

    test('fromMap parses eKYC fields correctly', () {
      final map = {
        'uid': 'user1',
        'idPhotoUrl': 'https://example.com/id.jpg',
        'idPhotoBackUrl': 'https://example.com/id_back.jpg',
        'selfieUrl': 'https://example.com/selfie.jpg',
        'documentType': 'drivers_license',
        'status': 'pending',
        'faceMatchScore': 85.5,
        'livenessVerified': true,
        'livenessCompletedAt': DateTime(2025, 6, 1, 10, 30),
        'faceMatchedAt': DateTime(2025, 6, 1, 10, 31),
      };

      final model = IdentityVerificationModel.fromMap(map);
      expect(model.idPhotoBackUrl, 'https://example.com/id_back.jpg');
      expect(model.faceMatchScore, 85.5);
      expect(model.livenessVerified, true);
      expect(model.livenessCompletedAt, DateTime(2025, 6, 1, 10, 30));
      expect(model.faceMatchedAt, DateTime(2025, 6, 1, 10, 31));
    });

    test('fromMap handles missing eKYC fields with defaults', () {
      final map = {
        'uid': 'user1',
        'idPhotoUrl': 'https://example.com/id.jpg',
        'selfieUrl': 'https://example.com/selfie.jpg',
      };

      final model = IdentityVerificationModel.fromMap(map);
      expect(model.idPhotoBackUrl, isNull);
      expect(model.faceMatchScore, isNull);
      expect(model.livenessVerified, false);
      expect(model.livenessCompletedAt, isNull);
      expect(model.faceMatchedAt, isNull);
    });

    test('fromMap parses faceMatchScore from int', () {
      final map = {
        'uid': 'user1',
        'idPhotoUrl': 'https://example.com/id.jpg',
        'selfieUrl': 'https://example.com/selfie.jpg',
        'faceMatchScore': 90,
      };

      final model = IdentityVerificationModel.fromMap(map);
      expect(model.faceMatchScore, 90.0);
    });

    test('toMap includes eKYC fields', () {
      final model = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        idPhotoBackUrl: 'https://example.com/id_back.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
        faceMatchScore: 92.0,
        livenessVerified: true,
        livenessCompletedAt: DateTime(2025, 6, 1),
        faceMatchedAt: DateTime(2025, 6, 1),
      );

      final map = model.toMap();
      expect(map['idPhotoBackUrl'], 'https://example.com/id_back.jpg');
      expect(map['faceMatchScore'], 92.0);
      expect(map['livenessVerified'], true);
      expect(map['livenessCompletedAt'], isA<Timestamp>());
      expect(map['faceMatchedAt'], isA<Timestamp>());
    });

    test('toMap omits null eKYC fields', () {
      final model = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
      );

      final map = model.toMap();
      expect(map.containsKey('idPhotoBackUrl'), false);
      expect(map.containsKey('faceMatchScore'), false);
      expect(map['livenessVerified'], false);
      expect(map.containsKey('livenessCompletedAt'), false);
      expect(map.containsKey('faceMatchedAt'), false);
    });

    test('copyWith updates eKYC fields', () {
      final original = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
      );

      final modified = original.copyWith(
        idPhotoBackUrl: 'https://example.com/id_back.jpg',
        faceMatchScore: 88.0,
        livenessVerified: true,
      );

      expect(modified.idPhotoBackUrl, 'https://example.com/id_back.jpg');
      expect(modified.faceMatchScore, 88.0);
      expect(modified.livenessVerified, true);
      expect(original.idPhotoBackUrl, isNull);
      expect(original.faceMatchScore, isNull);
      expect(original.livenessVerified, false);
    });

    test('equality considers eKYC fields', () {
      final a = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
        faceMatchScore: 85.0,
        livenessVerified: true,
      );
      final b = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
        faceMatchScore: 85.0,
        livenessVerified: true,
      );
      final c = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
        faceMatchScore: 60.0,
        livenessVerified: false,
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('documentTypeLabel returns correct label', () {
      expect(
        IdentityVerificationModel(
          uid: 'u', idPhotoUrl: '', selfieUrl: '', documentType: 'drivers_license',
        ).documentTypeLabel,
        '運転免許証',
      );
      expect(
        IdentityVerificationModel(
          uid: 'u', idPhotoUrl: '', selfieUrl: '', documentType: 'passport',
        ).documentTypeLabel,
        'パスポート',
      );
      expect(
        IdentityVerificationModel(
          uid: 'u', idPhotoUrl: '', selfieUrl: '', documentType: 'unknown',
        ).documentTypeLabel,
        'unknown',
      );
    });
  });
}
