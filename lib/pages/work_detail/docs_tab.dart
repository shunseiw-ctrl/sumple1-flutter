import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/image_upload_service.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';

/// 資料管理タブ（御見積書・図面・仕様・工程・その他）
class WorkDocsTab extends StatefulWidget {
  final String applicationId;
  const WorkDocsTab({super.key, required this.applicationId});

  @override
  State<WorkDocsTab> createState() => _WorkDocsTabState();
}

class _WorkDocsTabState extends State<WorkDocsTab> {
  final _imageService = ImageUploadService();
  bool _uploading = false;
  String _selectedFolder = '御見積書';

  static const folders = ['御見積書', '図面', '仕様', '工程', 'その他'];

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
            SnackBar(content: Text(context.l10n.workDocs_uploadSuccess(_selectedFolder))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.workDocs_uploadFailed(e.toString()))),
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
              Icon(Icons.folder_outlined, size: 20, color: context.appColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(context.l10n.workDocs_title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
              if (_uploading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                ElevatedButton.icon(
                  onPressed: _uploadDoc,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(context.l10n.workDocs_add),
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
            children: folders.map((f) {
              final selected = f == _selectedFolder;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(f, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedFolder = f),
                  selectedColor: context.appColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : context.appColors.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  backgroundColor: context.appColors.chipUnselected,
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
                      Icon(Icons.folder_off_outlined, size: 48, color: context.appColors.textHint),
                      const SizedBox(height: 12),
                      Text(context.l10n.workDocs_noDocuments(_selectedFolder), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.appColors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final data = docs[i].data();
                  final url = (data['url'] ?? '').toString();
                  final createdAt = data['createdAt'];
                  String dateStr = '';
                  if (createdAt is Timestamp) {
                    final d = createdAt.toDate();
                    dateStr = '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                  }

                  return _DocCard(
                    child: Row(
                      children: [
                        AppCachedImage(
                          imageUrl: url,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          borderRadius: 8,
                          errorWidget: Container(
                            width: 60,
                            height: 60,
                            color: context.appColors.chipUnselected,
                            child: Icon(Icons.description, color: context.appColors.textHint),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedFolder, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              if (dateStr.isNotEmpty)
                                Text(dateStr, style: TextStyle(fontSize: 12, color: context.appColors.textHint)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: context.appColors.error, size: 20),
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

class _DocCard extends StatelessWidget {
  final Widget child;
  const _DocCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface,
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
