import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/repositories/job_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late JobRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = JobRepository(firestore: fakeFirestore);
  });

  Map<String, dynamic> jobData({
    String title = 'テスト案件',
    String location = '東京都渋谷区',
    String prefecture = '東京都',
    String price = '15000',
    String date = '2026-04-01',
    String? workMonthKey,
    String? ownerId,
  }) {
    return {
      'title': title,
      'location': location,
      'prefecture': prefecture,
      'price': price,
      'date': date,
      if (workMonthKey != null) 'workMonthKey': workMonthKey,
      if (ownerId != null) 'ownerId': ownerId,
      'createdAt': DateTime.now(),
    };
  }

  group('getJobsPaginated', () {
    test('returns first page with correct limit', () async {
      // 25件投入
      for (int i = 0; i < 25; i++) {
        await fakeFirestore.collection('jobs').add(
          jobData(title: '案件$i', prefecture: '東京都'),
        );
      }

      final result = await repository.getJobsPaginated(
        prefecture: '東京都',
        limit: 20,
      );

      expect(result.items.length, 20);
      expect(result.hasMore, isTrue);
      expect(result.lastDocument, isNotNull);
    });

    test('returns all items when less than limit', () async {
      for (int i = 0; i < 5; i++) {
        await fakeFirestore.collection('jobs').add(
          jobData(title: '案件$i'),
        );
      }

      final result = await repository.getJobsPaginated(limit: 20);

      expect(result.items.length, 5);
      expect(result.hasMore, isFalse);
    });

    test('returns second page using startAfter', () async {
      for (int i = 0; i < 30; i++) {
        await fakeFirestore.collection('jobs').add(
          jobData(title: '案件${i.toString().padLeft(2, '0')}'),
        );
      }

      final page1 = await repository.getJobsPaginated(limit: 20);
      expect(page1.items.length, 20);
      expect(page1.hasMore, isTrue);

      final page2 = await repository.getJobsPaginated(
        limit: 20,
        startAfter: page1.lastDocument,
      );

      expect(page2.items.length, 10);
      expect(page2.hasMore, isFalse);
    });

    test('filters by prefecture', () async {
      await fakeFirestore.collection('jobs').add(
        jobData(title: '東京案件', prefecture: '東京都'),
      );
      await fakeFirestore.collection('jobs').add(
        jobData(title: '千葉案件', prefecture: '千葉県'),
      );

      final result = await repository.getJobsPaginated(prefecture: '東京都');

      expect(result.items.length, 1);
      expect(result.items.first.title, '東京案件');
    });

    test('filters by workMonthKey', () async {
      await fakeFirestore.collection('jobs').add(
        jobData(title: '4月案件', workMonthKey: '2026-04'),
      );
      await fakeFirestore.collection('jobs').add(
        jobData(title: '5月案件', workMonthKey: '2026-05'),
      );

      final result = await repository.getJobsPaginated(
        workMonthKey: '2026-04',
      );

      expect(result.items.length, 1);
      expect(result.items.first.title, '4月案件');
    });

    test('returns empty result for no matches', () async {
      await fakeFirestore.collection('jobs').add(
        jobData(title: '東京案件', prefecture: '東京都'),
      );

      final result = await repository.getJobsPaginated(prefecture: '大阪府');

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.lastDocument, isNull);
    });

    test('filters その他 prefecture (excludes major prefectures)', () async {
      await fakeFirestore.collection('jobs').add(
        jobData(title: '東京案件', prefecture: '東京都'),
      );
      await fakeFirestore.collection('jobs').add(
        jobData(title: '埼玉案件', prefecture: '埼玉県'),
      );
      await fakeFirestore.collection('jobs').add(
        jobData(title: '未設定案件', prefecture: '未設定'),
      );

      final result = await repository.getJobsPaginated(prefecture: 'その他');

      // 東京都は除外、埼玉県と未設定は含む
      expect(result.items.length, 2);
      final titles = result.items.map((j) => j.title).toSet();
      expect(titles.contains('埼玉案件'), isTrue);
      expect(titles.contains('未設定案件'), isTrue);
    });

    test('uses default limit of 20', () async {
      for (int i = 0; i < 25; i++) {
        await fakeFirestore.collection('jobs').add(jobData(title: '案件$i'));
      }

      final result = await repository.getJobsPaginated();

      expect(result.items.length, 20);
      expect(result.hasMore, isTrue);
    });
  });
}
