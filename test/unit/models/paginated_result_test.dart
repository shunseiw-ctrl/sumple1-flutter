import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/paginated_result.dart';

void main() {
  group('PaginatedResult', () {
    test('creates with required parameters', () {
      final result = const PaginatedResult<String>(items: ['a', 'b']);

      expect(result.items, ['a', 'b']);
      expect(result.lastDocument, isNull);
      expect(result.hasMore, isFalse);
    });

    test('creates with hasMore true', () {
      final result = const PaginatedResult<int>(items: [1, 2, 3], hasMore: true);

      expect(result.items.length, 3);
      expect(result.hasMore, isTrue);
    });

    test('creates with empty items', () {
      final result = const PaginatedResult<String>(items: []);

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
    });

    group('equality', () {
      test('同一フィールドのオブジェクトは等しい', () {
        final result1 = const PaginatedResult<String>(
          items: ['a', 'b', 'c'],
          hasMore: true,
        );
        final result2 = const PaginatedResult<String>(
          items: ['a', 'b', 'c'],
          hasMore: true,
        );

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('異なるフィールドのオブジェクトは等しくない', () {
        final result1 = const PaginatedResult<String>(
          items: ['a', 'b'],
          hasMore: true,
        );
        final result2 = const PaginatedResult<String>(
          items: ['c', 'd'],
          hasMore: false,
        );

        expect(result1, isNot(equals(result2)));
      });
    });

    test('preserves generic type', () {
      final result = const PaginatedResult<Map<String, dynamic>>(
        items: [
          {'key': 'value'},
        ],
        hasMore: false,
      );

      expect(result.items.first, isA<Map<String, dynamic>>());
      expect(result.items.first['key'], 'value');
    });
  });
}
