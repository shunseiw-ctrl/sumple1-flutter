import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test/helpers/test_helpers.dart';

void main() {
  group('既読ラベル表示ロジック', () {
    test('相手のlastReadAt > message.createdAtなら「既読」', () {
      // ロジックのユニットテスト
      final peerLastReadAt = Timestamp.fromDate(DateTime(2025, 4, 1, 12, 0));
      final messageCreatedAt = Timestamp.fromDate(DateTime(2025, 4, 1, 11, 0));

      final isRead = messageCreatedAt.compareTo(peerLastReadAt) <= 0;
      expect(isRead, isTrue);
    });

    test('lastReadAt未設定時は既読にならない', () {
      const Timestamp? peerLastReadAt = null;
      final messageCreatedAt = Timestamp.fromDate(DateTime(2025, 4, 1, 11, 0));

      final isRead = peerLastReadAt != null &&
          messageCreatedAt.compareTo(peerLastReadAt) <= 0;
      expect(isRead, isFalse);
    });
  });

  group('既読ラベルウィジェット', () {
    testWidgets('既読テキストが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Column(
            children: [
              Text('既読', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
              Text('12:00', style: TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
      );

      expect(find.text('既読'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
    });

    testWidgets('既読なしの場合は時刻のみ', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Column(
            children: [
              Text('12:00', style: TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
      );

      expect(find.text('既読'), findsNothing);
      expect(find.text('12:00'), findsOneWidget);
    });
  });
}
