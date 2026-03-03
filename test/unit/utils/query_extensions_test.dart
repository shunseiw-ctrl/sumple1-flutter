import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:sumple1/core/utils/query_extensions.dart';

void main() {
  group('QueryTimeout', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('getWithTimeout returns data on success', () async {
      await fakeFirestore.collection('test').add({'name': 'item1'});

      final result = await fakeFirestore.collection('test').getWithTimeout(
        timeout: const Duration(seconds: 5),
      );
      expect(result.docs.length, 1);
      expect(result.docs.first.data()['name'], 'item1');
    });

    test('getWithTimeout works with empty collection', () async {
      final result = await fakeFirestore.collection('test').getWithTimeout();
      expect(result.docs, isEmpty);
    });
  });
}
