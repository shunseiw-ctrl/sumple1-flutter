import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatRoomPage extends StatefulWidget {
  final String applicationId; // = chatId = applications docId
  const ChatRoomPage({super.key, required this.applicationId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _controller = TextEditingController();
  bool _sending = false;

  bool _ready = false;
  String? _readyError;

  bool _clearingUnread = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _appRef =>
      FirebaseFirestore.instance.collection('applications').doc(widget.applicationId);

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      FirebaseFirestore.instance.collection('chats').doc(widget.applicationId);

  CollectionReference<Map<String, dynamic>> get _msgRef =>
      _chatRef.collection('messages');

  @override
  void initState() {
    super.initState();
    _initializeChatRoom();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeChatRoom() async {
    try {
      if (_uid.isEmpty) {
        setState(() {
          _readyError = 'ログインしてください';
          _ready = false;
        });
        return;
      }

      // applications/{chatId} を正として当事者・必須情報を確定
      final appSnap = await _appRef.get();
      final app = appSnap.data();
      if (app == null) {
        setState(() {
          _readyError = '応募データが見つかりません（applications が存在しません）';
          _ready = false;
        });
        return;
      }

      final applicantUid = (app['applicantUid'] ?? '').toString();
      final adminUid = (app['adminUid'] ?? '').toString();
      final jobId = (app['jobId'] ?? '').toString();

      final titleSnapshot = (app['projectNameSnapshot'] ??
          app['jobTitleSnapshot'] ??
          '案件チャット')
          .toString();

      final amApplicant = _uid == applicantUid;
      final amAdmin = _uid == adminUid;

      if (!amApplicant && !amAdmin) {
        setState(() {
          _readyError = 'このチャットを開く権限がありません（当事者ではありません）';
          _ready = false;
        });
        return;
      }

      if (applicantUid.isEmpty || adminUid.isEmpty || jobId.isEmpty) {
        setState(() {
          _readyError = '必要情報が不足しています（applicantUid/adminUid/jobId）';
          _ready = false;
        });
        return;
      }

      // chats/{chatId} が無ければ rules の create(keys固定) に完全一致する7キーで作る
      final chatSnap = await _chatRef.get();
      if (!chatSnap.exists) {
        await _chatRef.set({
          'applicationId': widget.applicationId, // chatId と一致必須
          'applicantUid': applicantUid,
          'adminUid': adminUid,
          'jobId': jobId,
          'titleSnapshot': titleSnapshot,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 既存なら update許可キーだけ更新（titleSnapshot/updatedAt）
        // ※ updateルールの changedKeys に titleSnapshot/updatedAt が含まれている前提（貼ってくれた rules と一致）
        try {
          await _chatRef.update({
            'titleSnapshot': titleSnapshot,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      await _clearUnreadCountIfNeeded(amApplicant: amApplicant, amAdmin: amAdmin);

      if (mounted) {
        setState(() {
          _readyError = null;
          _ready = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _readyError = 'チャットの初期化に失敗: $e';
          _ready = false;
        });
      }
    }
  }

  Future<void> _clearUnreadCountIfNeeded({
    required bool amApplicant,
    required bool amAdmin,
  }) async {
    if (_clearingUnread) return;
    _clearingUnread = true;

    try {
      final snap = await _chatRef.get();
      final data = snap.data() ?? <String, dynamic>{};

      final update = <String, dynamic>{};

      if (amApplicant) {
        final cur = data['unreadCountApplicant'];
        final curInt = (cur is int) ? cur : 0;
        if (curInt != 0) update['unreadCountApplicant'] = 0;
      }
      if (amAdmin) {
        final cur = data['unreadCountAdmin'];
        final curInt = (cur is int) ? cur : 0;
        if (curInt != 0) update['unreadCountAdmin'] = 0;
      }

      if (update.isNotEmpty) {
        update['updatedAt'] = FieldValue.serverTimestamp();
        await _chatRef.update(update);
      }
    } catch (_) {
      // MVP: 失敗しても致命傷にしない
    } finally {
      _clearingUnread = false;
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _uid.isEmpty) return;

    setState(() => _sending = true);

    try {
      if (!_ready) {
        await _initializeChatRoom();
        if (!_ready) throw Exception(_readyError ?? 'チャットの準備ができていません');
      }

      final appSnap = await _appRef.get();
      final app = appSnap.data() ?? {};

      final applicantUid = (app['applicantUid'] ?? '').toString();
      final adminUid = (app['adminUid'] ?? '').toString();

      await _msgRef.add({
        'senderUid': _uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final update = <String, dynamic>{
        'lastMessageText': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderUid': _uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_uid == applicantUid) {
        update['unreadCountAdmin'] = FieldValue.increment(1);
      } else if (_uid == adminUid) {
        update['unreadCountApplicant'] = FieldValue.increment(1);
      }

      await _chatRef.update(update);

      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送信に失敗: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _uid;

    return Scaffold(
      appBar: AppBar(
        title: _ready
            ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _chatRef.snapshots(),
          builder: (context, snap) {
            final title =
            (snap.data?.data()?['titleSnapshot'] ?? 'チャット').toString();
            return Text(title);
          },
        )
            : const Text('チャット'),
      ),
      body: !_ready
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_readyError == null)
                const CircularProgressIndicator()
              else
                Text(_readyError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _initializeChatRoom,
                child: const Text('再試行'),
              )
            ],
          ),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _msgRef
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('読み込みエラー: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('まだメッセージはありません'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data();
                    final sender = (m['senderUid'] ?? '').toString();
                    final text = (m['text'] ?? '').toString();
                    final mine = sender == myUid;

                    return Align(
                      alignment:
                      mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color:
                          mine ? Colors.blue.shade50 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'メッセージを入力',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
