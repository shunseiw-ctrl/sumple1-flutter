import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_constants.dart';

void main() {
  group('起動最適化', () {
    test('_initializeFCM関数が存在（コード構造テスト）', () {
      // main.dartに_initializeFCMが定義されていることをソースコードから確認
      final mainFile = File('lib/main.dart');
      expect(mainFile.existsSync(), isTrue);
      final content = mainFile.readAsStringSync();
      expect(content.contains('Future<void> _initializeFCM()'), isTrue);
    });

    test('FirebaseMessaging.onBackgroundMessageがmain()レベルに残存', () {
      final mainFile = File('lib/main.dart');
      final content = mainFile.readAsStringSync();
      // onBackgroundMessageがmain()内にあることを確認
      expect(content.contains('FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler)'), isTrue);
      // _initializeFCM内ではなくmain内にあることを確認
      final mainFuncStart = content.indexOf('Future<void> main()');
      final initFcmStart = content.indexOf('Future<void> _initializeFCM()');
      final bgMessagePos = content.indexOf('FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler)');
      // onBackgroundMessageはmain関数の開始後、_initializeFCMの前にある
      expect(bgMessagePos, greaterThan(mainFuncStart));
      // _initializeFCMはmain関数の前に定義されているが、呼び出しはmain内
      expect(initFcmStart, lessThan(mainFuncStart));
    });

    test('AppConstants.firestoreCacheSizeBytesの型確認', () {
      expect(AppConstants.firestoreCacheSizeBytes, isA<int>());
      // 100MBであること
      expect(AppConstants.firestoreCacheSizeBytes, equals(104857600));
    });
  });
}
