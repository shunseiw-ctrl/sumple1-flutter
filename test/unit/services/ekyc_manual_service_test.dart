import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/ekyc_manual_service.dart';
import 'package:sumple1/data/models/ekyc_result.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('ManualEkycService', () {
    test('isAvailable returns true', () {
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'user-001'),
      );
      final service = ManualEkycService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );
      expect(service.isAvailable, isTrue);
    });

    test('checkStatus returns notStarted when doc does not exist', () async {
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'user-001'),
      );
      final service = ManualEkycService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final status = await service.checkStatus('user-001');
      expect(status, EkycStatus.notStarted);
    });

    test('checkStatus returns correct status for pending/approved/rejected', () async {
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'user-001'),
      );
      final service = ManualEkycService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      // pending
      await fakeFirestore
          .collection('identity_verification')
          .doc('user-pending')
          .set({'status': 'pending'});
      final pendingStatus = await service.checkStatus('user-pending');
      expect(pendingStatus, EkycStatus.pending);

      // approved
      await fakeFirestore
          .collection('identity_verification')
          .doc('user-approved')
          .set({'status': 'approved'});
      final approvedStatus = await service.checkStatus('user-approved');
      expect(approvedStatus, EkycStatus.approved);

      // rejected
      await fakeFirestore
          .collection('identity_verification')
          .doc('user-rejected')
          .set({'status': 'rejected'});
      final rejectedStatus = await service.checkStatus('user-rejected');
      expect(rejectedStatus, EkycStatus.rejected);
    });

    test('startVerification returns EkycPending for authenticated user', () async {
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'user-001'),
      );
      final service = ManualEkycService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.startVerification('user-001');
      expect(result, isA<EkycPending>());
      expect((result as EkycPending).message, '身分証明書と顔写真をアップロードしてください');
    });

    test('startVerification returns EkycError for null user (unauthenticated)', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = ManualEkycService(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.startVerification('user-001');
      expect(result, isA<EkycError>());
      expect((result as EkycError).message, '認証が必要です');
    });
  });
}
