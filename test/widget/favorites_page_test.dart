import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/l10n/app_localizations.dart';
import 'package:sumple1/pages/favorites_page.dart';

void main() {
  group('FavoritesPage（実ページ）', () {
    testWidgets('未ログイン→ログイン必要メッセージ', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth(signedIn: false);

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
        home: FavoritesPage(
          firestore: fakeFirestore,
          firebaseAuth: mockAuth,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('お気に入り案件'), findsAtLeastNWidgets(1));
      expect(find.text('ログインが必要です'), findsOneWidget);
    });

    testWidgets('お気に入り0件→空状態表示', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockUser = MockUser(uid: 'fav_test_user', isAnonymous: false);
      final mockAuth =
          MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await fakeFirestore.collection('favorites').doc('fav_test_user').set({
        'jobIds': <String>[],
      });

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
        home: FavoritesPage(
          firestore: fakeFirestore,
          firebaseAuth: mockAuth,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('お気に入りはまだありません'), findsAtLeastNWidgets(1));
    });

    testWidgets('お気に入りあり→カード一覧表示', (tester) async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockUser = MockUser(uid: 'fav_test_user2', isAnonymous: false);
      final mockAuth =
          MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await fakeFirestore
          .collection('favorites')
          .doc('fav_test_user2')
          .set({
        'jobIds': ['job1', 'job2'],
      });

      await fakeFirestore.collection('jobs').doc('job1').set({
        'title': '内装工事A',
        'location': '東京都新宿区',
        'price': '15,000',
        'date': '2025-04-01',
        'imageUrl': '',
      });
      await fakeFirestore.collection('jobs').doc('job2').set({
        'title': '外壁塗装B',
        'location': '大阪府大阪市',
        'price': '20,000',
        'date': '2025-04-15',
        'imageUrl': '',
      });

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
        home: FavoritesPage(
          firestore: fakeFirestore,
          firebaseAuth: mockAuth,
        ),
      ));

      // StreamBuilder needs pump, then _fetchJobs via addPostFrameCallback
      await tester.pumpAndSettle();

      expect(find.text('お気に入り案件'), findsAtLeastNWidgets(1));
      expect(find.text('内装工事A'), findsOneWidget);
      expect(find.text('外壁塗装B'), findsOneWidget);
    });
  });
}
