import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:sumple1/data/models/referral_model.dart';
import 'package:sumple1/core/services/referral_service.dart';
import 'package:sumple1/core/services/share_service.dart';
import 'package:sumple1/core/services/ekyc_manual_service.dart';
import 'package:sumple1/data/models/ekyc_result.dart';
import 'package:sumple1/pages/legal_page.dart';
import 'package:sumple1/core/router/route_paths.dart';

void main() {
  group('Phase 19 Integration Tests', () {
    // 1. ReferralModel → toMap/fromMap ラウンドトリップ
    test('ReferralModel toMap/fromMap round-trip', () {
      final now = DateTime(2026, 3, 2, 12, 0, 0);
      final model = ReferralModel(
        code: 'ABC123',
        referrerUid: 'user1',
        refereeUid: 'user2',
        status: 'completed',
        rewardGranted: true,
        createdAt: now,
      );

      final map = model.toMap();
      final restored = ReferralModel.fromMap(map);

      expect(restored.code, 'ABC123');
      expect(restored.referrerUid, 'user1');
      expect(restored.refereeUid, 'user2');
      expect(restored.status, 'completed');
      expect(restored.rewardGranted, isTrue);
    });

    // 2. ReferralService → generateCode + applyCode 連携
    test('ReferralService generateCode + applyCode flow', () async {
      final firestore = FakeFirebaseFirestore();
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'referrer1',
        email: 'referrer@example.com',
      );
      final auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      final service = ReferralService(firestore: firestore, auth: auth);

      // 紹介者がコード生成
      final code = await service.generateCode('referrer1');
      expect(code.length, 6);

      // 被紹介者がコード適用
      await service.applyCode(code, 'referee1');

      // referrals コレクションにドキュメントが作成されたことを確認
      final referrals = await firestore.collection('referrals').get();
      expect(referrals.docs.length, 1);
      expect(referrals.docs.first.data()['code'], code);
      expect(referrals.docs.first.data()['referrerUid'], 'referrer1');
      expect(referrals.docs.first.data()['refereeUid'], 'referee1');
    });

    // 3. ShareService → 求人シェアテキストフォーマット
    test('ShareService shareJobText format', () {
      final text = ShareService.shareJobText(
        'job123',
        '内装工事スタッフ',
        '15000',
        '東京都新宿区',
      );

      expect(text, contains('【ALBAWORK】内装工事スタッフ'));
      expect(text, contains('場所: 東京都新宿区'));
      expect(text, contains('日給: 15000円'));
      expect(text, contains('https://alba-work.web.app/jobs/job123'));
    });

    // 4. EkycManualService → checkStatus 各状態遷移
    test('EkycManualService checkStatus state transitions', () async {
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(isAnonymous: false, uid: 'testUid'),
        signedIn: true,
      );
      final service = ManualEkycService(firestore: firestore, auth: auth);

      // ドキュメントなし → notStarted
      var status = await service.checkStatus('testUid');
      expect(status, EkycStatus.notStarted);

      // pending
      await firestore.collection('identity_verification').doc('testUid').set({
        'status': 'pending',
      });
      status = await service.checkStatus('testUid');
      expect(status, EkycStatus.pending);

      // approved
      await firestore.collection('identity_verification').doc('testUid').update({
        'status': 'approved',
      });
      status = await service.checkStatus('testUid');
      expect(status, EkycStatus.approved);

      // rejected
      await firestore.collection('identity_verification').doc('testUid').update({
        'status': 'rejected',
      });
      status = await service.checkStatus('testUid');
      expect(status, EkycStatus.rejected);
    });

    // 5. EkycResult → sealed class パターンマッチ網羅
    test('EkycResult sealed class exhaustive pattern match', () {
      final results = <EkycResult>[
        const EkycSuccess(verificationId: 'v1'),
        const EkycPending(message: 'pending'),
        const EkycError(message: 'error'),
        const EkycUnavailable(),
      ];

      for (final result in results) {
        final label = switch (result) {
          EkycSuccess(verificationId: final id) => 'success:$id',
          EkycPending(message: final msg) => 'pending:$msg',
          EkycError(message: final msg) => 'error:$msg',
          EkycUnavailable() => 'unavailable',
        };
        expect(label, isNotEmpty);
      }

      // equality
      expect(
        const EkycSuccess(verificationId: 'v1'),
        const EkycSuccess(verificationId: 'v1'),
      );
      expect(
        const EkycUnavailable(),
        const EkycUnavailable(),
      );
    });

    // 6. 法的HTML定数 → 5ドキュメント全て存在確認
    test('Legal HTML constants exist for all 5 documents', () {
      expect(LegalPage.privacyPolicyHtml, isNotEmpty);
      expect(LegalPage.termsHtml, isNotEmpty);
      expect(LegalPage.laborInsuranceHtml, isNotEmpty);
      expect(LegalPage.dispatchLawHtml, isNotEmpty);
      expect(LegalPage.employmentSecurityLawHtml, isNotEmpty);

      // 内容に主要キーワードが含まれることを確認
      expect(LegalPage.laborInsuranceHtml, contains('労災'));
      expect(LegalPage.dispatchLawHtml, contains('派遣'));
      expect(LegalPage.employmentSecurityLawHtml, contains('職業安定法'));
    });

    // 7. RoutePaths → 新規ルート存在確認（legalIndex, referral）
    test('RoutePaths contains new Phase 19 routes', () {
      expect(RoutePaths.legalIndex, '/legal-index');
      expect(RoutePaths.referral, '/referral');

      // 既存ルートも健在確認
      expect(RoutePaths.home, '/');
      expect(RoutePaths.jobList, '/jobs');
      expect(RoutePaths.mapSearch, '/map-search');
      expect(RoutePaths.qualifications, '/qualifications');
      expect(RoutePaths.statements, '/statements');
    });

    // 8. AnalyticsService → 新規イベントメソッド存在確認
    test('ShareService methods exist and return correct text', () {
      // shareJobText
      final jobText = ShareService.shareJobText('id', 'title', '10000', 'loc');
      expect(jobText, contains('ALBAWORK'));
      expect(jobText, contains('https://alba-work.web.app/jobs/id'));

      // shareReferralText
      final refText = ShareService.shareReferralText('CODE');
      expect(refText, contains('紹介コード: CODE'));

      // shareAppText
      final appText = ShareService.shareAppText();
      expect(appText, contains('alba-work.web.app'));
    });
  });
}
