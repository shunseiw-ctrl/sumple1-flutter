import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_list_state.dart';

void main() {
  group('AdminListState', () {
    test('デフォルト値確認', () {
      const state = AdminListState<String>();

      expect(state.items, isEmpty);
      expect(state.hasMore, true);
      expect(state.isLoadingMore, false);
      expect(state.searchQuery, '');
      expect(state.filterStatus, 'all');
      expect(state.lastDocument, null);
    });

    test('copyWith全フィールド', () {
      const state = AdminListState<String>(
        items: ['a', 'b'],
        hasMore: true,
        isLoadingMore: false,
        searchQuery: '',
        filterStatus: 'all',
      );

      final updated = state.copyWith(
        items: ['c'],
        hasMore: false,
        isLoadingMore: true,
        searchQuery: 'test',
        filterStatus: 'applied',
      );

      expect(updated.items, ['c']);
      expect(updated.hasMore, false);
      expect(updated.isLoadingMore, true);
      expect(updated.searchQuery, 'test');
      expect(updated.filterStatus, 'applied');
    });

    test('copyWithで一部だけ変更', () {
      const state = AdminListState<String>(
        items: ['a'],
        filterStatus: 'all',
        searchQuery: 'hello',
      );

      final updated = state.copyWith(filterStatus: 'done');

      expect(updated.items, ['a']);
      expect(updated.filterStatus, 'done');
      expect(updated.searchQuery, 'hello');
    });

    test('clearLastDocument', () {
      const state = AdminListState<String>();
      final updated = state.copyWith(clearLastDocument: true);
      expect(updated.lastDocument, null);
    });

    test('filteredItemsでフィルタリング', () {
      const state = AdminListState<String>(
        items: ['apple', 'banana', 'avocado'],
        searchQuery: 'a',
      );

      final filtered = state.filteredItems(
        (item, query) => item.contains(query),
      );

      expect(filtered, ['apple', 'banana', 'avocado']);
    });

    test('searchQueryが空ならフィルタなし', () {
      const state = AdminListState<String>(
        items: ['apple', 'banana'],
        searchQuery: '',
      );

      final filtered = state.filteredItems(
        (item, query) => item.contains(query),
      );

      expect(filtered, ['apple', 'banana']);
    });
  });
}
