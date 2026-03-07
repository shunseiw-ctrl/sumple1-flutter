import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/presentation/widgets/status_badge.dart';

void main() {
  group('StatusBadge constructor', () {
    testWidgets('renders label and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppColorsExtension.light]),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: const Scaffold(
            body: StatusBadge(
              label: 'テスト',
              color: Colors.blue,
              icon: Icons.check,
            ),
          ),
        ),
      );

      expect(find.text('テスト'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders without icon when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppColorsExtension.light]),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: const Scaffold(
            body: StatusBadge(label: 'ラベルのみ', color: Colors.grey),
          ),
        ),
      );

      expect(find.text('ラベルのみ'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('StatusBadge.fromStatus', () {
    Widget buildWithTheme(String statusKey) {
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
        home: Scaffold(
          body: Builder(
            builder: (context) => StatusBadge.fromStatus(context, statusKey),
          ),
        ),
      );
    }

    testWidgets('applied shows 応募中', (tester) async {
      await tester.pumpWidget(buildWithTheme('applied'));
      await tester.pumpAndSettle();

      expect(find.text('応募中'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('assigned shows 着工前', (tester) async {
      await tester.pumpWidget(buildWithTheme('assigned'));
      await tester.pumpAndSettle();

      expect(find.text('着工前'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_turned_in), findsOneWidget);
    });

    testWidgets('in_progress shows 着工中', (tester) async {
      await tester.pumpWidget(buildWithTheme('in_progress'));
      await tester.pumpAndSettle();

      expect(find.text('着工中'), findsOneWidget);
      expect(find.byIcon(Icons.engineering), findsOneWidget);
    });

    testWidgets('completed shows 施工完了', (tester) async {
      await tester.pumpWidget(buildWithTheme('completed'));
      await tester.pumpAndSettle();

      expect(find.text('施工完了'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('inspection shows 検収中', (tester) async {
      await tester.pumpWidget(buildWithTheme('inspection'));
      await tester.pumpAndSettle();

      expect(find.text('検収中'), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('fixing shows 是正中', (tester) async {
      await tester.pumpWidget(buildWithTheme('fixing'));
      await tester.pumpAndSettle();

      expect(find.text('是正中'), findsOneWidget);
      expect(find.byIcon(Icons.build), findsOneWidget);
    });

    testWidgets('done shows 完了', (tester) async {
      await tester.pumpWidget(buildWithTheme('done'));
      await tester.pumpAndSettle();

      expect(find.text('完了'), findsOneWidget);
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('unknown status shows the key as label', (tester) async {
      await tester.pumpWidget(buildWithTheme('custom_status'));
      await tester.pumpAndSettle();

      expect(find.text('custom_status'), findsOneWidget);
    });
  });

  group('StatusBadge.labelFor', () {
    test('returns English fallback labels without context', () {
      expect(StatusBadge.labelFor('applied'), 'Applied');
      expect(StatusBadge.labelFor('assigned'), 'Assigned');
      expect(StatusBadge.labelFor('in_progress'), 'In Progress');
      expect(StatusBadge.labelFor('completed'), 'Completed');
      expect(StatusBadge.labelFor('inspection'), 'Inspection');
      expect(StatusBadge.labelFor('fixing'), 'Fixing');
      expect(StatusBadge.labelFor('done'), 'Done');
    });

    test('returns key as-is for unknown status', () {
      expect(StatusBadge.labelFor('unknown'), 'unknown');
    });
  });

  group('StatusBadge.colorFor', () {
    testWidgets('returns correct colors for all known statuses', (
      tester,
    ) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppColorsExtension.light]),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      // 全7ステータスの色を検証
      expect(
        StatusBadge.colorFor(capturedContext, 'applied'),
        AppColorsExtension.light.warning,
      );
      expect(
        StatusBadge.colorFor(capturedContext, 'assigned'),
        AppColorsExtension.light.info,
      );
      expect(
        StatusBadge.colorFor(capturedContext, 'in_progress'),
        AppColorsExtension.light.primary,
      );
      expect(
        StatusBadge.colorFor(capturedContext, 'completed'),
        AppColorsExtension.light.success,
      );
      expect(
        StatusBadge.colorFor(capturedContext, 'inspection'),
        const Color(0xFF8B5CF6),
      );
      expect(
        StatusBadge.colorFor(capturedContext, 'fixing'),
        AppColorsExtension.light.error,
      );
      expect(
        StatusBadge.colorFor(capturedContext, 'done'),
        AppColorsExtension.light.success,
      );
    });

    testWidgets('returns textSecondary for unknown status', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppColorsExtension.light]),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        StatusBadge.colorFor(capturedContext, 'unknown'),
        AppColorsExtension.light.textSecondary,
      );
    });
  });

  group('StatusBadge filled プロパティ', () {
    testWidgets('filled=true のとき背景が塗りつぶし・テキストが白色', (tester) async {
      const testColor = Colors.blue;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppColorsExtension.light]),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: const Scaffold(
            body: StatusBadge(
              label: 'Filled',
              color: testColor,
              icon: Icons.star,
              filled: true,
            ),
          ),
        ),
      );

      // テキストが白色であることを検証
      final textWidget = tester.widget<Text>(find.text('Filled'));
      expect(textWidget.style?.color, Colors.white);

      // アイコンが白色であることを検証
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.color, Colors.white);

      // Containerの背景が塗りつぶしであることを検証
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, testColor);
      expect(decoration.border, isNull);
    });

    testWidgets('filled=false のとき背景が半透明・テキストがcolor色', (tester) async {
      const testColor = Colors.green;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppColorsExtension.light]),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: const Scaffold(
            body: StatusBadge(label: 'Outline', color: testColor),
          ),
        ),
      );

      // テキストがcolor色であることを検証
      final textWidget = tester.widget<Text>(find.text('Outline'));
      expect(textWidget.style?.color, testColor);

      // Containerの背景が半透明であることを検証
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNot(testColor));
      expect(decoration.border, isNotNull);
    });
  });

  group('StatusBadge.fromStatus filled ステータス', () {
    Widget buildWithTheme(String statusKey) {
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
        home: Scaffold(
          body: Builder(
            builder: (context) => StatusBadge.fromStatus(context, statusKey),
          ),
        ),
      );
    }

    testWidgets('in_progress は filled=true で表示される', (tester) async {
      await tester.pumpWidget(buildWithTheme('in_progress'));
      await tester.pumpAndSettle();

      // filled=true → テキストが白色
      final textWidget = tester.widget<Text>(find.text('着工中'));
      expect(textWidget.style?.color, Colors.white);
    });

    testWidgets('done は filled=true で表示される', (tester) async {
      await tester.pumpWidget(buildWithTheme('done'));
      await tester.pumpAndSettle();

      // filled=true → テキストが白色
      final textWidget = tester.widget<Text>(find.text('完了'));
      expect(textWidget.style?.color, Colors.white);
    });

    testWidgets('applied は filled=false で表示される', (tester) async {
      await tester.pumpWidget(buildWithTheme('applied'));
      await tester.pumpAndSettle();

      // filled=false → テキストが白色ではない
      final textWidget = tester.widget<Text>(find.text('応募中'));
      expect(textWidget.style?.color, isNot(Colors.white));
    });
  });

  group('StatusBadge ダークモード', () {
    testWidgets('ダークモードで正しい色が適用される', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: const [AppColorsExtension.dark],
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        StatusBadge.colorFor(capturedContext, 'applied'),
        AppColorsExtension.dark.warning,
      );
      expect(
        StatusBadge.colorFor(capturedContext, 'unknown'),
        AppColorsExtension.dark.textSecondary,
      );
    });

    testWidgets('ダークモードでfromStatusが正しくレンダリングされる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: const [AppColorsExtension.dark],
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Scaffold(
            body: Builder(
              builder: (context) => StatusBadge.fromStatus(context, 'done'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('完了'), findsOneWidget);
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });
  });
}
