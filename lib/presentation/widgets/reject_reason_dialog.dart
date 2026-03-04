import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

/// 却下理由入力ダイアログ（共通）
Future<String?> showRejectReasonDialog(
  BuildContext context, {
  String? title,
  String? hintText,
}) async {
  final reasonCtrl = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title ?? context.l10n.adminApproval_rejectReasonTitle),
      content: TextField(
        controller: reasonCtrl,
        decoration: InputDecoration(
          hintText: hintText ?? context.l10n.adminApproval_rejectReasonHint,
          border: const OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(context.l10n.common_cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.error,
            foregroundColor: Colors.white,
          ),
          child: Text(context.l10n.adminApproval_rejectButton),
        ),
      ],
    ),
  );

  if (confirmed != true) {
    reasonCtrl.dispose();
    return null;
  }

  final reason = reasonCtrl.text.trim();
  reasonCtrl.dispose();

  if (reason.isEmpty) return null;
  return reason;
}
