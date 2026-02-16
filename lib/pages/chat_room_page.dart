import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/services/chat_service.dart';
import '../core/services/image_upload_service.dart';
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
  final _imageService = ImageUploadService();
  final _scrollController = ScrollController();

  bool _sending = false;
  bool _ready = false;
  String? _readyError;
  bool _uploadingImage = false;

  // 初期化結果を保持
  ChatRoomInitResult? _initResult;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.applicationId);

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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatRoom() async {
    Logger.info('Initializing chat room', tag: 'ChatRoomPage');

    setState(() {
      _ready = false;
      _readyError = null;
    });

    final result =
        await _chatService.initializeChatRoom(widget.applicationId);

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

  /// 画像を選択して送信
  Future<void> _sendImage() async {
    if (_uploadingImage) return;

    setState(() => _uploadingImage = true);

    try {
      // 選択方法をボトムシートで表示
      final source = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    '写真を送信',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.camera_alt, color: Colors.blue),
                  ),
                  title: const Text('カメラで撮影'),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library,
                        color: Colors.green),
                  ),
                  title: const Text('ギャラリーから選択'),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (source == null || !mounted) {
        setState(() => _uploadingImage = false);
        return;
      }

      // ローディング表示
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('写真をアップロード中...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // アップロード
      ImageUploadResult result;
      if (source == 'camera') {
        result = await _imageService.captureAndUploadImage(
          userId: _uid,
          folder: 'messages',
          documentId: widget.applicationId,
        );
      } else {
        result = await _imageService.pickAndUploadImage(
          userId: _uid,
          folder: 'messages',
          documentId: widget.applicationId,
        );
      }

      if (!mounted) return;

      // ローディングを閉じる
      Navigator.pop(context);

      if (result.cancelled) {
        setState(() => _uploadingImage = false);
        return;
      }

      if (!result.success || result.downloadUrl == null) {
        ErrorHandler.showError(
          context,
          result.errorMessage ?? '画像のアップロードに失敗しました',
        );
        setState(() => _uploadingImage = false);
        return;
      }

      // 画像メッセージを送信
      final sendResult = await _chatService.sendMessage(
        applicationId: widget.applicationId,
        text: '',
        imageUrl: result.downloadUrl,
      );

      if (!mounted) return;

      if (sendResult.success) {
        Logger.info('Image message sent', tag: 'ChatRoomPage');
      } else {
        ErrorHandler.showError(
          context,
          sendResult.errorMessage ?? '画像の送信に失敗しました',
        );
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Error sending image',
        tag: 'ChatRoomPage',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;
      ErrorHandler.showError(context, '画像の送信に失敗しました');
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  /// メッセージバブルを構築
  Widget _buildMessageBubble(Map<String, dynamic> m, bool mine) {
    final text = (m['text'] ?? '').toString();
    final type = (m['type'] ?? 'text').toString();
    final imageUrl = (m['imageUrl'] ?? '').toString();

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // 画像メッセージ
            if (type == 'image' && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => _showFullImage(imageUrl),
                  child: Image.network(
                    imageUrl,
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 220,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey),
                            SizedBox(height: 4),
                            Text(
                              '画像を読み込めません',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

            // テキストメッセージ
            if (text.isNotEmpty)
              Container(
                margin: EdgeInsets.only(
                  top: type == 'image' && imageUrl.isNotEmpty ? 4 : 0,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: mine ? Colors.blue.shade50 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(text),
              ),

            // テキストなし・画像なしの場合（フォールバック）
            if (text.isEmpty && (type != 'image' || imageUrl.isEmpty))
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: mine ? Colors.blue.shade50 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('（メッセージ）'),
              ),
          ],
        ),
      ),
    );
  }

  /// 画像をフルスクリーンで表示
  void _showFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
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
                      (snap.data?.data()?['titleSnapshot'] ?? 'チャット')
                          .toString();
                  return Text(title);
                },
              )
            : const Text('チャット'),
      ),
      body: !_ready
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_readyError == null) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        'チャットを準備しています...',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _readyError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '通信環境を確認して再度お試しください',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _initializeChatRoom,
                        icon: const Icon(Icons.refresh),
                        label: const Text('再試行'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child:
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _msgRef
                        .orderBy('createdAt', descending: true)
                        .limit(100)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.orange),
                              const SizedBox(height: 12),
                              Text('読み込みエラー: ${snap.error}'),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => setState(() {}),
                                child: const Text('再読み込み'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final docs = snap.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 48, color: Colors.black26),
                              SizedBox(height: 12),
                              Text(
                                'まだメッセージはありません',
                                style: TextStyle(color: Colors.black54),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'メッセージを送信して会話を始めましょう',
                                style: TextStyle(
                                    color: Colors.black38, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final m = docs[i].data();
                          final sender =
                              (m['senderUid'] ?? '').toString();
                          final mine = sender == myUid;

                          return _buildMessageBubble(m, mine);
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    child: Row(
                      children: [
                        // 画像送信ボタン
                        IconButton(
                          onPressed:
                              _uploadingImage ? null : _sendImage,
                          icon: _uploadingImage
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Icon(
                                  Icons.photo_camera,
                                  color: Colors.grey.shade600,
                                ),
                          tooltip: '写真を送信',
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'メッセージを入力',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(24),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(24),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                    color: Colors.black),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: IconButton(
                            onPressed: _sending ? null : _send,
                            icon: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send,
                                    color: Colors.white),
                          ),
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
