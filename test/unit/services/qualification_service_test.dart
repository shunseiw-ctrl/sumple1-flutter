import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/qualification_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late QualificationService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'worker-001'),
    );
    service = QualificationService(firestore: fakeFirestore, auth: mockAuth);
  });

  group('QualificationService', () {
    test('addQualification が資格ドキュメントを作成する', () async {
      await service.addQualification(
        name: '内装仕上げ施工技能士',
        category: 'interior',
        certPhotoUrl: 'https://example.com/cert.jpg',
      );

      final snap = await fakeFirestore
          .collection('profiles')
          .doc('worker-001')
          .collection('qualifications_v2')
          .get();
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();
      expect(data['name'], '内装仕上げ施工技能士');
      expect(data['category'], 'interior');
      expect(data['verificationStatus'], 'pending');
    });

    test('approve が資格を承認する', () async {
      // 資格を追加
      final ref = await fakeFirestore
          .collection('profiles')
          .doc('target-user')
          .collection('qualifications_v2')
          .add({
        'uid': 'target-user',
        'name': '電気工事士',
        'category': 'electrical',
        'verificationStatus': 'pending',
      });

      await service.approve(
        targetUid: 'target-user',
        qualificationId: ref.id,
      );

      final doc = await fakeFirestore
          .collection('profiles')
          .doc('target-user')
          .collection('qualifications_v2')
          .doc(ref.id)
          .get();
      expect(doc.data()!['verificationStatus'], 'approved');
      expect(doc.data()!['reviewedBy'], 'worker-001');
    });

    test('reject が資格を却下する', () async {
      final ref = await fakeFirestore
          .collection('profiles')
          .doc('target-user')
          .collection('qualifications_v2')
          .add({
        'uid': 'target-user',
        'name': '溶接技能者',
        'category': 'welding',
        'verificationStatus': 'pending',
      });

      await service.reject(
        targetUid: 'target-user',
        qualificationId: ref.id,
        reason: '証明書が不鮮明です',
      );

      final doc = await fakeFirestore
          .collection('profiles')
          .doc('target-user')
          .collection('qualifications_v2')
          .doc(ref.id)
          .get();
      expect(doc.data()!['verificationStatus'], 'rejected');
      expect(doc.data()!['rejectionReason'], '証明書が不鮮明です');
    });
  });
}
