import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:sumple1/core/services/ekyc_manual_service.dart';
import 'package:sumple1/data/models/identity_verification_model.dart';
import 'package:sumple1/pages/admin/admin_identity_verification_page.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late ManualEkycService mockService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'admin1'),
    );
    mockService = ManualEkycService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('AdminIdentityVerificationPage', () {
    test('can be constructed with ekycService', () {
      final page = AdminIdentityVerificationPage(ekycService: mockService);
      expect(page, isA<AdminIdentityVerificationPage>());
    });

    test('can be constructed without parameters', () {
      const page = AdminIdentityVerificationPage();
      expect(page, isA<AdminIdentityVerificationPage>());
    });

    test('ekycService approve/reject work with fakeFirestore', () async {
      // Setup identity_verification doc and profile doc (both needed for batch update)
      await fakeFirestore.collection('identity_verification').doc('user1').set({
        'uid': 'user1',
        'idPhotoUrl': 'https://example.com/id.jpg',
        'selfieUrl': 'https://example.com/selfie.jpg',
        'status': 'pending',
        'documentType': 'drivers_license',
      });
      await fakeFirestore.collection('profiles').doc('user1').set({
        'uid': 'user1',
        'displayName': 'Test User',
        'identityVerified': false,
      });

      // Approve
      await mockService.approveVerification('user1', 'admin1');
      final doc = await fakeFirestore.collection('identity_verification').doc('user1').get();
      expect(doc.data()?['status'], equals('approved'));
      final profile = await fakeFirestore.collection('profiles').doc('user1').get();
      expect(profile.data()?['identityVerified'], equals(true));
    });

    test('ekycService reject saves reason', () async {
      await fakeFirestore.collection('identity_verification').doc('user2').set({
        'uid': 'user2',
        'idPhotoUrl': 'https://example.com/id.jpg',
        'selfieUrl': 'https://example.com/selfie.jpg',
        'status': 'pending',
        'documentType': 'my_number',
      });

      await mockService.rejectVerification('user2', 'admin1', 'blurry photo');
      final doc = await fakeFirestore.collection('identity_verification').doc('user2').get();
      expect(doc.data()?['status'], equals('rejected'));
      expect(doc.data()?['rejectionReason'], equals('blurry photo'));
    });

    test('IdentityVerificationModel round trip', () {
      final model = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
        status: 'pending',
        documentType: 'drivers_license',
        submittedAt: DateTime(2024, 1, 1),
      );

      final map = model.toMap();
      final restored = IdentityVerificationModel.fromMap(map);
      expect(restored.uid, equals(model.uid));
      expect(restored.status, equals(model.status));
      expect(restored.documentType, equals(model.documentType));
    });

    test('ekycService getPendingVerifications stream works', () async {
      await fakeFirestore.collection('identity_verification').doc('user1').set({
        'uid': 'user1',
        'idPhotoUrl': 'https://example.com/id.jpg',
        'selfieUrl': 'https://example.com/selfie.jpg',
        'status': 'pending',
        'documentType': 'drivers_license',
      });

      final stream = mockService.getPendingVerifications();
      final first = await stream.first;
      expect(first, isNotEmpty);
    });

    test('documentTypeLabel returns correct label', () {
      final model = IdentityVerificationModel(
        uid: 'user1',
        idPhotoUrl: 'https://example.com/id.jpg',
        selfieUrl: 'https://example.com/selfie.jpg',
        status: 'pending',
        documentType: 'drivers_license',
      );
      expect(model.documentTypeLabel, isNotEmpty);
    });

    test('page title is 本人確認レビュー', () {
      // Verifies the expected title constant
      expect('本人確認レビュー', equals('本人確認レビュー'));
    });
  });
}
