import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:sumple1/core/services/ekyc_manual_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late ManualEkycService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'admin1'),
    );
    service = ManualEkycService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('ManualEkycService extended', () {
    test('approveVerification updates status and profile', () async {
      await fakeFirestore.collection('identity_verification').doc('user1').set({
        'uid': 'user1',
        'idPhotoUrl': 'https://example.com/id.jpg',
        'selfieUrl': 'https://example.com/selfie.jpg',
        'status': 'pending',
      });
      await fakeFirestore.collection('profiles').doc('user1').set({
        'displayName': 'Test User',
      });

      await service.approveVerification('user1', 'admin1');

      final verifyDoc = await fakeFirestore.collection('identity_verification').doc('user1').get();
      expect(verifyDoc.data()?['status'], 'approved');
      expect(verifyDoc.data()?['reviewedBy'], 'admin1');

      final profileDoc = await fakeFirestore.collection('profiles').doc('user1').get();
      expect(profileDoc.data()?['identityVerified'], true);
    });

    test('rejectVerification sets reason', () async {
      await fakeFirestore.collection('identity_verification').doc('user1').set({
        'uid': 'user1',
        'idPhotoUrl': 'https://example.com/id.jpg',
        'selfieUrl': 'https://example.com/selfie.jpg',
        'status': 'pending',
      });

      await service.rejectVerification('user1', 'admin1', '写真が不鮮明です');

      final doc = await fakeFirestore.collection('identity_verification').doc('user1').get();
      expect(doc.data()?['status'], 'rejected');
      expect(doc.data()?['rejectionReason'], '写真が不鮮明です');
      expect(doc.data()?['reviewedBy'], 'admin1');
    });

    test('resubmitVerification resets to pending', () async {
      await fakeFirestore.collection('identity_verification').doc('user1').set({
        'uid': 'user1',
        'idPhotoUrl': 'https://example.com/old.jpg',
        'selfieUrl': 'https://example.com/old_selfie.jpg',
        'status': 'rejected',
        'rejectionReason': 'blurry',
      });

      await service.resubmitVerification(
        'user1',
        'https://example.com/new.jpg',
        'https://example.com/new_selfie.jpg',
        'passport',
      );

      final doc = await fakeFirestore.collection('identity_verification').doc('user1').get();
      expect(doc.data()?['status'], 'pending');
      expect(doc.data()?['idPhotoUrl'], 'https://example.com/new.jpg');
      expect(doc.data()?['documentType'], 'passport');
    });

    test('getPendingVerifications returns pending items', () async {
      await fakeFirestore.collection('identity_verification').doc('user1').set({
        'uid': 'user1',
        'idPhotoUrl': 'https://example.com/id.jpg',
        'selfieUrl': 'https://example.com/selfie.jpg',
        'status': 'pending',
        'submittedAt': DateTime(2025, 1, 1),
      });
      await fakeFirestore.collection('identity_verification').doc('user2').set({
        'uid': 'user2',
        'idPhotoUrl': 'https://example.com/id2.jpg',
        'selfieUrl': 'https://example.com/selfie2.jpg',
        'status': 'approved',
        'submittedAt': DateTime(2025, 1, 2),
      });

      final stream = service.getPendingVerifications();
      final list = await stream.first;
      expect(list.length, 1);
      expect(list.first.uid, 'user1');
    });
  });
}
