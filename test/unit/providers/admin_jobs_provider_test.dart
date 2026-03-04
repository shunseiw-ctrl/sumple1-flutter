import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_jobs_provider.dart';
import 'package:sumple1/core/providers/admin_list_state.dart';

void main() {
  group('JobItem', () {
    test('デフォルト値が正しく設定される', () {
      const item = JobItem(
        id: 'job1',
        title: '内装工事A',
        location: '新宿区',
        price: 15000,
        date: '2025/03/15',
        status: 'active',
      );

      expect(item.id, 'job1');
      expect(item.title, '内装工事A');
      expect(item.location, '新宿区');
      expect(item.price, 15000);
      expect(item.date, '2025/03/15');
      expect(item.status, 'active');
      expect(item.applicantCount, 0);
      expect(item.slots, isNull);
      expect(item.createdAt, isNull);
    });

    test('全フィールドが正しく設定される', () {
      final now = DateTime.now();
      final item = JobItem(
        id: 'job2',
        title: '塗装工事B',
        location: '渋谷区',
        price: 20000,
        date: '2025/04/01',
        status: 'completed',
        applicantCount: 5,
        slots: 3,
        createdAt: now,
      );

      expect(item.applicantCount, 5);
      expect(item.slots, 3);
      expect(item.createdAt, now);
    });
  });

  group('AdminListState<JobItem>', () {
    test('デフォルト状態が正しい', () {
      const state = AdminListState<JobItem>();
      expect(state.items, isEmpty);
      expect(state.hasMore, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.searchQuery, '');
      expect(state.filterStatus, 'all');
    });

    test('フィルター変更でcopyWithが正しく動作する', () {
      const state = AdminListState<JobItem>();
      final updated = state.copyWith(filterStatus: 'active');
      expect(updated.filterStatus, 'active');
      expect(updated.items, isEmpty);
    });

    test('検索クエリでfilteredItemsが正しくフィルタリングされる', () {
      final items = [
        const JobItem(
          id: '1',
          title: '内装工事A',
          location: '新宿区',
          price: 15000,
          date: '',
          status: 'active',
        ),
        const JobItem(
          id: '2',
          title: '塗装工事B',
          location: '渋谷区',
          price: 20000,
          date: '',
          status: 'completed',
        ),
      ];

      var state = AdminListState<JobItem>(items: items);
      state = state.copyWith(searchQuery: '内装');

      final filtered = state.filteredItems(
        (item, query) => item.title.toLowerCase().contains(query.toLowerCase()),
      );
      expect(filtered.length, 1);
      expect(filtered.first.title, '内装工事A');
    });

    test('ページネーション状態が正しく更新される', () {
      final items = List.generate(
        20,
        (i) => JobItem(
          id: 'job$i',
          title: '案件$i',
          location: '',
          price: 10000,
          date: '',
          status: 'active',
        ),
      );

      final state = AdminListState<JobItem>(
        items: items,
        hasMore: true,
        isLoadingMore: false,
      );

      final loading = state.copyWith(isLoadingMore: true);
      expect(loading.isLoadingMore, isTrue);
      expect(loading.items.length, 20);

      final noMore = state.copyWith(hasMore: false);
      expect(noMore.hasMore, isFalse);
    });
  });
}
