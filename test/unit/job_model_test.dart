import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/job_model.dart';

void main() {
  group('JobModel.fromMap', () {
    test('with complete data', () {
      final now = DateTime(2025, 1, 15, 10, 30);
      final data = {
        'title': '足場工事',
        'location': '東京都渋谷区',
        'prefecture': '東京都',
        'price': 15000,
        'date': '2025-01-20',
        'workMonthKey': '2025-01',
        'ownerId': 'owner123',
        'description': '3階建て住宅の足場組立',
        'createdAt': now,
        'updatedAt': now,
      };

      final job = JobModel.fromMap('job1', data);

      expect(job.id, 'job1');
      expect(job.title, '足場工事');
      expect(job.location, '東京都渋谷区');
      expect(job.prefecture, '東京都');
      expect(job.price, 15000);
      expect(job.date, '2025-01-20');
      expect(job.workMonthKey, '2025-01');
      expect(job.ownerId, 'owner123');
      expect(job.description, '3階建て住宅の足場組立');
      expect(job.createdAt, now);
      expect(job.updatedAt, now);
    });

    test('with missing optional fields uses defaults', () {
      final data = <String, dynamic>{};

      final job = JobModel.fromMap('job2', data);

      expect(job.id, 'job2');
      expect(job.title, 'タイトルなし');
      expect(job.location, '未設定');
      expect(job.prefecture, '未設定');
      expect(job.price, 0);
      expect(job.date, '未設定');
      expect(job.workMonthKey, isNull);
      expect(job.ownerId, isNull);
      expect(job.description, isNull);
    });

    test('with null data values', () {
      final data = {
        'title': null,
        'location': null,
        'prefecture': null,
        'price': null,
        'date': null,
        'workMonthKey': null,
        'ownerId': null,
        'description': null,
        'createdAt': null,
        'updatedAt': null,
      };

      final job = JobModel.fromMap('job3', data);

      expect(job.title, 'タイトルなし');
      expect(job.location, '未設定');
      expect(job.prefecture, '未設定');
      expect(job.price, 0);
      expect(job.date, '未設定');
      expect(job.workMonthKey, isNull);
      expect(job.ownerId, isNull);
      expect(job.description, isNull);
      expect(job.createdAt, isNull);
      expect(job.updatedAt, isNull);
    });
  });

  group('toMap', () {
    test('returns correct fields', () {
      final job = JobModel(
        id: 'job1',
        title: '塗装工事',
        location: '千葉県船橋市',
        prefecture: '千葉県',
        price: 20000,
        date: '2025-02-01',
        workMonthKey: '2025-02',
        ownerId: 'owner456',
        description: '外壁塗装',
      );

      final map = job.toMap();

      expect(map['title'], '塗装工事');
      expect(map['location'], '千葉県船橋市');
      expect(map['prefecture'], '千葉県');
      expect(map['price'], 20000);
      expect(map['date'], '2025-02-01');
      expect(map['workMonthKey'], '2025-02');
      expect(map['ownerId'], 'owner456');
      expect(map['description'], '外壁塗装');
      expect(map['updatedAt'], isA<FieldValue>());
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('createdAt'), isFalse);
    });

    test('excludes null optional fields', () {
      final job = JobModel(
        id: 'job1',
        title: 'テスト',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-01-01',
      );

      final map = job.toMap();

      expect(map.containsKey('workMonthKey'), isFalse);
      expect(map.containsKey('ownerId'), isFalse);
      expect(map.containsKey('description'), isFalse);
    });
  });

  group('toCreateMap', () {
    test('includes createdAt', () {
      final job = JobModel(
        id: 'job1',
        title: 'テスト',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-01-01',
      );

      final map = job.toCreateMap();

      expect(map.containsKey('createdAt'), isTrue);
      expect(map['createdAt'], isA<FieldValue>());
      expect(map.containsKey('updatedAt'), isTrue);
    });
  });

  group('copyWith', () {
    test('creates modified copy', () {
      final original = JobModel(
        id: 'job1',
        title: '元のタイトル',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-01-01',
        ownerId: 'owner1',
      );

      final copied = original.copyWith(
        title: '新しいタイトル',
        price: 25000,
      );

      expect(copied.id, 'job1');
      expect(copied.title, '新しいタイトル');
      expect(copied.price, 25000);
      expect(copied.location, '東京');
      expect(copied.prefecture, '東京都');
      expect(copied.date, '2025-01-01');
      expect(copied.ownerId, 'owner1');
    });

    test('preserves all fields when no changes', () {
      final original = JobModel(
        id: 'job1',
        title: 'タイトル',
        location: '場所',
        prefecture: '県',
        price: 5000,
        date: '2025-01-01',
        ownerId: 'owner1',
        description: '説明',
      );

      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.title, original.title);
      expect(copied.location, original.location);
      expect(copied.prefecture, original.prefecture);
      expect(copied.price, original.price);
      expect(copied.date, original.date);
      expect(copied.ownerId, original.ownerId);
      expect(copied.description, original.description);
    });
  });

  group('hasOwner', () {
    test('returns true when ownerId is set', () {
      final job = JobModel(
        id: 'job1',
        title: 'テスト',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-01-01',
        ownerId: 'owner123',
      );

      expect(job.hasOwner, isTrue);
    });

    test('returns false when ownerId is null', () {
      final job = JobModel(
        id: 'job1',
        title: 'テスト',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-01-01',
      );

      expect(job.hasOwner, isFalse);
    });

    test('returns false when ownerId is empty string', () {
      final job = JobModel(
        id: 'job1',
        title: 'テスト',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-01-01',
        ownerId: '',
      );

      expect(job.hasOwner, isFalse);
    });
  });

  group('isOwner', () {
    test('returns true for matching userId', () {
      final job = JobModel(
        id: 'job1',
        title: 'テスト',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-01-01',
        ownerId: 'user123',
      );

      expect(job.isOwner('user123'), isTrue);
    });

    test('returns false for non-matching userId', () {
      final job = JobModel(
        id: 'job1',
        title: 'テスト',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-01-01',
        ownerId: 'user123',
      );

      expect(job.isOwner('user456'), isFalse);
    });

    test('returns false when no owner', () {
      final job = JobModel(
        id: 'job1',
        title: 'テスト',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-01-01',
      );

      expect(job.isOwner('user123'), isFalse);
    });
  });

  group('_parseInt (tested via fromMap)', () {
    test('handles int value', () {
      final job = JobModel.fromMap('id', {'price': 5000});
      expect(job.price, 5000);
    });

    test('handles String value', () {
      final job = JobModel.fromMap('id', {'price': '12000'});
      expect(job.price, 12000);
    });

    test('handles null value', () {
      final job = JobModel.fromMap('id', {'price': null});
      expect(job.price, 0);
    });

    test('handles invalid String value', () {
      final job = JobModel.fromMap('id', {'price': 'abc'});
      expect(job.price, 0);
    });
  });

  group('toString', () {
    test('returns correct format', () {
      final job = JobModel(
        id: 'job1',
        title: '足場工事',
        location: '東京都',
        prefecture: '東京都',
        price: 15000,
        date: '2025-01-01',
      );

      final str = job.toString();

      expect(str, 'JobModel(id: job1, title: 足場工事, location: 東京都, price: 15000)');
    });
  });
}
