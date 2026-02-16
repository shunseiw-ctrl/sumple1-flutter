import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// チャット機能のビジネスロジックを管理
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザーUID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// チャットルームの初期化情報（タイムアウト付き）
  Future<ChatRoomInitResult> initializeChatRoom(String applicationId) async {
    try {
      if (currentUserId.isEmpty) {
        return ChatRoomInitResult.error('ログインしてください');
      }

      Logger.info(
        'Initializing chat room',
        tag: 'ChatService',
        data: {'applicationId': applicationId, 'uid': currentUserId},
      );

      // タイムアウト付きで applications/{chatId} を取得
      final appRef = _firestore
          .collection(AppConstants.collectionApplications)
          .doc(applicationId);

      DocumentSnapshot<Map<String, dynamic>> appSnap;
      try {
        appSnap = await appRef.get().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('応募データの取得がタイムアウトしました'),
        );
      } catch (e) {
        Logger.error(
          'Failed to get application document',
          tag: 'ChatService',
          error: e,
        );
        return ChatRoomInitResult.error(
          'データの取得に失敗しました。通信環境を確認してください。',
        );
      }

      if (!appSnap.exists) {
        return ChatRoomInitResult.error('応募データが見つかりません');
      }

      final app = appSnap.data() ?? {};
      final applicantUid = (app['applicantUid'] ?? '').toString();
      final adminUid = (app['adminUid'] ?? '').toString();
      final jobId = (app['jobId'] ?? '').toString();

      final titleSnapshot = (app['projectNameSnapshot'] ??
              app['jobTitleSnapshot'] ??
              '案件チャット')
          .toString();

      final amApplicant = currentUserId == applicantUid;
      final amAdmin = currentUserId == adminUid;

      if (!amApplicant && !amAdmin) {
        return ChatRoomInitResult.error('このチャットを開く権限がありません');
      }

      if (applicantUid.isEmpty || adminUid.isEmpty || jobId.isEmpty) {
        return ChatRoomInitResult.error('必要情報が不足しています');
      }

      // chats/{chatId} の初期化（冪等操作）
      final chatRef = _firestore
          .collection(AppConstants.collectionChats)
          .doc(applicationId);

      await _ensureChatDocumentExists(
        chatRef: chatRef,
        applicationId: applicationId,
        applicantUid: applicantUid,
        adminUid: adminUid,
        jobId: jobId,
        titleSnapshot: titleSnapshot,
      );

      // 未読カウントをクリア
      await _clearUnreadCount(
        chatRef: chatRef,
        isApplicant: amApplicant,
        isAdmin: amAdmin,
      );

      Logger.info(
        'Chat room initialized successfully',
        tag: 'ChatService',
        data: {
          'applicationId': applicationId,
          'isApplicant': amApplicant,
          'isAdmin': amAdmin,
        },
      );

      return ChatRoomInitResult.success(
        applicantUid: applicantUid,
        adminUid: adminUid,
        jobId: jobId,
        titleSnapshot: titleSnapshot,
        isApplicant: amApplicant,
        isAdmin: amAdmin,
      );
    } on FirebaseException catch (e) {
      Logger.error(
        'Firebase error during chat initialization',
        tag: 'ChatService',
        error: e,
        data: {'code': e.code, 'message': e.message},
      );
      return ChatRoomInitResult.error(_getFirebaseErrorMessage(e));
    } catch (e, stackTrace) {
      Logger.error(
        'Unexpected error during chat initialization',
        tag: 'ChatService',
        error: e,
        stackTrace: stackTrace,
      );
      return ChatRoomInitResult.error('チャットの初期化に失敗しました');
    }
  }

  /// チャットドキュメントが存在することを保証（冪等操作）
  ///
  /// SetOptions(merge: true) を使用することで、ドキュメントが存在しない場合は
  /// 新規作成し、存在する場合はタイトルと更新日時のみ更新します。
  /// これにより、データ不整合によるエラーを防ぎます。
  Future<void> _ensureChatDocumentExists({
    required DocumentReference<Map<String, dynamic>> chatRef,
    required String applicationId,
    required String applicantUid,
    required String adminUid,
    required String jobId,
    required String titleSnapshot,
  }) async {
    try {
      // merge: true で冪等な書き込み
      // - ドキュメントが存在しない → 全フィールドで新規作成
      // - ドキュメントが存在する → 指定フィールドのみ更新（既存データは保持）
      await chatRef.set({
        'applicationId': applicationId,
        'applicantUid': applicantUid,
        'adminUid': adminUid,
        'jobId': jobId,
        'titleSnapshot': titleSnapshot,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // 未読カウントの初期値（既存値がある場合はmergeで保持される）
        'unreadCountAdmin': 0,
        'unreadCountApplicant': 0,
        'lastMessageText': '',
      }, SetOptions(merge: true)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          Logger.warning(
            'Chat document set timed out (may succeed later via offline cache)',
            tag: 'ChatService',
          );
        },
      );

      Logger.info(
        'Chat document ensured',
        tag: 'ChatService',
        data: {'applicationId': applicationId},
      );
    } catch (e) {
      // オフラインでもFirestoreキャッシュが動作するため、
      // ここでのエラーは致命的ではない。ログに記録して続行。
      Logger.warning(
        'Failed to ensure chat document (continuing anyway)',
        tag: 'ChatService',
        data: {'error': e.toString()},
      );
    }
  }

  /// 未読カウントをクリア
  Future<void> _clearUnreadCount({
    required DocumentReference<Map<String, dynamic>> chatRef,
    required bool isApplicant,
    required bool isAdmin,
  }) async {
    try {
      final snap = await chatRef.get();

      // ドキュメントが存在しない場合はスキップ
      if (!snap.exists) {
        Logger.debug(
          'Skip unread clear: chat doc not exists yet',
          tag: 'ChatService',
        );
        return;
      }

      final data = snap.data() ?? {};
      final update = <String, dynamic>{};

      if (isApplicant) {
        final current = data['unreadCountApplicant'];
        final currentInt = (current is int) ? current : 0;
        if (currentInt != 0) {
          update['unreadCountApplicant'] = 0;
        }
      }

      if (isAdmin) {
        final current = data['unreadCountAdmin'];
        final currentInt = (current is int) ? current : 0;
        if (currentInt != 0) {
          update['unreadCountAdmin'] = 0;
        }
      }

      if (update.isNotEmpty) {
        update['updatedAt'] = FieldValue.serverTimestamp();
        await chatRef.update(update);

        Logger.debug(
          'Unread count cleared',
          tag: 'ChatService',
          data: update,
        );
      }
    } catch (e) {
      // 未読クリアの失敗はUXに致命的ではないため、ログのみ
      Logger.warning(
        'Failed to clear unread count',
        tag: 'ChatService',
        data: {'error': e.toString()},
      );
    }
  }

  /// メッセージを送信（リトライ機能付き）
  ///
  /// 画像メッセージの場合は [imageUrl] を指定します。
  Future<SendMessageResult> sendMessage({
    required String applicationId,
    required String text,
    String? imageUrl,
    int maxRetries = 3,
  }) async {
    // テキストも画像もない場合はエラー
    if (text.trim().isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
      return SendMessageResult.error('メッセージが空です');
    }

    if (currentUserId.isEmpty) {
      return SendMessageResult.error('ログインしてください');
    }

    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      attempt++;

      try {
        Logger.debug(
          'Attempting to send message',
          tag: 'ChatService',
          data: {
            'attempt': attempt,
            'maxRetries': maxRetries,
            'hasImage': imageUrl != null,
          },
        );

        final chatRef = _firestore
            .collection(AppConstants.collectionChats)
            .doc(applicationId);
        final appRef = _firestore
            .collection(AppConstants.collectionApplications)
            .doc(applicationId);

        // applications データを取得
        final appSnap = await appRef.get();
        final app = appSnap.data() ?? {};

        final applicantUid = (app['applicantUid'] ?? '').toString();
        final adminUid = (app['adminUid'] ?? '').toString();

        // メッセージデータを構築
        final messageData = <String, dynamic>{
          'senderUid': currentUserId,
          'text': text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'type': imageUrl != null ? 'image' : 'text',
        };

        // 画像URLがある場合は追加
        if (imageUrl != null && imageUrl.isNotEmpty) {
          messageData['imageUrl'] = imageUrl;
        }

        // メッセージを追加
        await chatRef.collection('messages').add(messageData);

        // チャット情報を更新
        final displayText = imageUrl != null && text.trim().isEmpty
            ? '📷 写真を送信しました'
            : text.trim();

        final update = <String, dynamic>{
          'lastMessageText': displayText,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessageSenderUid': currentUserId,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // 相手の未読カウントを増やす
        if (currentUserId == applicantUid) {
          update['unreadCountAdmin'] = FieldValue.increment(1);
        } else if (currentUserId == adminUid) {
          update['unreadCountApplicant'] = FieldValue.increment(1);
        }

        await chatRef.update(update);

        Logger.info(
          'Message sent successfully',
          tag: 'ChatService',
          data: {'attempt': attempt, 'applicationId': applicationId},
        );

        return SendMessageResult.success();
      } on FirebaseException catch (e) {
        lastError = e;

        Logger.warning(
          'Firebase error during message send',
          tag: 'ChatService',
          data: {
            'attempt': attempt,
            'code': e.code,
            'message': e.message,
          },
        );

        // リトライ不可能なエラーの場合は即座に失敗
        if (_isNonRetryableError(e)) {
          return SendMessageResult.error(_getFirebaseErrorMessage(e));
        }

        // 最後の試行でない場合は待機してリトライ
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      } catch (e, stackTrace) {
        lastError = e is Exception ? e : Exception(e.toString());

        Logger.error(
          'Unexpected error during message send',
          tag: 'ChatService',
          error: e,
          stackTrace: stackTrace,
          data: {'attempt': attempt},
        );

        // 最後の試行でない場合は待機してリトライ
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    // 全ての試行が失敗
    Logger.error(
      'All message send attempts failed',
      tag: 'ChatService',
      error: lastError,
      data: {'totalAttempts': attempt},
    );

    return SendMessageResult.error('メッセージの送信に失敗しました（${attempt}回試行）');
  }

  /// リトライ不可能なエラーかどうかを判定
  bool _isNonRetryableError(FirebaseException e) {
    const nonRetryableCodes = [
      'permission-denied',
      'not-found',
      'invalid-argument',
      'unauthenticated',
    ];
    return nonRetryableCodes.contains(e.code);
  }

  /// Firebaseエラーメッセージを取得
  String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return '権限がありません';
      case 'not-found':
        return 'チャットが見つかりません';
      case 'unavailable':
        return 'ネットワークエラーが発生しました。通信環境を確認してください。';
      case 'deadline-exceeded':
        return 'タイムアウトしました。再度お試しください。';
      default:
        return 'エラーが発生しました: ${e.code}';
    }
  }
}

