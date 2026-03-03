import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/extensions/build_context_extensions.dart';
import '../core/router/route_paths.dart';
import '../core/services/qualification_service.dart';
import '../data/models/qualification_model.dart';

/// 資格一覧ページ
class QualificationsPage extends StatelessWidget {
  final QualificationService? qualificationService;

  const QualificationsPage({super.key, this.qualificationService});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.qualifications_loginRequired)),
      );
    }

    final service = qualificationService ?? QualificationService();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.qualifications_title)),
      body: StreamBuilder<List<QualificationModel>>(
        stream: service.watchQualifications(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(context.l10n.qualifications_error(snap.error.toString())));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final quals = snap.data!;
          if (quals.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, size: 48, color: context.appColors.textHint),
                  const SizedBox(height: 12),
                  Text(context.l10n.qualifications_empty, style: TextStyle(color: context.appColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(context.l10n.qualifications_addHint, style: TextStyle(color: context.appColors.textHint, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: quals.length,
            itemBuilder: (context, index) {
              final qual = quals[index];
              return _QualificationCard(qual: qual);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(RoutePaths.qualificationAdd);
        },
        backgroundColor: context.appColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _QualificationCard extends StatelessWidget {
  final QualificationModel qual;
  const _QualificationCard({required this.qual});

  @override
  Widget build(BuildContext context) {
    final categoryLabel =
        AppConstants.qualificationCategories[qual.category] ?? qual.category;

    Color statusColor;
    String statusText;
    if (qual.isVerified) {
      statusColor = Colors.green;
      statusText = context.l10n.qualifications_approved;
    } else if (qual.isPending) {
      statusColor = Colors.orange;
      statusText = context.l10n.qualifications_pending;
    } else {
      statusColor = Colors.red;
      statusText = context.l10n.qualifications_rejected;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.workspace_premium,
          color: qual.isVerified ? Colors.green : context.appColors.textHint,
        ),
        title: Text(qual.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(categoryLabel, style: const TextStyle(fontSize: 12)),
            if (qual.expiryDate != null)
              Text(
                context.l10n.qualifications_expiryDate(qual.expiryDate!, qual.isExpired ? context.l10n.qualifications_expired : ''),
                style: TextStyle(
                  fontSize: 12,
                  color: qual.isExpired ? Colors.red : context.appColors.textSecondary,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
