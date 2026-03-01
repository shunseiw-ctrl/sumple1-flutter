import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/favorites_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('FavoritesService with anonymous user', () {
    late FavoritesService service;

    setUp(() {
      final mockAuth = MockFirebaseAuth(signedIn: false);
      service = FavoritesService(firestore: fakeFirestore, auth: mockAuth);
    });

    test('isRegistered returns false for unauthenticated user', () {
      expect(service.isRegistered, isFalse);
    });

    test('favoritesStream returns empty list for unauthenticated user', () async {
      final stream = service.favoritesStream();
      final result = await stream.first;
      expect(result, isEmpty);
    });

    test('toggleFavorite does nothing for unauthenticated user', () async {
      await service.toggleFavorite('job1');
      final snap = await fakeFirestore.collection('favorites').get();
      expect(snap.docs, isEmpty);
    });
  });

  group('FavoritesService with signed-in user', () {
    late FavoritesService service;
    const testUid = 'test-uid-123';

    setUp(() {
      final mockUser = MockUser(uid: testUid, isAnonymous: false);
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      service = FavoritesService(firestore: fakeFirestore, auth: mockAuth);
    });

    test('isRegistered returns true for signed-in user', () {
      expect(service.isRegistered, isTrue);
    });

    test('toggleFavorite adds a job', () async {
      await service.toggleFavorite('job1');

      final doc = await fakeFirestore.collection('favorites').doc(testUid).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['jobIds'], contains('job1'));
    });

    test('toggleFavorite removes existing job', () async {
      await service.toggleFavorite('job1');
      await service.toggleFavorite('job1');

      final doc = await fakeFirestore.collection('favorites').doc(testUid).get();
      final data = doc.data()!;
      expect(data['jobIds'], isNot(contains('job1')));
    });

    test('toggleFavorite adds multiple jobs', () async {
      await service.toggleFavorite('job1');
      await service.toggleFavorite('job2');

      final doc = await fakeFirestore.collection('favorites').doc(testUid).get();
      final data = doc.data()!;
      expect(data['jobIds'], containsAll(['job1', 'job2']));
    });

    test('favoritesStream emits favorites', () async {
      await service.toggleFavorite('job1');

      final stream = service.favoritesStream();
      final result = await stream.first;
      expect(result, contains('job1'));
    });

    test('favoritesStream emits empty list initially', () async {
      final stream = service.favoritesStream();
      final result = await stream.first;
      expect(result, isEmpty);
    });
  });
}
