import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/admin_active_workers_provider.dart';

void main() {
  group('ActiveWorkerItem', () {
    test('コンストラクタ_必須フィールド', () {
      const item = ActiveWorkerItem(
        uid: 'worker-1',
        name: 'テスト太郎',
        activeJobCount: 3,
      );

      expect(item.uid, 'worker-1');
      expect(item.name, 'テスト太郎');
      expect(item.activeJobCount, 3);
      expect(item.latestJobTitle, '');
      expect(item.status, '');
      expect(item.qualityScore, 0);
    });

    test('全フィールド指定', () {
      const item = ActiveWorkerItem(
        uid: 'worker-2',
        name: '山田花子',
        activeJobCount: 2,
        latestJobTitle: '内装工事A',
        status: 'in_progress',
        qualityScore: 4.5,
      );

      expect(item.latestJobTitle, '内装工事A');
      expect(item.status, 'in_progress');
      expect(item.qualityScore, 4.5);
    });

    test('activeJobCount_0件', () {
      const item = ActiveWorkerItem(
        uid: 'worker-3',
        name: '佐藤一郎',
        activeJobCount: 0,
      );

      expect(item.activeJobCount, 0);
    });
  });
}
