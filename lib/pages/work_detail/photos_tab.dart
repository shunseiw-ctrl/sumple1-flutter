import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/image_upload_service.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';

class WorkPhotosTab extends StatefulWidget {
  final String applicationId;
  final String jobId;
  const WorkPhotosTab({super.key, required this.applicationId, required this.jobId});

  @override
  State<WorkPhotosTab> createState() => _WorkPhotosTabState();
}

class _WorkPhotosTabState extends State<WorkPhotosTab> {
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
          SnackBar(content: Text(context.l10n.workPhotos_uploadSuccess(successCount.toString()))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.workPhotos_uploadFailed(e.toString()))),
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
        title: Text(context.l10n.workPhotos_deleteTitle),
        content: Text(context.l10n.workPhotos_deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.workPhotos_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.appColors.error),
            child: Text(context.l10n.workPhotos_delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _photosRef.doc(docId).delete();
      await _imageService.deleteImage(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.workPhotos_deleteSuccess)));
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
              Icon(Icons.photo_library, size: 20, color: context.appColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(context.l10n.workPhotos_title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
              if (_uploading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                ElevatedButton.icon(
                  onPressed: _uploadPhotos,
                  icon: const Icon(Icons.add_a_photo, size: 18),
                  label: Text(context.l10n.workPhotos_add),
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
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_outlined, size: 56, color: context.appColors.textHint),
                      const SizedBox(height: 12),
                      Text(context.l10n.workPhotos_noPhotos, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.appColors.textSecondary)),
                      const SizedBox(height: 6),
                      Text(context.l10n.workPhotos_uploadHint, style: TextStyle(fontSize: 13, color: context.appColors.textHint)),
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
                                    child: AppCachedImage(
                                      imageUrl: url,
                                      fit: BoxFit.contain,
                                      borderRadius: 12,
                                      errorWidget: const SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image))),
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
                                  icon: Icon(Icons.delete, color: context.appColors.error, size: 18),
                                  label: Text(context.l10n.workPhotos_delete, style: TextStyle(color: context.appColors.error)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: AppCachedImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      borderRadius: 8,
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
