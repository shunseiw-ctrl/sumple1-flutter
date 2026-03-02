import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/chat_service.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/services/distance_sort_service.dart';
import 'package:sumple1/core/services/location_service.dart';
import 'package:sumple1/core/utils/distance_utils.dart';
import 'package:sumple1/data/models/message_model.dart';
import '../../test/helpers/test_fixtures.dart';

void main() {
  group('Phase 15 結合テスト', () {
    test('画像メッセージsendImageMessage→Firestore書込み確認', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockUser = MockUser(isAnonymous: false, uid: 'worker-001', email: 'w@test.com');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      final chatService = ChatService(
        firestore: fakeFirestore,
        auth: mockAuth,
        notificationService: NotificationService(firestore: fakeFirestore),
      );

      await fakeFirestore.collection('applications').doc('app-001').set({
        'applicantUid': 'worker-001',
        'adminUid': 'admin-001',
        'jobId': 'job-001',
      });
      await fakeFirestore.collection('chats').doc('app-001').set({
        'applicantUid': 'worker-001',
        'adminUid': 'admin-001',
        'jobId': 'job-001',
        'titleSnapshot': 'テスト案件',
      });

      final result = await chatService.sendImageMessage(
        applicationId: 'app-001',
        imageUrl: 'https://example.com/photo.jpg',
        text: '現場写真',
      );

      expect(result.success, isTrue);

      final messages = await fakeFirestore
          .collection('chats')
          .doc('app-001')
          .collection('messages')
          .get();
      expect(messages.docs.length, 1);
      final msgData = messages.docs.first.data();
      expect(msgData['imageUrl'], 'https://example.com/photo.jpg');
      expect(msgData['messageType'], 'image');
      expect(msgData['text'], '現場写真');
    });

    test('距離計算: 東京→横浜 ≈ 27-29km', () {
      final distance = LocationService.calculateDistance(
        35.6812, 139.7671, // 東京駅
        35.4657, 139.6223, // 横浜駅
      );

      final km = distance / 1000;
      expect(km, greaterThan(27));
      expect(km, lessThan(29));
    });

    test('MessageModel imageUrl付きラウンドトリップ（toMap→fromMap）', () {
      final original = MessageModel(
        id: 'msg-001',
        senderUid: 'worker-001',
        text: '現場写真',
        imageUrl: 'https://example.com/photo.jpg',
        messageType: 'image',
        createdAt: DateTime(2025, 3, 15),
      );

      final map = original.toMap();
      expect(map['imageUrl'], 'https://example.com/photo.jpg');
      expect(map['messageType'], 'image');
      expect(map['text'], '現場写真');

      // fromMapで復元
      final restored = MessageModel.fromMap('msg-001', {
        ...map,
        'createdAt': DateTime(2025, 3, 15),
      });

      expect(restored.imageUrl, original.imageUrl);
      expect(restored.messageType, original.messageType);
      expect(restored.text, original.text);
      expect(restored.isImage, isTrue);
      expect(restored.isNotEmpty, isTrue);
    });

    test('DistanceSortService + DistanceUtils統合: formatDistance付き結果', () {
      final service = DistanceSortService();
      final jobs = [
        {
          'data': {'latitude': 35.6812, 'longitude': 139.7671},
          'docId': 'tokyo',
        },
        {
          'data': {'latitude': 34.6937, 'longitude': 135.5023},
          'docId': 'osaka',
        },
      ];

      // 東京駅付近から計算
      final results = service.calculateDistances(jobs, 35.6812, 139.7671);

      // 東京→東京 = ほぼ0m
      expect(results[0].distanceMeters, lessThan(100));
      expect(results[0].distanceLabel, isNotNull);

      // 東京→大阪 ≈ 400km
      final osakaDistance = results[1].distanceMeters!;
      expect(osakaDistance / 1000, closeTo(400, 20));
      expect(results[1].distanceLabel, isNotNull);

      // formatDistanceの確認
      expect(DistanceUtils.formatDistance(osakaDistance), contains('km'));
    });

    test('TestFixtures.imageMessageData→MessageModel変換', () {
      final data = TestFixtures.imageMessageData(
        senderUid: 'user-001',
        imageUrl: 'https://example.com/chat.jpg',
      );

      final model = MessageModel.fromMap('msg-img', data);

      expect(model.imageUrl, 'https://example.com/chat.jpg');
      expect(model.messageType, 'image');
      expect(model.isImage, isTrue);
      expect(model.senderUid, 'user-001');
    });
  });
}
