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
            body: StatusBadge(
              label: 'ラベルのみ',
              color: Colors.grey,
            ),
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
        theme: ThemeData(
          extensions: const [AppColorsExtension.light],
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
    testWidgets('returns correct colors for known statuses', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColorsExtension.light],
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

      expect(StatusBadge.colorFor(capturedContext, 'applied'), AppColorsExtension.light.warning);
      expect(StatusBadge.colorFor(capturedContext, 'in_progress'), AppColorsExtension.light.primary);
      expect(StatusBadge.colorFor(capturedContext, 'done'), AppColorsExtension.light.success);
      expect(StatusBadge.colorFor(capturedContext, 'fixing'), AppColorsExtension.light.error);
    });

    testWidgets('returns textSecondary for unknown status', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColorsExtension.light],
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

      expect(StatusBadge.colorFor(capturedContext, 'unknown'), AppColorsExtension.light.textSecondary);
    });
  });
}
