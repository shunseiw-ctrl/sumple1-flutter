import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';

Widget _wrapWithLocalization(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: const [AppColorsExtension.light]),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ja'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('ErrorRetryWidget', () {
    testWidgets('デフォルトでエラーメッセージと再試行ボタンを表示', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          ErrorRetryWidget(
            title: 'テストエラー',
            message: 'エラーの詳細',
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('テストエラー'), findsOneWidget);
      expect(find.text('エラーの詳細'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('再試行ボタンのタップでコールバックが呼ばれる', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        _wrapWithLocalization(
          ErrorRetryWidget(
            title: 'エラー',
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    testWidgets('network factoryでネットワークエラー表示', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          ErrorRetryWidget.network(onRetry: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ネットワークエラー'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('timeout factoryでタイムアウト表示', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          ErrorRetryWidget.timeout(onRetry: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('タイムアウト'), findsOneWidget);
      expect(find.byIcon(Icons.timer_off_rounded), findsOneWidget);
    });

    testWidgets('general factoryでエラー表示', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          ErrorRetryWidget.general(onRetry: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('エラーが発生しました'), findsOneWidget);
    });

    testWidgets('empty factoryで検索結果なし表示', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          ErrorRetryWidget.empty(onRetry: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('データが見つかりません'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('compact modeでサイズが小さい', (tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          ErrorRetryWidget(
            title: 'エラー',
            onRetry: () {},
            isCompact: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('エラー'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });
  });
}
