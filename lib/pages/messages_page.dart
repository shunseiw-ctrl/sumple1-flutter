import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'chat_room_page.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String _query = '';

  // 固定ADMIN UID（MVP）
  static const String _adminUid = AppConstants.adminUid;

  String get _myUid => _auth.currentUser?.uid ?? '';
  String get _myEmail => _auth.currentUser?.email ?? '';
  bool get _isAdmin => _myUid.isNotEmpty && _myUid == _adminUid;

  // chats/{appId} の lastMessageAt をキャッシュ（並び替え用）
  final Map<String, DateTime> _lastAtCache = {};

  DateTime _toDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _lastMessageAtFromChat(Map<String, dynamic>? chat) {
    if (chat == null) return null;
    final v = chat['lastMessageAt'];
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  // chats/{appId} から未読数を取得（自分側）
  int _unreadFromChat(Map<String, dynamic>? chat) {
    if (chat == null) return 0;
    final key = _isAdmin ? 'unreadCountAdmin' : 'unreadCountApplicant';
    final v = chat[key];
    if (v is int) return v;
    return 0;
  }

  String _lastMessageTextFromChat(Map<String, dynamic>? chat) {
    if (chat == null) return '';
    final v = chat['lastMessageText'];
    return (v ?? '').toString().trim();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  // ✅ 右上の日付を yyyy/MM/dd で固定
  String _formatYmd(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}/${_two(dt.month)}/${_two(dt.day)}';
  }

  Widget _unreadBadge(int unread) {
    if (unread <= 0) return const SizedBox.shrink();
    final text = unread > 99 ? '99+' : unread.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  int _compareByLastMessageAtDesc(
      QueryDocumentSnapshot<Map<String, dynamic>> a,
      QueryDocumentSnapshot<Map<String, dynamic>> b,
      ) {
    // キャッシュがあれば lastMessageAt、なければ applications.createdAt をフォールバック
    final aLast = _lastAtCache[a.id];
    final bLast = _lastAtCache[b.id];

    if (aLast != null || bLast != null) {
      final ad = aLast ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = bLast ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    }

    final ad = _toDate(a.data()['createdAt']);
    final bd = _toDate(b.data()['createdAt']);
    return bd.compareTo(ad);
  }

  void _log(String message, {Map<String, dynamic>? extra}) {
    Logger.debug(message, tag: 'MessagesPage', data: extra);
  }

  /// ✅ ルール完全適合（update維持＋存在チェック＋ログ）
  /// - chats/{chatId} update は changedKeys 制限があるため、許可キーのみ更新
  /// - doc が無い場合は create しない（create は 7キー必須で MessagesPage からは事故りやすい）
  Future<void> _resetUnreadIfPossible(String chatId) async {
    if (_myUid.isEmpty) return;

    final chatRef = _db.collection('chats').doc(chatId);
    final unreadKey = _isAdmin ? 'unreadCountAdmin' : 'unreadCountApplicant';

    try {
      final snap = await chatRef.get();

      if (!snap.exists) {
        _log('skip unread reset (chat doc not exists)', extra: {
          'chatId': chatId,
          'unreadKey': unreadKey,
        });
        return;
      }

      // 既に0なら書かない（無駄な書き込み削減）
      final data = snap.data() ?? <String, dynamic>{};
      final cur = data[unreadKey];
      final curInt = (cur is int) ? cur : 0;
      if (curInt == 0) {
        _log('skip unread reset (already 0)', extra: {
          'chatId': chatId,
          'unreadKey': unreadKey,
        });
        return;
      }

      // ✅ rules で許可されているキーのみ
      await chatRef.update({
        unreadKey: 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _log('unread reset ok', extra: {
        'chatId': chatId,
        'unreadKey': unreadKey,
        'from': curInt,
        'to': 0,
      });
    } on FirebaseException catch (e) {
      // permission-denied / not-found などをログに残す（MVP: UIは止めない）
      _log('unread reset failed (FirebaseException)', extra: {
        'chatId': chatId,
        'code': e.code,
        'message': e.message ?? '',
      });
    } catch (e) {
      _log('unread reset failed (unknown)', extra: {
        'chatId': chatId,
        'error': e.toString(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_myUid.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('ログインしてください')),
      );
    }

    // ✅ 母集団（applications）
    final applicationsQuery = _db
        .collection('applications')
        .where(_isAdmin ? 'adminUid' : 'applicantUid', isEqualTo: _myUid)
        .limit(50);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'メッセージ（管理者）' : 'メッセージ'),
        bottom: kDebugMode
            ? PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'uid=${_myUid.substring(0, _myUid.length > 8 ? 8 : _myUid.length)}…  '
                    'isAdmin=$_isAdmin  '
                    '${_myEmail.isEmpty ? "" : "email=$_myEmail"}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ),
        )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '案件名で検索',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: applicationsQuery.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('読み込みエラー: ${snap.error}'));
                }

                final docs = snap.data?.docs.toList() ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(_isAdmin ? '担当案件のメッセージはまだありません' : 'メッセージはまだありません'),
                  );
                }

                // ✅ 検索（物件名を最優先：projectNameSnapshot）
                final filtered = docs.where((d) {
                  final data = d.data();
                  final title = (data['projectNameSnapshot'] ??
                      data['jobTitleSnapshot'] ??
                      data['titleSnapshot'] ??
                      '')
                      .toString();
                  if (_query.isEmpty) return true;
                  return title.toLowerCase().contains(_query.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('検索結果がありません'));
                }

                // ✅ 並び替え：lastMessageAt desc（キャッシュ使用）
                filtered.sort(_compareByLastMessageAtDesc);

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    final appId = doc.id;
                    final app = doc.data();

                    // ✅ 表示タイトルも物件名優先
                    final title = (app['projectNameSnapshot'] ??
                        app['jobTitleSnapshot'] ??
                        app['titleSnapshot'] ??
                        '案件')
                        .toString();

                    final status = (app['status'] ?? '').toString();
                    final chatStream = _db.collection('chats').doc(appId).snapshots();

                    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: chatStream,
                      builder: (context, chatSnap) {
                        final chatData = chatSnap.data?.data();
                        final unread = _unreadFromChat(chatData);
                        final lastText = _lastMessageTextFromChat(chatData);
                        final lastAt = _lastMessageAtFromChat(chatData);

                        final ymdText = _formatYmd(lastAt);

                        // ✅ キャッシュ更新（次回ビルドの並び替えに反映）
                        if (lastAt != null) {
                          final prev = _lastAtCache[appId];
                          if (prev == null || prev != lastAt) {
                            _lastAtCache[appId] = lastAt;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() {});
                            });
                          }
                        }

                        final sub1 = lastText.isNotEmpty
                            ? lastText
                            : (status.isEmpty ? ' ' : 'ステータス: $status');
                        final sub2 = lastText.isNotEmpty && status.isNotEmpty ? 'ステータス: $status' : '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueGrey.shade100,
                            child: const Icon(Icons.work_outline, color: Colors.black54),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (ymdText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    ymdText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (sub2.isNotEmpty)
                                Text(
                                  sub2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _unreadBadge(unread),
                              const SizedBox(width: 10),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () async {
                            // ✅ ルール適合：存在する時だけ update（create しない）
                            await _resetUnreadIfPossible(appId);

                            if (!context.mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomPage(applicationId: appId),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
