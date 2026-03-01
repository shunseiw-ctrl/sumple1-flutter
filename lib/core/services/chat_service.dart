import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_performance/firebase_performance.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// チャット機能のビジネスロジックを管理
class ChatService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// 現在のユーザーUID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// チャットルームの初期化情報
  Future<ChatRoomInitResult> initializeChatRoom(String applicationId) async {
    Trace? trace;
    try {
      trace = FirebasePerformance.instance.newTrace('chat_init');
      await trace.start();
    } catch (_) {
      // Performance not available (e.g., in tests)
    }
    try {
      if (currentUserId.isEmpty) {
        return ChatRoomInitResult.error('ログインしてください');
      }

      // applications/{chatId} を取得
      final appRef = _firestore.collection(AppConstants.collectionApplications).doc(applicationId);
      final appSnap = await appRef.get();

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

      // chats/{chatId} の初期化
      final chatRef = _firestore.collection(AppConstants.collectionChats).doc(applicationId);
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

      try { await trace?.stop(); } catch (_) {}
      return ChatRoomInitResult.success(
        applicantUid: applicantUid,
        adminUid: adminUid,
        jobId: jobId,
        titleSnapshot: titleSnapshot,
        isApplicant: amApplicant,
        isAdmin: amAdmin,
      );
    } on FirebaseException catch (e) {
      try { await trace?.stop(); } catch (_) {}
      Logger.error(
        'Firebase error during chat initialization',
        tag: 'ChatService',
        error: e,
        data: {'code': e.code, 'message': e.message},
      );
      return ChatRoomInitResult.error(_getFirebaseErrorMessage(e));
    } catch (e, stackTrace) {
      try { await trace?.stop(); } catch (_) {}
      Logger.error(
        'Unexpected error during chat initialization',
        tag: 'ChatService',
        error: e,
        stackTrace: stackTrace,
      );
      return ChatRoomInitResult.error('チャットの初期化に失敗しました');
    }
  }

  /// チャットドキュメントが存在することを保証
  Future<void> _ensureChatDocumentExists({
    required DocumentReference<Map<String, dynamic>> chatRef,
    required String applicationId,
    required String applicantUid,
    required String adminUid,
    required String jobId,
    required String titleSnapshot,
  }) async {
    final chatSnap = await chatRef.get();

    if (!chatSnap.exists) {
      // 新規作成（7キー固定）
      await chatRef.set({
        'applicationId': applicationId,
        'applicantUid': applicantUid,
        'adminUid': adminUid,
        'jobId': jobId,
        'titleSnapshot': titleSnapshot,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.info(
        'Chat document created',
        tag: 'ChatService',
        data: {'applicationId': applicationId},
      );
    } else {
      // 既存の場合はタイトルのみ更新
      try {
        await chatRef.update({
          'titleSnapshot': titleSnapshot,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        Logger.warning(
          'Failed to update chat title',
          tag: 'ChatService',
          data: {'error': e.toString()},
        );
      }
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
      Logger.warning(
        'Failed to clear unread count',
        tag: 'ChatService',
        data: {'error': e.toString()},
      );
    }
  }

  /// メッセージを送信（リトライ機能付き）
  Future<SendMessageResult> sendMessage({
    required String applicationId,
    required String text,
    int maxRetries = 3,
  }) async {
    if (text.trim().isEmpty) {
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
          data: {'attempt': attempt, 'maxRetries': maxRetries},
        );

        final chatRef = _firestore.collection(AppConstants.collectionChats).doc(applicationId);
        final appRef = _firestore.collection(AppConstants.collectionApplications).doc(applicationId);

        // applications データを取得
        final appSnap = await appRef.get();
        final app = appSnap.data() ?? {};

        final applicantUid = (app['applicantUid'] ?? '').toString();
        final adminUid = (app['adminUid'] ?? '').toString();

        // メッセージを追加
        await chatRef.collection('messages').add({
          'senderUid': currentUserId,
          'text': text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // チャット情報を更新
        final update = <String, dynamic>{
          'lastMessageText': text.trim(),
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
        return 'ネットワークエラーが発生しました';
      case 'deadline-exceeded':
        return 'タイムアウトしました';
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
