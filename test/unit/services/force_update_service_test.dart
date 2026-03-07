import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/force_update_service.dart';

void main() {
  group('ForceUpdateService', () {
    group('isLessThan', () {
      test('マイナーバージョン比較_1.0.0と1.1.0_trueを返す', () {
        expect(ForceUpdateService.isLessThan('1.0.0', '1.1.0'), isTrue);
      });

      test('マイナーバージョン比較_1.2.0と1.1.9_falseを返す', () {
        expect(ForceUpdateService.isLessThan('1.2.0', '1.1.9'), isFalse);
      });

      test('同一バージョン_1.0.0と1.0.0_falseを返す', () {
        expect(ForceUpdateService.isLessThan('1.0.0', '1.0.0'), isFalse);
      });

      test('メジャーバージョン比較_0.9.9と1.0.0_trueを返す', () {
        expect(ForceUpdateService.isLessThan('0.9.9', '1.0.0'), isTrue);
      });

      test('メジャーバージョン比較_2.0.0と1.9.9_falseを返す', () {
        expect(ForceUpdateService.isLessThan('2.0.0', '1.9.9'), isFalse);
      });

      test('パッチバージョン比較_1.0.0と1.0.1_trueを返す', () {
        expect(ForceUpdateService.isLessThan('1.0.0', '1.0.1'), isTrue);
      });

      test('メジャーバージョン跨ぎ_1.9.9と2.0.0_trueを返す', () {
        expect(ForceUpdateService.isLessThan('1.9.9', '2.0.0'), isTrue);
      });

      test('短いバージョン文字列_1.0と1.0.1_trueを返す', () {
        expect(ForceUpdateService.isLessThan('1.0', '1.0.1'), isTrue);
      });
    });

    group('checkForUpdate', () {
      test('現在バージョンが最低バージョン以上_更新不要を返す', () async {
        final db = FakeFirebaseFirestore();
        await db.doc('app_config/version').set({
          'minVersion': '1.0.0',
          'recommendedVersion': '1.0.0',
        });
        final service = ForceUpdateService(db: db, currentVersion: '1.0.0');

        final result = await service.checkForUpdate();
        expect(result, ForceUpdateResult.upToDate);
      });

      test('現在バージョンが最低バージョンより大きい_更新不要を返す', () async {
        final db = FakeFirebaseFirestore();
        await db.doc('app_config/version').set({
          'minVersion': '1.0.0',
          'recommendedVersion': '1.0.0',
        });
        final service = ForceUpdateService(db: db, currentVersion: '2.0.0');

        final result = await service.checkForUpdate();
        expect(result, ForceUpdateResult.upToDate);
      });

      test('現在バージョンが最低バージョン未満_強制更新を返す', () async {
        final db = FakeFirebaseFirestore();
        await db.doc('app_config/version').set({
          'minVersion': '2.0.0',
          'recommendedVersion': '2.0.0',
        });
        final service = ForceUpdateService(db: db, currentVersion: '1.0.0');

        final result = await service.checkForUpdate();
        expect(result, ForceUpdateResult.forced);
      });

      test('現在バージョンが推奨バージョン未満で最低バージョン以上_推奨更新を返す',
          () async {
        final db = FakeFirebaseFirestore();
        await db.doc('app_config/version').set({
          'minVersion': '1.0.0',
          'recommendedVersion': '2.0.0',
        });
        final service = ForceUpdateService(db: db, currentVersion: '1.5.0');

        final result = await service.checkForUpdate();
        expect(result, ForceUpdateResult.recommended);
      });

      test('Firestoreドキュメントが存在しない場合_更新不要を返す', () async {
        final db = FakeFirebaseFirestore();
        final service = ForceUpdateService(db: db, currentVersion: '1.0.0');

        final result = await service.checkForUpdate();
        expect(result, ForceUpdateResult.upToDate);
      });

      test('Firestoreドキュメントのフィールドが欠落_フォールバックで更新不要を返す',
          () async {
        final db = FakeFirebaseFirestore();
        await db.doc('app_config/version').set({});
        final service = ForceUpdateService(db: db, currentVersion: '1.0.0');

        final result = await service.checkForUpdate();
        expect(result, ForceUpdateResult.upToDate);
      });
    });
  });
}
