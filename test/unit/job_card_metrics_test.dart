import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/presentation/widgets/job_card.dart';

void main() {
  group('JobCardMetrics', () {
    test('remaining slots計算（5-2=3）', () {
      final metrics = JobCardMetrics.fromData({
        'slots': '5',
        'applicantCount': '2',
        'date': '2099-12-31',
      });
      expect(metrics.remainingSlots, 3);
    });

    test('isUrgent: remaining <= 2 → true', () {
      final metrics = JobCardMetrics.fromData({
        'slots': '3',
        'applicantCount': '2',
        'date': '2099-12-31',
      });
      expect(metrics.remainingSlots, 1);
      expect(metrics.isUrgent, isTrue);
    });

    test('isUrgent: remaining > 2 → false', () {
      final metrics = JobCardMetrics.fromData({
        'slots': '10',
        'applicantCount': '2',
        'date': '2099-12-31',
      });
      expect(metrics.remainingSlots, 8);
      expect(metrics.isUrgent, isFalse);
    });

    test('showQuickStart: quickStart=true → true', () {
      final metrics = JobCardMetrics.fromData({
        'slots': '5',
        'applicantCount': '0',
        'date': '2099-12-31',
        'quickStart': true,
      });
      expect(metrics.showQuickStart, isTrue);
    });

    test('showQuickStart: 3日以内の日付 → true', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      final metrics = JobCardMetrics.fromData({
        'slots': '5',
        'applicantCount': '0',
        'date': dateStr,
        'quickStart': false,
      });
      expect(metrics.showQuickStart, isTrue);
    });

    test('showQuickStart: 遠い日付 + quickStart=false → false', () {
      final metrics = JobCardMetrics.fromData({
        'slots': '5',
        'applicantCount': '0',
        'date': '2099-12-31',
        'quickStart': false,
      });
      expect(metrics.showQuickStart, isFalse);
    });

    test('フィールド欠損時のデフォルト値', () {
      final metrics = JobCardMetrics.fromData({});
      expect(metrics.remainingSlots, 5); // default slots=5, applicants=0
      expect(metrics.isUrgent, isFalse);
      expect(metrics.showQuickStart, isFalse);
    });
  });
}
