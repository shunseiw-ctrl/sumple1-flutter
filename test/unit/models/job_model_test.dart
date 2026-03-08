import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/job_model.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('JobModel.fromMap', () {
    test('完全なデータから正しくパースされる', () {
      final now = DateTime(2025, 4, 1, 10, 0);
      final data = {
        'title': '内装仕上げ工事',
        'location': '東京都渋谷区神南1-2-3',
        'prefecture': '東京都',
        'price': 25000,
        'date': '2025-04-15',
        'workMonthKey': '2025-04',
        'ownerId': 'owner-001',
        'description': 'オフィスビル内装仕上げ',
        'latitude': 35.6612,
        'longitude': 139.7010,
        'requiredQualifications': ['interior', 'scaffolding'],
        'imageUrl': 'https://example.com/main.jpg',
        'imageUrls': [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
        ],
        'category': '内装',
        'slots': 5,
        'applicantCount': 3,
        'status': 'published',
        'customInspectionItems': ['仕上がり確認', '清掃確認'],
        'createdAt': now,
        'updatedAt': now,
      };

      final job = JobModel.fromMap('job-001', data);

      expect(job.id, 'job-001');
      expect(job.title, '内装仕上げ工事');
      expect(job.location, '東京都渋谷区神南1-2-3');
      expect(job.prefecture, '東京都');
      expect(job.price, 25000);
      expect(job.date, '2025-04-15');
      expect(job.workMonthKey, '2025-04');
      expect(job.ownerId, 'owner-001');
      expect(job.description, 'オフィスビル内装仕上げ');
      expect(job.latitude, 35.6612);
      expect(job.longitude, 139.7010);
      expect(job.requiredQualifications, ['interior', 'scaffolding']);
      expect(job.imageUrls, [
        'https://example.com/img1.jpg',
        'https://example.com/img2.jpg',
      ]);
      expect(job.category, '内装');
      expect(job.slots, 5);
      expect(job.applicantCount, 3);
      expect(job.status, 'published');
      expect(job.customInspectionItems, ['仕上がり確認', '清掃確認']);
      expect(job.createdAt, now);
      expect(job.updatedAt, now);
    });

    test('必須フィールド欠損時にデフォルト値が設定される', () {
      final job = JobModel.fromMap('job-empty', <String, dynamic>{});

      expect(job.id, 'job-empty');
      expect(job.title, 'タイトルなし');
      expect(job.location, '未設定');
      expect(job.prefecture, '未設定');
      expect(job.price, 0);
      expect(job.date, '未設定');
      expect(job.status, 'published');
      expect(job.imageUrls, isEmpty);
      expect(job.workMonthKey, isNull);
      expect(job.ownerId, isNull);
      expect(job.description, isNull);
      expect(job.latitude, isNull);
      expect(job.longitude, isNull);
      expect(job.requiredQualifications, isNull);
      expect(job.imageUrl, isNull);
      expect(job.category, isNull);
      expect(job.slots, isNull);
      expect(job.applicantCount, isNull);
      expect(job.customInspectionItems, isNull);
      expect(job.createdAt, isNull);
      expect(job.updatedAt, isNull);
    });

    test('全フィールドnull時にデフォルト値が設定される', () {
      final data = {
        'title': null,
        'location': null,
        'prefecture': null,
        'price': null,
        'date': null,
        'status': null,
        'createdAt': null,
        'updatedAt': null,
        'latitude': null,
        'longitude': null,
        'slots': null,
      };

      final job = JobModel.fromMap('job-null', data);

      expect(job.title, 'タイトルなし');
      expect(job.location, '未設定');
      expect(job.prefecture, '未設定');
      expect(job.price, 0);
      expect(job.date, '未設定');
      expect(job.status, 'published');
      expect(job.createdAt, isNull);
      expect(job.updatedAt, isNull);
      expect(job.latitude, isNull);
      expect(job.longitude, isNull);
      expect(job.slots, isNull);
    });

    test('statusがdraftの場合にisDraftが真を返す', () {
      final job = JobModel.fromMap('job-draft', {'status': 'draft'});

      expect(job.status, 'draft');
      expect(job.isDraft, isTrue);
      expect(job.isPublished, isFalse);
    });
  });

  group('JobModel.fromMap imageUrl/imageUrls優先順位', () {
    test('imageUrlsが優先される（imageUrlとimageUrls両方存在）', () {
      final job = JobModel.fromMap('id', {
        'imageUrl': 'https://example.com/single.jpg',
        'imageUrls': ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
      });

      expect(job.imageUrls, [
        'https://example.com/a.jpg',
        'https://example.com/b.jpg',
      ]);
    });

    test('imageUrlのみの場合はimageUrlsにフォールバック', () {
      final job = JobModel.fromMap('id', {
        'imageUrl': 'https://example.com/only.jpg',
      });

      expect(job.imageUrls, ['https://example.com/only.jpg']);
      expect(job.imageUrl, 'https://example.com/only.jpg');
    });

    test('imageUrlsが空リストでimageUrlがある場合はimageUrlにフォールバック', () {
      final job = JobModel.fromMap('id', {
        'imageUrl': 'https://example.com/fallback.jpg',
        'imageUrls': <String>[],
      });

      expect(job.imageUrls, ['https://example.com/fallback.jpg']);
    });

    test('imageUrlが空文字の場合はimageUrlsは空リスト', () {
      final job = JobModel.fromMap('id', {'imageUrl': ''});

      expect(job.imageUrls, isEmpty);
    });

    test('両方未設定の場合はimageUrlsが空リスト', () {
      final job = JobModel.fromMap('id', <String, dynamic>{});

      expect(job.imageUrls, isEmpty);
      expect(job.imageUrl, isNull);
    });
  });

  group('JobModel.fromMap Timestamp処理', () {
    test('Timestamp型がDateTimeに正しく変換される', () {
      final ts = Timestamp.fromDate(DateTime(2025, 6, 15, 9, 30));
      final job = JobModel.fromMap('id', {'createdAt': ts, 'updatedAt': ts});

      expect(job.createdAt, DateTime(2025, 6, 15, 9, 30));
      expect(job.updatedAt, DateTime(2025, 6, 15, 9, 30));
    });

    test('DateTime型はそのまま保持される', () {
      final dt = DateTime(2025, 3, 1);
      final job = JobModel.fromMap('id', {'createdAt': dt, 'updatedAt': dt});

      expect(job.createdAt, dt);
      expect(job.updatedAt, dt);
    });

    test('null Timestampはnullになる', () {
      final job = JobModel.fromMap('id', {
        'createdAt': null,
        'updatedAt': null,
      });

      expect(job.createdAt, isNull);
      expect(job.updatedAt, isNull);
    });

    test('不正な型（String）はnullになる', () {
      final job = JobModel.fromMap('id', {
        'createdAt': '2025-01-01',
        'updatedAt': 12345,
      });

      expect(job.createdAt, isNull);
      expect(job.updatedAt, isNull);
    });
  });

  group('JobModel.fromMap 数値型変換', () {
    test('int値のpriceが正しくパースされる', () {
      final job = JobModel.fromMap('id', {'price': 15000});
      expect(job.price, 15000);
    });

    test('String値のpriceがintに変換される', () {
      final job = JobModel.fromMap('id', {'price': '20000'});
      expect(job.price, 20000);
    });

    test('不正なString値のpriceはデフォルト0になる', () {
      final job = JobModel.fromMap('id', {'price': 'abc'});
      expect(job.price, 0);
    });

    test('int値のlatitudeがdoubleに変換される', () {
      final job = JobModel.fromMap('id', {'latitude': 35, 'longitude': 139});
      expect(job.latitude, 35.0);
      expect(job.longitude, 139.0);
      expect(job.latitude, isA<double>());
      expect(job.longitude, isA<double>());
    });

    test('double値のlatitude/longitudeがそのまま保持される', () {
      final job = JobModel.fromMap('id', {
        'latitude': 35.6895,
        'longitude': 139.6917,
      });
      expect(job.latitude, 35.6895);
      expect(job.longitude, 139.6917);
    });

    test('String値のlatitudeがdoubleに変換される', () {
      final job = JobModel.fromMap('id', {
        'latitude': '35.6895',
        'longitude': '139.6917',
      });
      expect(job.latitude, 35.6895);
      expect(job.longitude, 139.6917);
    });

    test('String値のslotsがintに変換される', () {
      final job = JobModel.fromMap('id', {
        'slots': '10',
        'applicantCount': '3',
      });
      expect(job.slots, 10);
      expect(job.applicantCount, 3);
    });
  });

  group('JobModel.toMap', () {
    test('全フィールドが正しくシリアライズされる', () {
      final job = JobModel(
        id: 'job-001',
        title: '内装工事',
        location: '東京都新宿区',
        prefecture: '東京都',
        price: 15000,
        date: '2025-04-01',
        workMonthKey: '2025-04',
        ownerId: 'admin-001',
        description: 'テスト案件の説明',
        latitude: 35.6895,
        longitude: 139.6917,
        requiredQualifications: ['interior'],
        imageUrl: 'https://example.com/img.jpg',
        imageUrls: ['https://example.com/img.jpg'],
        category: '内装',
        slots: 5,
        applicantCount: 2,
        status: 'published',
        customInspectionItems: ['品質確認'],
      );

      final map = job.toMap();

      expect(map['title'], '内装工事');
      expect(map['location'], '東京都新宿区');
      expect(map['prefecture'], '東京都');
      expect(map['price'], 15000);
      expect(map['date'], '2025-04-01');
      expect(map['workMonthKey'], '2025-04');
      expect(map['ownerId'], 'admin-001');
      expect(map['description'], 'テスト案件の説明');
      expect(map['latitude'], 35.6895);
      expect(map['longitude'], 139.6917);
      expect(map['requiredQualifications'], ['interior']);
      expect(map['imageUrl'], 'https://example.com/img.jpg');
      expect(map['imageUrls'], ['https://example.com/img.jpg']);
      expect(map['category'], '内装');
      expect(map['slots'], 5);
      expect(map['applicantCount'], 2);
      expect(map['status'], 'published');
      expect(map['customInspectionItems'], ['品質確認']);
      expect(map['updatedAt'], isA<FieldValue>());
      // idとcreatedAtはtoMapに含まれない
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('createdAt'), isFalse);
    });

    test('nullのオプショナルフィールドはMapに含まれない', () {
      final job = JobModel(
        id: 'job-min',
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
      expect(map.containsKey('latitude'), isFalse);
      expect(map.containsKey('longitude'), isFalse);
      expect(map.containsKey('requiredQualifications'), isFalse);
      expect(map.containsKey('imageUrl'), isFalse);
      expect(map.containsKey('imageUrls'), isFalse);
      expect(map.containsKey('category'), isFalse);
      expect(map.containsKey('slots'), isFalse);
      expect(map.containsKey('applicantCount'), isFalse);
      expect(map.containsKey('customInspectionItems'), isFalse);
      // 必須フィールドは含まれる
      expect(map.containsKey('title'), isTrue);
      expect(map.containsKey('status'), isTrue);
    });

    test('toCreateMapにcreatedAtが含まれる', () {
      final job = JobModel(
        id: 'job-001',
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

  group('ラウンドトリップ: fromMap → toMap → fromMap', () {
    test('主要フィールドがラウンドトリップで保持される', () {
      final originalData = TestFixtures.jobData();
      originalData['imageUrl'] = 'https://example.com/img.jpg';
      originalData['imageUrls'] = [
        'https://example.com/img1.jpg',
        'https://example.com/img2.jpg',
      ];
      originalData['category'] = '内装';
      originalData['slots'] = 5;
      originalData['applicantCount'] = 2;
      originalData['status'] = 'published';
      originalData['requiredQualifications'] = ['interior', 'scaffolding'];
      originalData['customInspectionItems'] = ['品質確認', '清掃確認'];

      // 1回目のfromMap
      final first = JobModel.fromMap('job-rt', originalData);
      // toMapでシリアライズ
      final map = first.toMap();
      // 2回目のfromMap（updatedAtはFieldValueなので除外して再構築）
      final reconstructedData = Map<String, dynamic>.from(map);
      reconstructedData.remove('updatedAt');
      final second = JobModel.fromMap('job-rt', reconstructedData);

      expect(second.title, first.title);
      expect(second.location, first.location);
      expect(second.prefecture, first.prefecture);
      expect(second.price, first.price);
      expect(second.date, first.date);
      expect(second.workMonthKey, first.workMonthKey);
      expect(second.ownerId, first.ownerId);
      expect(second.description, first.description);
      expect(second.latitude, first.latitude);
      expect(second.longitude, first.longitude);
      expect(second.requiredQualifications, first.requiredQualifications);
      expect(second.imageUrl, first.imageUrl);
      expect(second.imageUrls, first.imageUrls);
      expect(second.category, first.category);
      expect(second.slots, first.slots);
      expect(second.applicantCount, first.applicantCount);
      expect(second.status, first.status);
      expect(second.customInspectionItems, first.customInspectionItems);
    });

    test('最小データのラウンドトリップ', () {
      final first = JobModel.fromMap('job-min', <String, dynamic>{});
      final map = first.toMap();
      final reconstructedData = Map<String, dynamic>.from(map);
      reconstructedData.remove('updatedAt');
      final second = JobModel.fromMap('job-min', reconstructedData);

      expect(second.title, first.title);
      expect(second.location, first.location);
      expect(second.prefecture, first.prefecture);
      expect(second.price, first.price);
      expect(second.date, first.date);
      expect(second.status, first.status);
    });
  });
}
