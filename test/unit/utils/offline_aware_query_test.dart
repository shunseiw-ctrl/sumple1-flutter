import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:sumple1/core/utils/offline_aware_query.dart';

void main() {
  group('OfflineAwareQuery', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('getWithFallback returns data from server', () async {
      await fakeFirestore.collection('jobs').add({
        'title': 'Test Job',
        'location': 'Tokyo',
      });

      final result = await fakeFirestore.collection('jobs').getWithFallback();
      expect(result.docs.length, 1);
      expect(result.docs.first.data()['title'], 'Test Job');
    });

    test('getWithFallback works with empty collection', () async {
      final result = await fakeFirestore.collection('jobs').getWithFallback();
      expect(result.docs, isEmpty);
    });
  });
}
