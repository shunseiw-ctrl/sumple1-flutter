import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';

/// 管理者向け下書き一覧ページ
class AdminDraftsPage extends StatelessWidget {
  const AdminDraftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(
          context.l10n.adminDrafts_title,
          style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('status', isEqualTo: 'draft')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                context.l10n.adminDrafts_empty,
                style: TextStyle(color: context.appColors.textSecondary),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.listInsets,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = (data['title'] ?? '').toString();
              final location = (data['location'] ?? '').toString();
              final date = (data['date'] ?? '').toString();

              return _DraftCard(
                title: title,
                location: location,
                date: date,
                onPublish: () => _publishDraft(context, doc.id),
                onDelete: () => _deleteDraft(context, doc.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _publishDraft(BuildContext context, String jobId) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 'published',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppHaptics.success();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminDrafts_published)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminDrafts_publishFailed)),
        );
      }
    }
  }

  Future<void> _deleteDraft(BuildContext context, String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.adminDrafts_delete),
        content: Text(context.l10n.adminDrafts_deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.adminWorkReports_feedbackCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.adminDrafts_delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
      AppHaptics.success();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminDrafts_deleted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminDrafts_deleteFailed)),
        );
      }
    }
  }
}

class _DraftCard extends StatelessWidget {
  final String title;
  final String location;
  final String date;
  final VoidCallback onPublish;
  final VoidCallback onDelete;

  const _DraftCard({
    required this.title,
    required this.location,
    required this.date,
    required this.onPublish,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isNotEmpty ? title : '(タイトルなし)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          if (location.isNotEmpty)
            Text(location, style: TextStyle(fontSize: 12, color: context.appColors.textSecondary)),
          if (date.isNotEmpty)
            Text(date, style: TextStyle(fontSize: 12, color: context.appColors.textHint)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, size: 16, color: context.appColors.error),
                label: Text(
                  context.l10n.adminDrafts_delete,
                  style: TextStyle(fontSize: 12, color: context.appColors.error),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onPublish,
                icon: const Icon(Icons.publish, size: 16),
                label: Text(context.l10n.adminDrafts_publish, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
