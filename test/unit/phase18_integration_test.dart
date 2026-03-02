import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumple1/core/utils/app_result.dart';
import 'package:sumple1/core/services/image_upload_service.dart';
import 'package:sumple1/core/services/profile_image_service.dart';
import 'package:sumple1/core/providers/admin_list_state.dart';
import 'package:sumple1/core/providers/admin_pending_counts_provider.dart';

class MockImageUploadService extends Mock implements ImageUploadService {}

void main() {
  group('Phase 18 結合テスト', () {
    test('AppResult<T> → 成功/エラー両方のパターンマッチ', () {
      const AppResult<String> success = AppSuccess('data');
      const AppResult<String> error = AppError('エラー');

      // 成功
      final s = success.when(
        success: (data) => 'ok:$data',
        error: (msg, _) => 'err:$msg',
      );
      expect(s, 'ok:data');

      // エラー
      final e = error.when(
        success: (data) => 'ok:$data',
        error: (msg, _) => 'err:$msg',
      );
      expect(e, 'err:エラー');

      // switch exhaustive
      final result = switch (success) {
        AppSuccess<String>(value: final v) => v,
        AppError<String>(message: final m) => m,
      };
      expect(result, 'data');
    });

    test('ProfileImageService → Firestore profilePhotoUrl更新確認', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockImageUpload = MockImageUploadService();
      final mockUser = MockUser(isAnonymous: false, uid: 'integ_user');
      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await fakeFirestore.collection('profiles').doc('integ_user').set({
        'profilePhotoLocked': false,
      });

      when(() => mockImageUpload.pickAndUploadImage(
            userId: any(named: 'userId'),
            folder: any(named: 'folder'),
            documentId: any(named: 'documentId'),
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            quality: any(named: 'quality'),
          )).thenAnswer(
              (_) async => ImageUploadResult.success('https://img.test/avatar.jpg'));

      final service = ProfileImageService(
        imageUploadService: mockImageUpload,
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      final result = await service.pickAndUploadAvatar();
      expect(result.isSuccess, true);

      final doc = await fakeFirestore.collection('profiles').doc('integ_user').get();
      expect(doc.data()?['profilePhotoUrl'], 'https://img.test/avatar.jpg');
    });

    test('AdminListState → copyWith + ページネーション状態管理', () {
      const initial = AdminListState<String>(
        items: ['a', 'b', 'c'],
        hasMore: true,
        filterStatus: 'all',
      );

      // フィルタ変更
      final filtered = initial.copyWith(filterStatus: 'applied');
      expect(filtered.filterStatus, 'applied');
      expect(filtered.items, initial.items);

      // ページネーション追加
      final loaded = filtered.copyWith(
        items: [...filtered.items, 'd', 'e'],
        hasMore: false,
        isLoadingMore: false,
      );
      expect(loaded.items.length, 5);
      expect(loaded.hasMore, false);

      // 検索
      final searched = loaded.copyWith(searchQuery: 'a');
      final results = searched.filteredItems((item, q) => item.contains(q));
      expect(results, ['a']);
    });

    test('AdminPendingCounts → 複数コレクションの件数集計', () {
      const counts = AdminPendingCounts(
        pendingApplications: 5,
        pendingQualifications: 3,
        pendingEarlyPayments: 2,
      );

      expect(counts.total, 10);
      expect(counts.pendingApplications, 5);
      expect(counts.pendingQualifications, 3);
      expect(counts.pendingEarlyPayments, 2);

      // 空の場合
      const empty = AdminPendingCounts();
      expect(empty.total, 0);
    });

    test('AdminListState clearLastDocumentの動作', () {
      const state = AdminListState<String>(items: ['x']);
      final cleared = state.copyWith(clearLastDocument: true);
      expect(cleared.lastDocument, null);
      expect(cleared.items, ['x']);
    });
  });
}
