import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:sumple1/data/models/job_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('JobRepository with FakeFirestore', () {
    group('create and read', () {
      test('should create and retrieve a job', () async {
        final jobData = {
          'title': 'クロス張替え',
          'location': '東京都新宿区',
          'prefecture': '東京都',
          'price': 30000,
          'date': '2026-03-01',
          'workMonthKey': '2026-03',
          'workDateKey': '2026-03-01',
          'ownerId': 'owner-1',
          'description': 'テスト説明',
          'notes': '',
        };

        final docRef = await fakeFirestore.collection('jobs').add(jobData);
        final doc = await fakeFirestore.collection('jobs').doc(docRef.id).get();

        expect(doc.exists, true);
        final model = JobModel.fromFirestore(doc);
        expect(model.title, 'クロス張替え');
        expect(model.location, '東京都新宿区');
        expect(model.prefecture, '東京都');
        expect(model.price, 30000);
      });

      test('should return null data for non-existent job', () async {
        final doc =
            await fakeFirestore.collection('jobs').doc('non-existent').get();
        expect(doc.exists, false);
      });
    });

    group('filtering', () {
      setUp(() async {
        await fakeFirestore.collection('jobs').add({
          'title': '案件A',
          'location': '東京都渋谷区',
          'prefecture': '東京都',
          'price': 20000,
          'date': '2026-03-01',
          'workMonthKey': '2026-03',
          'ownerId': 'owner-1',
        });
        await fakeFirestore.collection('jobs').add({
          'title': '案件B',
          'location': '千葉県千葉市',
          'prefecture': '千葉県',
          'price': 25000,
          'date': '2026-04-01',
          'workMonthKey': '2026-04',
          'ownerId': 'owner-2',
        });
        await fakeFirestore.collection('jobs').add({
          'title': '案件C',
          'location': '神奈川県横浜市',
          'prefecture': '神奈川県',
          'price': 35000,
          'date': '2026-03-15',
          'workMonthKey': '2026-03',
          'ownerId': 'owner-1',
        });
      });

      test('should filter by prefecture', () async {
        final snapshot = await fakeFirestore
            .collection('jobs')
            .where('prefecture', isEqualTo: '東京都')
            .get();

        expect(snapshot.docs.length, 1);
        expect(snapshot.docs.first.data()['title'], '案件A');
      });

      test('should filter by workMonthKey', () async {
        final snapshot = await fakeFirestore
            .collection('jobs')
            .where('workMonthKey', isEqualTo: '2026-03')
            .get();

        expect(snapshot.docs.length, 2);
      });

      test('should filter by owner', () async {
        final snapshot = await fakeFirestore
            .collection('jobs')
            .where('ownerId', isEqualTo: 'owner-1')
            .get();

        expect(snapshot.docs.length, 2);
      });

      test('should return all jobs without filter', () async {
        final snapshot = await fakeFirestore.collection('jobs').get();
        expect(snapshot.docs.length, 3);
      });
    });

    group('update and delete', () {
      test('should update a job', () async {
        final docRef = await fakeFirestore.collection('jobs').add({
          'title': '元のタイトル',
          'location': '東京都',
          'prefecture': '東京都',
          'price': 10000,
          'date': '2026-03-01',
          'ownerId': 'owner-1',
        });

        await fakeFirestore.collection('jobs').doc(docRef.id).update({
          'title': '更新後のタイトル',
          'price': 20000,
        });

        final updated =
            await fakeFirestore.collection('jobs').doc(docRef.id).get();
        expect(updated.data()!['title'], '更新後のタイトル');
        expect(updated.data()!['price'], 20000);
      });

      test('should delete a job', () async {
        final docRef = await fakeFirestore.collection('jobs').add({
          'title': '削除対象',
          'location': '東京都',
          'prefecture': '東京都',
          'price': 10000,
          'date': '2026-03-01',
          'ownerId': 'owner-1',
        });

        await fakeFirestore.collection('jobs').doc(docRef.id).delete();

        final doc =
            await fakeFirestore.collection('jobs').doc(docRef.id).get();
        expect(doc.exists, false);
      });
    });

    group('JobModel', () {
      test('fromFirestore handles missing fields gracefully', () async {
        await fakeFirestore.collection('jobs').doc('minimal').set({
          'title': 'タイトルのみ',
        });

        final doc =
            await fakeFirestore.collection('jobs').doc('minimal').get();
        final model = JobModel.fromFirestore(doc);
        expect(model.title, 'タイトルのみ');
        expect(model.location, '未設定');
        expect(model.price, 0);
      });

      test('fromFirestore parses string price correctly', () async {
        await fakeFirestore.collection('jobs').doc('string-price').set({
          'title': 'テスト',
          'price': '25000',
        });

        final doc =
            await fakeFirestore.collection('jobs').doc('string-price').get();
        final model = JobModel.fromFirestore(doc);
        expect(model.price, 25000);
      });

      test('copyWith creates new instance with updated fields', () {
        final original = JobModel(
          id: '1',
          title: '元',
          location: '東京都',
          prefecture: '東京都',
          price: 10000,
          date: '2026-01-01',
        );

        final copied = original.copyWith(title: '変更後', price: 50000);
        expect(copied.title, '変更後');
        expect(copied.price, 50000);
        expect(copied.location, '東京都');
        expect(copied.id, '1');
      });

      test('isOwner returns correct value', () {
        final job = JobModel(
          id: '1',
          title: 'テスト',
          location: '東京都',
          prefecture: '東京都',
          price: 10000,
          date: '2026-01-01',
          ownerId: 'owner-123',
        );

        expect(job.isOwner('owner-123'), true);
        expect(job.isOwner('other-uid'), false);
      });
    });
  });
}