/// チャットルーム初期化結果
class ChatRoomInitResult {
  final bool success;
  final String? errorMessage;
  final String? applicantUid;
  final String? adminUid;
  final String? jobId;
  final String? titleSnapshot;
  final bool isApplicant;
  final bool isAdmin;

  ChatRoomInitResult._({
    required this.success,
    this.errorMessage,
    this.applicantUid,
    this.adminUid,
    this.jobId,
    this.titleSnapshot,
    this.isApplicant = false,
    this.isAdmin = false,
  });

  factory ChatRoomInitResult.success({
    required String applicantUid,
    required String adminUid,
    required String jobId,
    required String titleSnapshot,
    required bool isApplicant,
    required bool isAdmin,
  }) {
    return ChatRoomInitResult._(
      success: true,
      applicantUid: applicantUid,
      adminUid: adminUid,
      jobId: jobId,
      titleSnapshot: titleSnapshot,
      isApplicant: isApplicant,
      isAdmin: isAdmin,
    );
  }

  factory ChatRoomInitResult.error(String message) {
    return ChatRoomInitResult._(
      success: false,
      errorMessage: message,
    );
  }
}

/// メッセージ送信結果
class SendMessageResult {
  final bool success;
  final String? errorMessage;

  SendMessageResult._({
    required this.success,
    this.errorMessage,
  });

  factory SendMessageResult.success() {
    return SendMessageResult._(success: true);
  }

  factory SendMessageResult.error(String message) {
    return SendMessageResult._(
      success: false,
      errorMessage: message,
    );
  }
}
