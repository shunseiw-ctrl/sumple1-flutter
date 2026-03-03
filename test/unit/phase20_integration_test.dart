import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:sumple1/data/models/identity_verification_model.dart';
import 'package:sumple1/core/services/ekyc_manual_service.dart';
import 'package:sumple1/core/providers/admin_pending_counts_provider.dart';
import 'package:sumple1/core/services/connectivity_service.dart';
import 'package:sumple1/data/models/payment_test_result.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/utils/offline_aware_query.dart';

void main() {
  group('Phase 20 Integration', () {
    test('IdentityVerificationModel toMap/fromMap round trip', () {
      final original = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
        documentType: 'passport',
        status: 'pending',
        reviewedBy: null,
        rejectionReason: null,
      );

      final map = original.toMap();
      final restored = IdentityVerificationModel.fromMap(map);

      expect(restored.uid, original.uid);
      expect(restored.idPhotoUrl, original.idPhotoUrl);
      expect(restored.selfieUrl, original.selfieUrl);
      expect(restored.documentType, original.documentType);
      expect(restored.status, original.status);
      expect(restored, equals(original));
    });

    test('ManualEkycService approve updates profiles', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'admin1'),
      );
      final service = ManualEkycService(firestore: fakeFirestore, auth: mockAuth);

      // Setup data
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

      final verifyDoc =
          await fakeFirestore.collection('identity_verification').doc('user1').get();
      expect(verifyDoc.data()?['status'], 'approved');
      expect(verifyDoc.data()?['reviewedBy'], 'admin1');

      final profileDoc =
          await fakeFirestore.collection('profiles').doc('user1').get();
      expect(profileDoc.data()?['identityVerified'], true);
    });

    test('ManualEkycService reject saves rejectionReason', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'admin1'),
      );
      final service = ManualEkycService(firestore: fakeFirestore, auth: mockAuth);

      await fakeFirestore.collection('identity_verification').doc('user1').set({
        'uid': 'user1',
        'idPhotoUrl': 'https://example.com/id.jpg',
        'selfieUrl': 'https://example.com/selfie.jpg',
        'status': 'pending',
      });

      await service.rejectVerification('user1', 'admin1', '写真が不鮮明です');

      final doc =
          await fakeFirestore.collection('identity_verification').doc('user1').get();
      expect(doc.data()?['status'], 'rejected');
      expect(doc.data()?['rejectionReason'], '写真が不鮮明です');
    });

    test('AdminPendingCounts includes pendingVerifications', () {
      const counts = AdminPendingCounts(
        pendingApplications: 5,
        pendingQualifications: 3,
        pendingEarlyPayments: 2,
        pendingVerifications: 7,
      );
      expect(counts.total, 17);
      expect(counts.pendingVerifications, 7);
    });

    test('ConnectivityService initial state is online', () {
      final service = ConnectivityService();
      expect(service.isOnline, true);
    });

    test('OfflineAwareQuery getWithFallback works', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore.collection('test').add({'name': 'item1'});

      final result = await fakeFirestore.collection('test').getWithFallback();
      expect(result.docs.length, 1);
      expect(result.docs.first.data()['name'], 'item1');
    });

    test('PaymentTestResult tracks all steps', () {
      var result = PaymentTestResult(steps: []);
      result = result.addStep(const PaymentTestStep('Account', true, 'OK'));
      result = result.addStep(const PaymentTestStep('Payment', true, 'OK'));
      expect(result.allPassed, true);
      expect(result.passedCount, 2);
    });

    test('RoutePaths adminIdentityVerification exists', () {
      expect(RoutePaths.adminIdentityVerification, '/admin/identity-verification');
    });
  });
}
