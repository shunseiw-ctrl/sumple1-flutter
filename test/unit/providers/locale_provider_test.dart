import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumple1/core/providers/locale_provider.dart';

void main() {
  group('LocaleNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('初期値がjaである', () {
      final notifier = LocaleNotifier();
      expect(notifier.state, const Locale('ja'));
    });

    test('setLocaleでenに変更できる', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = LocaleNotifier();
      await notifier.setLocale(const Locale('en'));
      expect(notifier.state, const Locale('en'));
    });

    test('SharedPreferencesに永続化される', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = LocaleNotifier();
      await notifier.setLocale(const Locale('en'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), 'en');
    });

    test('アプリ再起動後に復元される', () async {
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      final notifier = LocaleNotifier();
      // _loadが非同期で実行されるため少し待つ
      await Future.delayed(const Duration(milliseconds: 100));
      expect(notifier.state, const Locale('en'));
    });
  });
}
