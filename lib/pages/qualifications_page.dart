import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
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
      return const Scaffold(
        body: Center(child: Text('ログインが必要です')),
      );
    }

    final service = qualificationService ?? QualificationService();

    return Scaffold(
      appBar: AppBar(title: const Text('資格管理')),
      body: StreamBuilder<List<QualificationModel>>(
        stream: service.watchQualifications(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('エラー: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final quals = snap.data!;
          if (quals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, size: 48, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('登録された資格はありません', style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('右下のボタンから追加できます', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
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
        backgroundColor: AppColors.ruri,
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
      statusText = '承認済み';
    } else if (qual.isPending) {
      statusColor = Colors.orange;
      statusText = '審査中';
    } else {
      statusColor = Colors.red;
      statusText = '却下';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.workspace_premium,
          color: qual.isVerified ? Colors.green : AppColors.textHint,
        ),
        title: Text(qual.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(categoryLabel, style: const TextStyle(fontSize: 12)),
            if (qual.expiryDate != null)
              Text(
                '有効期限: ${qual.expiryDate}${qual.isExpired ? ' (期限切れ)' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: qual.isExpired ? Colors.red : AppColors.textSecondary,
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
