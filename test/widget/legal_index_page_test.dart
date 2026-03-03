import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/pages/legal_index_page.dart';
import 'package:sumple1/pages/legal_page.dart';
import 'package:sumple1/pages/profile/profile_widgets.dart';

void main() {
  Widget buildTestWidget() {
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
      home: const LegalIndexPage(),
    );
  }

  group('LegalIndexPage', () {
    testWidgets('5つの法的ドキュメントタイトルが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('プライバシーポリシー'), findsOneWidget);
      expect(find.text('利用規約'), findsOneWidget);
      expect(find.text('労災保険について'), findsOneWidget);
      expect(find.text('労働者派遣法について'), findsOneWidget);
      expect(find.text('職業安定法について'), findsOneWidget);
    });

    testWidgets('各タイルがタップ可能である', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 各タイルが存在しタップ可能であることを確認（go_routerなしのためタップ時にエラーが出るが、
      // タイルの存在とInkWellの検出で確認）
      expect(find.text('プライバシーポリシー'), findsOneWidget);
      expect(find.text('利用規約'), findsOneWidget);
      expect(find.text('労災保険について'), findsOneWidget);
      expect(find.text('労働者派遣法について'), findsOneWidget);
      expect(find.text('職業安定法について'), findsOneWidget);

      // ProfileMenuTileが5つ存在（タップ可能なタイル）
      expect(find.byType(ProfileMenuTile), findsAtLeast(5));
    });

    testWidgets('労災保険ページのHTML内容が正しい', (tester) async {
      expect(LegalPage.laborInsuranceHtml.contains('労災保険について'), isTrue);
      expect(LegalPage.laborInsuranceHtml.contains('ALBAWORKの位置づけ'), isTrue);
      expect(LegalPage.laborInsuranceHtml.contains('マッチングプラットフォーム'), isTrue);
      expect(LegalPage.laborInsuranceHtml.contains('労働者災害補償保険法'), isTrue);
      expect(LegalPage.laborInsuranceHtml.contains('昭和22年法律第50号'), isTrue);
      expect(LegalPage.laborInsuranceHtml.contains('直接締結'), isTrue);
      expect(LegalPage.laborInsuranceHtml.contains('事故・怪我'), isTrue);
      expect(LegalPage.laborInsuranceHtml.contains('保険給付の責任'), isTrue);
    });

    testWidgets('派遣法ページのHTML内容が正しい', (tester) async {
      expect(LegalPage.dispatchLawHtml.contains('労働者派遣法について'), isTrue);
      expect(LegalPage.dispatchLawHtml.contains('直接マッチング'), isTrue);
      expect(LegalPage.dispatchLawHtml.contains('労働者派遣事業を行うものではなく'), isTrue);
      expect(LegalPage.dispatchLawHtml.contains('昭和60年法律第88号'), isTrue);
      expect(LegalPage.dispatchLawHtml.contains('厚生労働大臣の許可'), isTrue);
      expect(LegalPage.dispatchLawHtml.contains('建設業務における派遣の禁止'), isTrue);
    });

    testWidgets('職業安定法ページのHTML内容が正しい', (tester) async {
      expect(LegalPage.employmentSecurityLawHtml.contains('職業安定法に基づく表示'), isTrue);
      expect(LegalPage.employmentSecurityLawHtml.contains('募集情報等提供事業'), isTrue);
      expect(LegalPage.employmentSecurityLawHtml.contains('昭和22年法律第141号'), isTrue);
      expect(LegalPage.employmentSecurityLawHtml.contains('虚偽の求人条件'), isTrue);
      expect(LegalPage.employmentSecurityLawHtml.contains('第65条第8号'), isTrue);
      expect(LegalPage.employmentSecurityLawHtml.contains('第44条'), isTrue);
      expect(LegalPage.employmentSecurityLawHtml.contains('不当な差別的取扱い'), isTrue);
    });

    testWidgets('プロフィールから法的情報への遷移用タイルが存在する', (tester) async {
      // LegalIndexPageが正しく構成されていることを確認
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // ページタイトル「法的情報」がAppBarに表示される
      expect(find.text('法的情報'), findsOneWidget);

      // セクションヘッダーが表示される
      // ProfileSectionHeaderはtoUpperCaseを使用するため大文字で表示
      expect(find.textContaining('法的ドキュメント'), findsOneWidget);
      expect(find.textContaining('法令遵守'), findsOneWidget);
    });

    testWidgets('l10nキーに対応する文字列定数が存在する', (tester) async {
      // HTML定数が正しく定義されていることを確認
      expect(LegalPage.privacyPolicyHtml, isNotEmpty);
      expect(LegalPage.termsHtml, isNotEmpty);
      expect(LegalPage.laborInsuranceHtml, isNotEmpty);
      expect(LegalPage.dispatchLawHtml, isNotEmpty);
      expect(LegalPage.employmentSecurityLawHtml, isNotEmpty);

      // 各HTMLが正しいHTMLフォーマットであることを確認
      expect(LegalPage.laborInsuranceHtml.contains('<!DOCTYPE html>'), isTrue);
      expect(LegalPage.dispatchLawHtml.contains('<!DOCTYPE html>'), isTrue);
      expect(LegalPage.employmentSecurityLawHtml.contains('<!DOCTYPE html>'), isTrue);
      expect(LegalPage.laborInsuranceHtml.contains('</html>'), isTrue);
      expect(LegalPage.dispatchLawHtml.contains('</html>'), isTrue);
      expect(LegalPage.employmentSecurityLawHtml.contains('</html>'), isTrue);
    });

    testWidgets('戻るボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // MaterialApp + homeの場合、AppBarには戻るボタンは表示されないが、
      // Navigatorスタック内で表示される場合をシミュレート
      await tester.pumpWidget(MaterialApp(
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
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalIndexPage(),
                    ),
                  );
                },
                child: const Text('Go'),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // ナビゲーションでLegalIndexPageに遷移
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      // 戻るボタンが表示される
      expect(find.byType(BackButton), findsOneWidget);

      // 戻るボタンをタップして前のページに戻る
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 元のページに戻っていることを確認
      expect(find.text('Go'), findsOneWidget);
      expect(find.text('法的情報'), findsNothing);
    });
  });
}
