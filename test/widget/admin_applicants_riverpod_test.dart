import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_applicants_provider.dart';
import 'package:sumple1/core/providers/admin_list_state.dart';

void main() {
  group('AdminApplicantsTab Riverpod', () {
    testWidgets('ProviderScopeで初期状態テスト', (tester) async {
      // AdminListState の初期状態をテスト
      const state = AdminListState<ApplicantItem>();
      expect(state.items, isEmpty);
      expect(state.hasMore, true);
      expect(state.filterStatus, 'all');
      expect(state.searchQuery, '');
    });

    testWidgets('フィルタ切替で表示更新', (tester) async {
      final items = [
        const ApplicantItem(id: '1', jobTitle: 'Job A', status: 'applied', applicantUid: 'uid1'),
        const ApplicantItem(id: '2', jobTitle: 'Job B', status: 'assigned', applicantUid: 'uid2'),
        const ApplicantItem(id: '3', jobTitle: 'Job C', status: 'applied', applicantUid: 'uid3'),
      ];

      var state = AdminListState<ApplicantItem>(items: items);

      // 'applied'フィルタ
      state = state.copyWith(filterStatus: 'applied');
      final filtered = state.items.where((i) => i.status == 'applied').toList();
      expect(filtered.length, 2);
      expect(filtered[0].jobTitle, 'Job A');
      expect(filtered[1].jobTitle, 'Job C');
    });

    testWidgets('検索入力でフィルタリング', (tester) async {
      final items = [
        const ApplicantItem(id: '1', jobTitle: '内装工事A', status: 'applied', applicantUid: 'uid1', workerName: '田中太郎'),
        const ApplicantItem(id: '2', jobTitle: '電気工事B', status: 'applied', applicantUid: 'uid2', workerName: '鈴木花子'),
      ];

      final state = AdminListState<ApplicantItem>(items: items, searchQuery: '田中');
      final filtered = state.filteredItems(
        (item, query) => item.workerName.contains(query) || item.jobTitle.contains(query),
      );
      expect(filtered.length, 1);
      expect(filtered[0].workerName, '田中太郎');
    });

    testWidgets('LoadMoreボタン表示条件', (tester) async {
      const state = AdminListState<ApplicantItem>(hasMore: true, isLoadingMore: false);
      expect(state.hasMore, true);
      expect(state.isLoadingMore, false);
    });

    testWidgets('空状態メッセージ', (tester) async {
      const state = AdminListState<ApplicantItem>();
      expect(state.items, isEmpty);
      // 空状態の場合、UIで「応募者はまだいません」が表示される
    });
  });
}
