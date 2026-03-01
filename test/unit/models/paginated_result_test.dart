import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/data/models/paginated_result.dart';

void main() {
  group('PaginatedResult', () {
    test('creates with required parameters', () {
      final result = PaginatedResult<String>(items: ['a', 'b']);

      expect(result.items, ['a', 'b']);
      expect(result.lastDocument, isNull);
      expect(result.hasMore, isFalse);
    });

    test('creates with hasMore true', () {
      final result = PaginatedResult<int>(items: [1, 2, 3], hasMore: true);

      expect(result.items.length, 3);
      expect(result.hasMore, isTrue);
    });

    test('creates with empty items', () {
      final result = PaginatedResult<String>(items: []);

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
    });

    test('preserves generic type', () {
      final result = PaginatedResult<Map<String, dynamic>>(
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
