import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/job_model.dart';

void main() {
  group('JobModel imageUrls', () {
    test('imageUrlsが空の場合、空リストが返る', () {
      final model = JobModel.fromMap('test-id', {
        'title': 'テスト案件',
        'location': '東京都',
        'prefecture': '東京都',
        'price': 15000,
        'date': '2025-04-01',
      });
      expect(model.imageUrls, isEmpty);
      expect(model.imageUrl, isNull);
    });

    test('imageUrlのみ設定時、imageUrlsにフォールバック', () {
      final model = JobModel.fromMap('test-id', {
        'title': 'テスト案件',
        'location': '東京都',
        'prefecture': '東京都',
        'price': 15000,
        'date': '2025-04-01',
        'imageUrl': 'https://example.com/img1.jpg',
      });
      expect(model.imageUrls, ['https://example.com/img1.jpg']);
      expect(model.imageUrl, 'https://example.com/img1.jpg');
    });

    test('imageUrls複数指定時、そのまま使用', () {
      final urls = [
        'https://example.com/img1.jpg',
        'https://example.com/img2.jpg',
        'https://example.com/img3.jpg',
      ];
      final model = JobModel.fromMap('test-id', {
        'title': 'テスト案件',
        'location': '東京都',
        'prefecture': '東京都',
        'price': 15000,
        'date': '2025-04-01',
        'imageUrls': urls,
      });
      expect(model.imageUrls, urls);
    });

    test('imageUrlsが空リストでimageUrlあり時、imageUrlにフォールバック', () {
      final model = JobModel.fromMap('test-id', {
        'title': 'テスト案件',
        'location': '東京都',
        'prefecture': '東京都',
        'price': 15000,
        'date': '2025-04-01',
        'imageUrls': <String>[],
        'imageUrl': 'https://example.com/fallback.jpg',
      });
      expect(model.imageUrls, ['https://example.com/fallback.jpg']);
    });

    test('imageUrlsとimageUrl両方設定時、imageUrlsが優先', () {
      final model = JobModel.fromMap('test-id', {
        'title': 'テスト案件',
        'location': '東京都',
        'prefecture': '東京都',
        'price': 15000,
        'date': '2025-04-01',
        'imageUrl': 'https://example.com/single.jpg',
        'imageUrls': ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
      });
      expect(model.imageUrls, ['https://example.com/a.jpg', 'https://example.com/b.jpg']);
    });

    test('新フィールド（category/slots/applicantCount）がパースされる', () {
      final model = JobModel.fromMap('test-id', {
        'title': 'テスト案件',
        'location': '東京都',
        'prefecture': '東京都',
        'price': 15000,
        'date': '2025-04-01',
        'category': '内装',
        'slots': 3,
        'applicantCount': 5,
      });
      expect(model.category, '内装');
      expect(model.slots, 3);
      expect(model.applicantCount, 5);
    });
  });

  group('JobModel toMap imageUrls', () {
    test('imageUrlsが空の場合、toMapに含まれない', () {
      final model = JobModel(
        id: 'test',
        title: 'テスト',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-04-01',
      );
      final map = model.toMap();
      expect(map.containsKey('imageUrls'), isFalse);
    });

    test('imageUrlsがある場合、toMapに含まれる', () {
      final model = JobModel(
        id: 'test',
        title: 'テスト',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-04-01',
        imageUrls: ['https://example.com/img.jpg'],
      );
      final map = model.toMap();
      expect(map['imageUrls'], ['https://example.com/img.jpg']);
    });
  });

  group('JobModel copyWith', () {
    test('imageUrlsをcopyWithで変更できる', () {
      final original = JobModel(
        id: 'test',
        title: 'テスト',
        location: '東京',
        prefecture: '東京都',
        price: 10000,
        date: '2025-04-01',
      );
      final copied = original.copyWith(
        imageUrls: ['https://example.com/new.jpg'],
      );
      expect(copied.imageUrls, ['https://example.com/new.jpg']);
      expect(original.imageUrls, isEmpty);
    });
  });
}
