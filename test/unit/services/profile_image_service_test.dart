import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumple1/core/services/image_upload_service.dart';
import 'package:sumple1/core/services/profile_image_service.dart';

class MockImageUploadService extends Mock implements ImageUploadService {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockImageUploadService mockImageUpload;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockImageUpload = MockImageUploadService();
  });

  group('ProfileImageService', () {
    test('未認証ユーザー→エラー', () async {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      final service = ProfileImageService(
        imageUploadService: mockImageUpload,
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.pickAndUploadAvatar();
      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('認証が必要'));
    });

    test('匿名ユーザー→エラー', () async {
      final mockUser = MockUser(isAnonymous: true, uid: 'anon123');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      final service = ProfileImageService(
        imageUploadService: mockImageUpload,
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.pickAndUploadAvatar();
      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('匿名ユーザー'));
    });

    test('ギャラリー選択成功→Firestore profilePhotoUrl更新', () async {
      final mockUser = MockUser(isAnonymous: false, uid: 'user123');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      // profileドキュメントをセットアップ
      await fakeFirestore.collection('profiles').doc('user123').set({
        'profilePhotoLocked': false,
      });

      when(() => mockImageUpload.pickAndUploadImage(
            userId: any(named: 'userId'),
            folder: any(named: 'folder'),
            documentId: any(named: 'documentId'),
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            quality: any(named: 'quality'),
          )).thenAnswer((_) async => ImageUploadResult.success('https://example.com/photo.jpg'));

      final service = ProfileImageService(
        imageUploadService: mockImageUpload,
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.pickAndUploadAvatar();
      expect(result.isSuccess, true);
      expect(result.downloadUrl, 'https://example.com/photo.jpg');

      // Firestoreに保存されたか確認
      final doc = await fakeFirestore.collection('profiles').doc('user123').get();
      expect(doc.data()?['profilePhotoUrl'], 'https://example.com/photo.jpg');
    });

    test('カメラ撮影成功→Firestore更新', () async {
      final mockUser = MockUser(isAnonymous: false, uid: 'user456');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await fakeFirestore.collection('profiles').doc('user456').set({
        'profilePhotoLocked': false,
      });

      when(() => mockImageUpload.captureAndUploadImage(
            userId: any(named: 'userId'),
            folder: any(named: 'folder'),
            documentId: any(named: 'documentId'),
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            quality: any(named: 'quality'),
          )).thenAnswer((_) async => ImageUploadResult.success('https://example.com/camera.jpg'));

      final service = ProfileImageService(
        imageUploadService: mockImageUpload,
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.captureAndUploadAvatar();
      expect(result.isSuccess, true);

      final doc = await fakeFirestore.collection('profiles').doc('user456').get();
      expect(doc.data()?['profilePhotoUrl'], 'https://example.com/camera.jpg');
    });

    test('キャンセル時→変更なし', () async {
      final mockUser = MockUser(isAnonymous: false, uid: 'user789');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await fakeFirestore.collection('profiles').doc('user789').set({
        'profilePhotoLocked': false,
      });

      when(() => mockImageUpload.pickAndUploadImage(
            userId: any(named: 'userId'),
            folder: any(named: 'folder'),
            documentId: any(named: 'documentId'),
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            quality: any(named: 'quality'),
          )).thenAnswer((_) async => ImageUploadResult.cancelled());

      final service = ProfileImageService(
        imageUploadService: mockImageUpload,
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.pickAndUploadAvatar();
      expect(result.isSuccess, false);
      expect(result.isCancelled, true);

      final doc = await fakeFirestore.collection('profiles').doc('user789').get();
      expect(doc.data()?['profilePhotoUrl'], null);
    });

    test('profilePhotoLocked==true→更新拒否', () async {
      final mockUser = MockUser(isAnonymous: false, uid: 'lockedUser');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await fakeFirestore.collection('profiles').doc('lockedUser').set({
        'profilePhotoLocked': true,
      });

      final service = ProfileImageService(
        imageUploadService: mockImageUpload,
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.pickAndUploadAvatar();
      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('本人確認済み'));
    });
  });
}
