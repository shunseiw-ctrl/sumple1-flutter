import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/utils/job_date_utils.dart';

void main() {
  group('dateKey', () {
    test('formats date as YYYY-MM-DD', () {
      expect(dateKey(DateTime(2026, 3, 2)), '2026-03-02');
      expect(dateKey(DateTime(2025, 12, 25)), '2025-12-25');
      expect(dateKey(DateTime(2026, 1, 1)), '2026-01-01');
    });
  });

  group('monthKeyFromDateKey', () {
    test('extracts YYYY-MM from date key', () {
      expect(monthKeyFromDateKey('2026-03-02'), '2026-03');
      expect(monthKeyFromDateKey('2025-12-25'), '2025-12');
    });

    test('returns empty string for short input', () {
      expect(monthKeyFromDateKey('short'), '');
      expect(monthKeyFromDateKey(''), '');
    });
  });
}
