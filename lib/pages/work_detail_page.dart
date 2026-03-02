import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_room_page.dart';
import 'job_detail_page.dart';
import 'qr_checkin_page.dart';
import 'shift_qr_page.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/services/image_upload_service.dart';
import 'package:sumple1/presentation/widgets/rating_dialog.dart';
import 'package:sumple1/core/services/notification_service.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/core/services/analytics_service.dart';

class WorkDetailPage extends StatefulWidget {
  final String applicationId;
  const WorkDetailPage({super.key, required this.applicationId});

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _notAnonymous(User? u) => u != null && !u.isAnonymous;

  bool _isAdminUser = false;

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.trim().isEmpty) {
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.doc('config/admins').get();
      final data = doc.data();
      final emails = (data?['emails'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final adminUids = (data?['adminUids'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (mounted) {
        setState(() {
          _isAdminUser = emails.contains(email) || adminUids.contains(user?.uid);
        });
      }
    } catch (e) {
      Logger.warning('管理者チェックに失敗', tag: 'WorkDetail', data: {'error': '$e'});
    }
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('work_detail');
    _tabController = TabController(length: 3, vsync: this);
    _checkAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _statusLabel(String key) {
    switch (key) {
      case 'assigned':
        return '着工前';
      case 'applied':
        return '応募中';
      case 'in_progress':
        return '着工中';
      case 'completed':
        return '施工完了';
      case 'inspection':
        return '検収中';
      case 'fixing':
        return '是正中';
      case 'done':
        return '完了';
      default:
        return key;
    }
  }

  Future<bool> _hasRated(String applicationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap = await FirebaseFirestore.instance
        .collection('ratings')
        .where('applicationId', isEqualTo: applicationId)
        .where('raterUid', isEqualTo: uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> _updateStatus(String newStatus) async {
    await FirebaseFirestore.instance
        .collection('applications')
        .doc(widget.applicationId)
        .update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (!_notAnonymous(user)) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text('「はたらく」を使うにはログインが必要です'),
          ),
        ),
      );
    }

    final uid = user!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('読み込みエラー: ${snap.error}')));
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final doc = snap.data!;
        if (!doc.exists) {
          return const Scaffold(body: Center(child: Text('この案件は存在しません')));
        }

        final app = doc.data() ?? <String, dynamic>{};

        final applicantUid = (app['applicantUid'] ?? '').toString();
        if (applicantUid.isNotEmpty && applicantUid != uid && !_isAdminUser) {
          return const Scaffold(body: Center(child: Text('権限がありません')));
        }

        final title = (app['jobTitleSnapshot'] ?? '案件').toString();
        final status = (app['status'] ?? 'applied').toString();

        final canStart = status == 'assigned' || status == 'applied';
        final canComplete = status == 'in_progress';

        final jobId = (app['jobId'] ?? '').toString();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
            ),
            actions: [
              if (_isAdminUser && jobId.isNotEmpty)
                IconButton(
                  tooltip: 'QR出退勤管理',
                  icon: const Icon(Icons.qr_code),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShiftQrPage(
                          jobId: jobId,
                          jobTitle: title,
                        ),
                      ),
                    );
                  },
                ),
              IconButton(
                tooltip: 'チャット',
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomPage(applicationId: widget.applicationId),
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.ruri,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.ruri,
              tabs: const [
                Tab(text: '概要'),
                Tab(text: '写真'),
                Tab(text: '資料'),
              ],
            ),
          ),
          body: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF1F4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: canStart
                          ? () async {
                        try {
                          await _updateStatus('in_progress');
                          final applicantUid = (app['applicantUid'] ?? '').toString();
                          if (applicantUid.isNotEmpty) {
                            NotificationService().createNotification(
                              targetUid: applicantUid,
                              title: 'ステータス更新',
                              body: '$titleが「着工中」になりました',
                              type: 'status_update',
                            );
                          }
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('開始しました（着工中）')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('開始に失敗: $e')),
                          );
                        }
                      }
                          : null,
                      child: const Text('開始'),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: canComplete
                          ? () async {
                        try {
                          await _updateStatus('completed');
                          final applicantUid = (app['applicantUid'] ?? '').toString();
                          if (applicantUid.isNotEmpty) {
                            NotificationService().createNotification(
                              targetUid: applicantUid,
                              title: 'ステータス更新',
                              body: '$titleが「施工完了」になりました',
                              type: 'status_update',
                            );
                          }
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('完了しました（施工完了）')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('完了に失敗: $e')),
                          );
                        }
                      }
                          : null,
                      child: const Text('完了'),
                    ),
                    const SizedBox(width: 6),
                    if (status == 'done' && _isAdminUser)
                      FutureBuilder<bool>(
                        future: _hasRated(widget.applicationId),
                        builder: (context, ratingSnap) {
                          final hasRated = ratingSnap.data == true;
                          if (hasRated) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text('評価済み', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
                                ],
                              ),
                            );
                          }
                          return ElevatedButton.icon(
                            onPressed: () {
                              RatingDialog.show(
                                context,
                                applicationId: widget.applicationId,
                                jobId: jobId,
                                jobTitle: title,
                                targetUid: applicantUid,
                              );
                            },
                            icon: const Icon(Icons.star_rounded, size: 18),
                            label: const Text('評価する'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              if (status == 'in_progress' || status == 'assigned')
                const Divider(height: 1, color: AppColors.divider),
              if (status == 'in_progress' || status == 'assigned')
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Builder(
                    builder: (context) {
                      final checkInStatus = (app['checkInStatus'] ?? '').toString();
                      final isCheckedIn = checkInStatus == 'checked_in';
                      final isCheckedOut = checkInStatus == 'checked_out';

                      return Row(
                        children: [
                          Icon(
                            isCheckedIn ? Icons.location_on : Icons.location_off_outlined,
                            color: isCheckedIn ? Colors.green : AppColors.textHint,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCheckedOut
                                ? '退勤済み'
                                : isCheckedIn
                                    ? '出勤中'
                                    : '未出勤',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isCheckedIn ? Colors.green : AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          if (!isCheckedIn && !isCheckedOut)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QrCheckinPage(
                                      applicationId: widget.applicationId,
                                      isCheckOut: false,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.qr_code_scanner, size: 18),
                              label: const Text('QR出勤'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          if (isCheckedIn && !isCheckedOut)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QrCheckinPage(
                                      applicationId: widget.applicationId,
                                      isCheckOut: true,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.qr_code_scanner, size: 18),
                              label: const Text('QR退勤'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          if (isCheckedOut)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.chipUnselected,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text('完了', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(app: app, jobId: jobId),
                    _PhotosTab(applicationId: widget.applicationId, jobId: jobId),
                    _DocsTab(applicationId: widget.applicationId),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> app;
  final String jobId;

  const _OverviewTab({required this.app, required this.jobId});

  @override
  Widget build(BuildContext context) {
    if (jobId.trim().isEmpty) {
      final title = (app['jobTitleSnapshot'] ?? '').toString();
      final location = (app['jobLocationSnapshot'] ?? '').toString();
      final price = (app['jobPriceSnapshot'] ?? '').toString();
      final date = (app['jobDateSnapshot'] ?? '').toString();

      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('概要', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 10),
                Text('案件名: ${title.isNotEmpty ? title : "-"}'),
                Text('場所: ${location.isNotEmpty ? location : "-"}'),
                Text('報酬: ${price.isNotEmpty ? price : "-"}'),
                Text('日程: ${date.isNotEmpty ? date : "未定"}'),
                const SizedBox(height: 12),
                const Text(
                  '※jobIdが無いデータのため、詳細本文を表示できません',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('jobs').doc(jobId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('読み込みエラー: ${snap.error}'));
        }
        final doc = snap.data;
        if (doc == null || !doc.exists) {
          return const Center(child: Text('案件が見つかりません'));
        }

        final jobData = doc.data() ?? <String, dynamic>{};

        return JobDetailBody(data: jobData);
      },
    );
  }
}

class _PhotosTab extends StatefulWidget {
  final String applicationId;
  final String jobId;
  const _PhotosTab({required this.applicationId, required this.jobId});

  @override
  State<_PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<_PhotosTab> {
  final _imageService = ImageUploadService();
  bool _uploading = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _photosRef =>
      FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .collection('photos');

  Future<void> _uploadPhotos() async {
    if (_uploading || _uid.isEmpty) return;
    setState(() => _uploading = true);

    try {
      final results = await _imageService.pickAndUploadMultipleImages(
        userId: _uid,
        folder: 'work_photos/${widget.jobId}',
        documentId: 'photo',
        maxImages: 10,
        quality: 80,
      );

      for (final result in results) {
        if (result.isSuccess && result.downloadUrl != null) {
          await _photosRef.add({
            'url': result.downloadUrl,
            'uploadedBy': _uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      final successCount = results.where((r) => r.isSuccess).length;
      if (mounted && successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$successCount枚の写真をアップロードしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アップロードに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deletePhoto(String docId, String url) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('写真を削除'),
        content: const Text('この写真を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _photosRef.doc(docId).delete();
      await _imageService.deleteImage(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('写真を削除しました')));
      }
    } catch (e) {
      Logger.warning('写真の削除に失敗', tag: 'WorkDetail', data: {'docId': docId, 'error': '$e'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              const Icon(Icons.photo_library, size: 20, color: AppColors.ruri),
              const SizedBox(width: 8),
              const Expanded(child: Text('現場写真', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
              if (_uploading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                ElevatedButton.icon(
                  onPressed: _uploadPhotos,
                  icon: const Icon(Icons.add_a_photo, size: 18),
                  label: const Text('追加'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _photosRef.orderBy('createdAt', descending: true).limit(200).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_outlined, size: 56, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text('写真はまだありません', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      SizedBox(height: 6),
                      Text('「追加」ボタンから写真をアップロード', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data();
                  final url = (data['url'] ?? '').toString();
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          insetPadding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(url, fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image))),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      style: IconButton.styleFrom(backgroundColor: Colors.black45),
                                      onPressed: () => Navigator.pop(ctx),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _deletePhoto(docs[i].id, url);
                                  },
                                  icon: const Icon(Icons.delete, color: AppColors.error, size: 18),
                                  label: const Text('削除', style: TextStyle(color: AppColors.error)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.chipUnselected,
                          child: const Icon(Icons.broken_image, color: AppColors.textHint),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DocsTab extends StatefulWidget {
  final String applicationId;
  const _DocsTab({required this.applicationId});

  @override
  State<_DocsTab> createState() => _DocsTabState();
}

class _DocsTabState extends State<_DocsTab> {
  final _imageService = ImageUploadService();
  bool _uploading = false;
  String _selectedFolder = '御見積書';

  static const _folders = ['御見積書', '図面', '仕様', '工程', 'その他'];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _docsRef =>
      FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .collection('documents');

  Future<void> _uploadDoc() async {
    if (_uploading || _uid.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final result = await _imageService.pickAndUploadImage(
        userId: _uid,
        folder: 'work_documents/${widget.applicationId}',
        documentId: 'doc_$_selectedFolder',
        quality: 90,
        compress: false,
      );

      if (result.isSuccess && result.downloadUrl != null) {
        await _docsRef.add({
          'url': result.downloadUrl,
          'folder': _selectedFolder,
          'uploadedBy': _uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$_selectedFolderにアップロードしました')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アップロードに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              const Icon(Icons.folder_outlined, size: 20, color: AppColors.ruri),
              const SizedBox(width: 8),
              const Expanded(child: Text('資料管理', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
              if (_uploading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                ElevatedButton.icon(
                  onPressed: _uploadDoc,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('追加'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _folders.map((f) {
              final selected = f == _selectedFolder;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(f, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedFolder = f),
                  selectedColor: AppColors.ruri,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  backgroundColor: AppColors.chipUnselected,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _docsRef
                .where('folder', isEqualTo: _selectedFolder)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_off_outlined, size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('「$_selectedFolder」の資料はまだありません', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final data = docs[i].data();
                  final url = (data['url'] ?? '').toString();
                  final createdAt = data['createdAt'];
                  String dateStr = '';
                  if (createdAt is Timestamp) {
                    final d = createdAt.toDate();
                    dateStr = '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                  }

                  return _Card(
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 60, height: 60,
                            child: Image.network(url, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.chipUnselected,
                                child: const Icon(Icons.description, color: AppColors.textHint),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedFolder, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              if (dateStr.isNotEmpty)
                                Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          onPressed: () async {
                            try {
                              await _docsRef.doc(docs[i].id).delete();
                              await _imageService.deleteImage(url);
                            } catch (e) {
                              Logger.warning('資料の削除に失敗', tag: 'WorkDetail', data: {'error': '$e'});
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EB)),
        ),
        child: child,
      ),
    );
  }
}
