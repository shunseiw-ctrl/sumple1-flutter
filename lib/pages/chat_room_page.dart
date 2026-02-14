import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/services/chat_service.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/logger.dart';

class ChatRoomPage extends StatefulWidget {
  final String applicationId; // = chatId = applications docId
  const ChatRoomPage({super.key, required this.applicationId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _controller = TextEditingController();
  final _chatService = ChatService();

  bool _sending = false;
  bool _ready = false;
  String? _readyError;

  // 初期化結果を保持
  ChatRoomInitResult? _initResult;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

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
    Logger.info('Initializing chat room', tag: 'ChatRoomPage');

    setState(() {
      _ready = false;
      _readyError = null;
    });

    final result = await _chatService.initializeChatRoom(widget.applicationId);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _initResult = result;
        _ready = true;
        _readyError = null;
      });
      Logger.info('Chat room ready', tag: 'ChatRoomPage');
    } else {
      setState(() {
        _ready = false;
        _readyError = result.errorMessage;
      });
      Logger.warning(
        'Chat room initialization failed',
        tag: 'ChatRoomPage',
        data: {'error': result.errorMessage},
      );
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // UIをロック
    setState(() => _sending = true);

    Logger.debug('Sending message', tag: 'ChatRoomPage');

    try {
      // チャットが準備できていない場合は初期化を試行
      if (!_ready) {
        await _initializeChatRoom();
        if (!_ready) {
          throw Exception(_readyError ?? 'チャットの準備ができていません');
        }
      }

      // メッセージ送信（リトライ機能付き）
      final result = await _chatService.sendMessage(
        applicationId: widget.applicationId,
        text: text,
      );

      if (!mounted) return;

      if (result.success) {
        _controller.clear();
        Logger.info('Message sent successfully', tag: 'ChatRoomPage');
      } else {
        ErrorHandler.showError(
          context,
          result.errorMessage ?? 'メッセージの送信に失敗しました',
        );
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Error sending message',
        tag: 'ChatRoomPage',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
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
