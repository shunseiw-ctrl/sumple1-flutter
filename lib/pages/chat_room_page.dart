import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/services/chat_image_service.dart';
import '../core/services/chat_service.dart';
import '../core/utils/error_handler.dart';
import '../core/utils/logger.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../presentation/widgets/chat_image_bubble.dart';

class ChatRoomPage extends StatefulWidget {
  final String applicationId;
  const ChatRoomPage({super.key, required this.applicationId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _chatImageService = ChatImageService();
  final _focusNode = FocusNode();

  bool _sending = false;
  bool _uploadingImage = false;
  bool _ready = false;
  String? _readyError;
  bool _isApplicant = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      FirebaseFirestore.instance.collection('chats').doc(widget.applicationId);

  CollectionReference<Map<String, dynamic>> get _msgRef =>
      _chatRef.collection('messages');

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('chat_room');
    _initializeChatRoom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeChatRoom() async {
    Logger.info('Initializing chat room', tag: 'ChatRoomPage');
    setState(() { _ready = false; _readyError = null; });

    final result = await _chatService.initializeChatRoom(widget.applicationId);
    if (!mounted) return;

    if (result.success) {
      _isApplicant = result.isApplicant;
      // 既読タイムスタンプを更新
      _chatService.markAsRead(
        applicationId: widget.applicationId,
        isApplicant: _isApplicant,
      );
      setState(() { _ready = true; _readyError = null; });
    } else {
      setState(() { _ready = false; _readyError = result.errorMessage; });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      if (!_ready) {
        await _initializeChatRoom();
        if (!_ready) throw Exception(_readyError ?? 'チャットの準備ができていません');
      }

      final result = await _chatService.sendMessage(
        applicationId: widget.applicationId,
        text: text,
      );

      if (!mounted) return;
      if (result.success) {
        _controller.clear();
      } else {
        ErrorHandler.showError(context, result.errorMessage ?? 'メッセージの送信に失敗しました');
      }
    } catch (e, stackTrace) {
      Logger.error('Error sending message', tag: 'ChatRoomPage', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.ruri),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(ctx);
                _sendImage(useCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.ruri),
              title: const Text('ギャラリーから選択'),
              onTap: () {
                Navigator.pop(ctx);
                _sendImage(useCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendImage({required bool useCamera}) async {
    if (_uploadingImage) return;
    setState(() => _uploadingImage = true);

    try {
      if (!_ready) {
        await _initializeChatRoom();
        if (!_ready) throw Exception(_readyError ?? 'チャットの準備ができていません');
      }

      final userId = _uid;
      if (userId.isEmpty) {
        ErrorHandler.showError(context, 'ログインしてください');
        return;
      }

      final uploadResult = useCamera
          ? await _chatImageService.captureAndUpload(
              userId: userId,
              applicationId: widget.applicationId,
            )
          : await _chatImageService.pickAndUpload(
              userId: userId,
              applicationId: widget.applicationId,
            );

      if (!mounted) return;

      if (uploadResult.cancelled) return;

      if (!uploadResult.isSuccess) {
        ErrorHandler.showError(context, uploadResult.errorMessage ?? '画像のアップロードに失敗しました');
        return;
      }

      final sendResult = await _chatService.sendImageMessage(
        applicationId: widget.applicationId,
        imageUrl: uploadResult.downloadUrl!,
      );

      if (!mounted) return;
      if (!sendResult.success) {
        ErrorHandler.showError(context, sendResult.errorMessage ?? '画像の送信に失敗しました');
      }
    } catch (e, stackTrace) {
      Logger.error('Error sending image', tag: 'ChatRoomPage', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '今日';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) {
      return '昨日';
    }
    return '${d.month}/${d.day}';
  }

  bool _shouldShowDate(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, int index) {
    if (index == docs.length - 1) return true;
    final current = docs[index].data()['createdAt'] as Timestamp?;
    final next = docs[index + 1].data()['createdAt'] as Timestamp?;
    if (current == null || next == null) return false;
    final cd = current.toDate();
    final nd = next.toDate();
    return cd.year != nd.year || cd.month != nd.month || cd.day != nd.day;
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _uid;

    return Scaffold(
      backgroundColor: const Color(0xFF8CABD9),
      appBar: AppBar(
        backgroundColor: AppColors.ruri,
        foregroundColor: Colors.white,
        elevation: 0,
        title: _ready
            ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _chatRef.snapshots(),
                builder: (context, snap) {
                  final title = (snap.data?.data()?['titleSnapshot'] ?? 'チャット').toString();
                  return Text(title, style: const TextStyle(fontWeight: FontWeight.w700));
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
                      const CircularProgressIndicator(color: AppColors.ruri)
                    else
                      Text(_readyError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _initializeChatRoom, child: const Text('再試行')),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _chatRef.snapshots(),
                    builder: (context, chatSnap) {
                      // 相手のlastReadAtを取得
                      final chatData = chatSnap.data?.data() ?? {};
                      final peerReadField = _isApplicant
                          ? 'lastReadAtAdmin'
                          : 'lastReadAtApplicant';
                      final peerLastReadAt =
                          chatData[peerReadField] as Timestamp?;

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _msgRef.orderBy('createdAt', descending: true).limit(100).snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) return const Center(child: Text('読み込みエラー'));
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.ruri));

                      final docs = snap.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('メッセージを始めましょう', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final m = docs[i].data();
                          final sender = (m['senderUid'] ?? '').toString();
                          final text = (m['text'] ?? '').toString();
                          final imageUrl = (m['imageUrl'] ?? '').toString();
                          final messageType = (m['messageType'] ?? 'text').toString();
                          final createdAt = m['createdAt'] as Timestamp?;
                          final mine = sender == myUid;
                          final showDate = _shouldShowDate(docs, i);
                          final isImageMessage = messageType == 'image' && imageUrl.isNotEmpty;

                          return Column(
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _formatDate(createdAt),
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!mine) ...[
                                      const CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.ruriPale,
                                        child: Icon(Icons.person, size: 18, color: AppColors.ruri),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    if (mine)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4, bottom: 2),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (peerLastReadAt != null &&
                                                createdAt != null &&
                                                createdAt.compareTo(peerLastReadAt) <= 0)
                                              const Text(
                                                '既読',
                                                style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                              ),
                                            Text(
                                              _formatTime(createdAt),
                                              style: const TextStyle(fontSize: 10, color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Flexible(
                                      child: isImageMessage
                                          ? ChatImageBubble(
                                              imageUrl: imageUrl,
                                              isMine: mine,
                                              caption: text.isNotEmpty ? text : null,
                                            )
                                          : Container(
                                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: mine ? const Color(0xFF7BC67E) : Colors.white,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: const Radius.circular(18),
                                                  topRight: const Radius.circular(18),
                                                  bottomLeft: Radius.circular(mine ? 18 : 4),
                                                  bottomRight: Radius.circular(mine ? 4 : 18),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.06),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                text,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: mine ? Colors.white : AppColors.textPrimary,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                    ),
                                    if (!mine)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4, bottom: 2),
                                        child: Text(
                                          _formatTime(createdAt),
                                          style: const TextStyle(fontSize: 10, color: Colors.white70),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                    },
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Row(
                        children: [
                          _uploadingImage
                              ? const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ruri),
                                  ),
                                )
                              : IconButton(
                                  onPressed: _showImageOptions,
                                  icon: const Icon(Icons.add, color: AppColors.ruri),
                                  tooltip: '画像を添付',
                                ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.chipUnselected,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                minLines: 1,
                                maxLines: 4,
                                maxLength: AppConstants.maxMessageLength,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                                decoration: const InputDecoration(
                                  hintText: 'メッセージを入力',
                                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 15),
                                  border: InputBorder.none,
                                  counterText: '',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Material(
                            color: _sending ? AppColors.textHint : AppColors.ruri,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _sending ? null : _send,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                child: _sending
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.send, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
