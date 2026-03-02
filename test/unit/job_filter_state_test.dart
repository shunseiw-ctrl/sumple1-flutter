import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/pages/job_filter_sheet.dart';

void main() {
  group('JobFilterState', () {
    test('default state has no active filters', () {
      const state = JobFilterState();

      expect(state.priceRange, const RangeValues(0, 100000));
      expect(state.areaFilter, '');
      expect(state.qualFilter, isEmpty);
      expect(state.dateFromFilter, isNull);
      expect(state.dateToFilter, isNull);
      expect(state.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters returns true when any filter is set', () {
      // Area filter
      expect(
        const JobFilterState(areaFilter: '渋谷区').hasActiveFilters,
        isTrue,
      );

      // Qualification filter
      expect(
        const JobFilterState(qualFilter: {'足場組立'}).hasActiveFilters,
        isTrue,
      );

      // Date from filter
      expect(
        const JobFilterState(dateFromFilter: '2026-04-01').hasActiveFilters,
        isTrue,
      );

      // Date to filter
      expect(
        const JobFilterState(dateToFilter: '2026-05-01').hasActiveFilters,
        isTrue,
      );

      // Price range (start > 0)
      expect(
        const JobFilterState(priceRange: RangeValues(5000, 100000)).hasActiveFilters,
        isTrue,
      );

      // Price range (end < 100000)
      expect(
        const JobFilterState(priceRange: RangeValues(0, 50000)).hasActiveFilters,
        isTrue,
      );
    });

    test('reset returns default state', () {
      const state = JobFilterState(
        priceRange: RangeValues(10000, 50000),
        areaFilter: '渋谷区',
        qualFilter: {'足場組立', '玉掛け'},
        dateFromFilter: '2026-04-01',
        dateToFilter: '2026-05-01',
      );

      final resetState = state.reset();

      expect(resetState.priceRange, const RangeValues(0, 100000));
      expect(resetState.areaFilter, '');
      expect(resetState.qualFilter, isEmpty);
      expect(resetState.dateFromFilter, isNull);
      expect(resetState.dateToFilter, isNull);
      expect(resetState.hasActiveFilters, isFalse);
    });

    test('copyWith creates correct copy', () {
      const original = JobFilterState(
        areaFilter: '渋谷区',
        dateFromFilter: '2026-04-01',
      );

      final copy = original.copyWith(areaFilter: '横浜市');
      expect(copy.areaFilter, '横浜市');
      expect(copy.dateFromFilter, '2026-04-01'); // preserved

      final cleared = original.copyWith(clearDateFrom: true);
      expect(cleared.dateFromFilter, isNull);
      expect(cleared.areaFilter, '渋谷区'); // preserved
    });

    test('equality works correctly', () {
      const a = JobFilterState(areaFilter: '渋谷区', qualFilter: {'足場組立'});
      const b = JobFilterState(areaFilter: '渋谷区', qualFilter: {'足場組立'});
      const c = JobFilterState(areaFilter: '新宿区', qualFilter: {'足場組立'});

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('qualificationOptions', () {
    test('contains expected qualifications', () {
      expect(qualificationOptions, contains('足場組立'));
      expect(qualificationOptions, contains('玉掛け'));
      expect(qualificationOptions, contains('フォークリフト'));
      expect(qualificationOptions.length, 8);
    });
  });
}
