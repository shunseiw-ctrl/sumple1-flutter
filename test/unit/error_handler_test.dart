import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/utils/error_handler.dart';

Widget _buildTestAppWithButton({
  required void Function(BuildContext) onPressed,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => onPressed(context),
          child: const Text('trigger'),
        ),
      ),
    ),
  );
}

void main() {
  // Note: FirebaseAuthException has a @protected constructor, so we cannot
  // instantiate it directly in tests. We test FirebaseException (which
  // FirebaseAuthException extends) and other error types instead.
  // The FirebaseAuth error codes would be tested via integration tests.

  group('showError with FirebaseException', () {
    testWidgets('permission-denied shows correct message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(
            context,
            FirebaseException(plugin: 'firestore', code: 'permission-denied'),
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('権限がありません'), findsOneWidget);
    });

    testWidgets('not-found shows correct message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(
            context,
            FirebaseException(plugin: 'firestore', code: 'not-found'),
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('データが見つかりません'), findsOneWidget);
    });

    testWidgets('already-exists shows correct message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(
            context,
            FirebaseException(plugin: 'firestore', code: 'already-exists'),
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('データが既に存在します'), findsOneWidget);
    });

    testWidgets('cancelled shows correct message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(
            context,
            FirebaseException(plugin: 'firestore', code: 'cancelled'),
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('操作がキャンセルされました'), findsOneWidget);
    });

    testWidgets('deadline-exceeded shows correct message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(
            context,
            FirebaseException(plugin: 'firestore', code: 'deadline-exceeded'),
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('タイムアウトしました'), findsOneWidget);
    });

    testWidgets('unauthenticated shows correct message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(
            context,
            FirebaseException(plugin: 'firestore', code: 'unauthenticated'),
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('認証されていません'), findsOneWidget);
    });

    testWidgets('unavailable shows correct message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(
            context,
            FirebaseException(plugin: 'firestore', code: 'unavailable'),
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('サービスが利用できません'), findsOneWidget);
    });

    testWidgets('network-request-failed shows correct message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(
            context,
            FirebaseException(plugin: 'firestore', code: 'network-request-failed'),
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('ネットワークエラーが発生しました'), findsOneWidget);
    });

    testWidgets('unknown code shows generic message with code', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(
            context,
            FirebaseException(plugin: 'firestore', code: 'some-random-code'),
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('エラーが発生しました: some-random-code'), findsOneWidget);
    });
  });

  group('showError with String error', () {
    testWidgets('displays the string directly', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(context, 'カスタムエラーメッセージ');
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('カスタムエラーメッセージ'), findsOneWidget);
    });
  });

  group('showError with unknown error type', () {
    testWidgets('displays generic message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(context, 12345);
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('エラーが発生しました。しばらく経ってからお試しください'), findsOneWidget);
    });
  });

  group('showError with customMessage', () {
    testWidgets('uses custom message instead of error message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showError(
            context,
            Exception('some error'),
            customMessage: 'カスタムメッセージ',
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('カスタムメッセージ'), findsOneWidget);
    });
  });

  group('showSuccess', () {
    testWidgets('shows green snackbar with message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showSuccess(context, '保存しました');
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('保存しました'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.green.shade700);
    });
  });

  group('showInfo', () {
    testWidgets('shows blue snackbar with message', (tester) async {
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) {
          ErrorHandler.showInfo(context, '情報メッセージ');
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('情報メッセージ'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.blue.shade700);
    });
  });

  group('showConfirmDialog', () {
    testWidgets('returns true on confirm', (tester) async {
      bool? result;
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) async {
          result = await ErrorHandler.showConfirmDialog(
            context,
            title: '確認',
            message: '削除しますか？',
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      expect(find.text('確認'), findsOneWidget);
      expect(find.text('削除しますか？'), findsOneWidget);

      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('returns false on cancel', (tester) async {
      bool? result;
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) async {
          result = await ErrorHandler.showConfirmDialog(
            context,
            title: '確認',
            message: '削除しますか？',
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('いいえ'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('returns false when dialog is dismissed', (tester) async {
      bool? result;
      await tester.pumpWidget(_buildTestAppWithButton(
        onPressed: (context) async {
          result = await ErrorHandler.showConfirmDialog(
            context,
            title: '確認',
            message: 'テスト',
          );
        },
      ));

      await tester.tap(find.text('trigger'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
