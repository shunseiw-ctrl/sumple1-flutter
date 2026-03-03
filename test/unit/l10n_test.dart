import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sumple1/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    testWidgets('Japanese locale loads correctly', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
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
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.appName, equals('ALBAWORK'));
    });

    testWidgets('Common button labels are defined', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
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
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.cancel, equals('キャンセル'));
      expect(l10n.save, equals('保存'));
      expect(l10n.delete, equals('削除'));
      expect(l10n.confirm, equals('確認'));
      expect(l10n.close, equals('閉じる'));
    });

    testWidgets('Navigation labels are defined', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
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
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.navHome, equals('ホーム'));
      expect(l10n.navWork, equals('仕事'));
      expect(l10n.navMessages, equals('メッセージ'));
      expect(l10n.navSales, equals('売上'));
      expect(l10n.navProfile, equals('プロフィール'));
    });

    testWidgets('Auth-related keys are defined', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
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
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.signInWithApple, equals('Appleでサインイン'));
      expect(l10n.signInWithLine, equals('LINEでログイン'));
      expect(l10n.signInWithEmail, equals('メールアドレスでログイン'));
      expect(l10n.startAsGuest, equals('ゲストとして始める'));
      expect(l10n.login, equals('ログイン'));
      expect(l10n.register, equals('新規登録'));
      expect(l10n.forgotPassword, equals('パスワードを忘れた方'));
    });

    testWidgets('Job-related keys are defined', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
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
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.jobDetail, equals('案件詳細'));
      expect(l10n.jobTitle, equals('案件名'));
      expect(l10n.jobLocation, equals('勤務地'));
      expect(l10n.jobDate, equals('勤務日'));
      expect(l10n.jobPrice, equals('報酬'));
      expect(l10n.applyForJob, equals('この案件に応募する'));
    });

    testWidgets('Profile keys are defined', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
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
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.myProfile, equals('プロフィール'));
      expect(l10n.editProfile, equals('プロフィール編集'));
      expect(l10n.familyName, equals('姓'));
      expect(l10n.givenName, equals('名'));
      expect(l10n.phone, equals('電話番号'));
      expect(l10n.address, equals('住所'));
    });

    testWidgets('Parameterized message formats correctly', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
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
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.itemCount(5.toString()), equals('5件'));
      expect(l10n.unreadCount(3.toString()), equals('未読3件'));
    });
  });
}
