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
  });
}
