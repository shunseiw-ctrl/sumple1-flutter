import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

/// 日報フィードバック入力ダイアログ
class WorkReportFeedbackDialog extends StatefulWidget {
  final String reportDate;

  const WorkReportFeedbackDialog({super.key, required this.reportDate});

  @override
  State<WorkReportFeedbackDialog> createState() => _WorkReportFeedbackDialogState();
}

class _WorkReportFeedbackDialogState extends State<WorkReportFeedbackDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.adminWorkReports_feedbackTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.reportDate,
            style: TextStyle(
              fontSize: 13,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: context.l10n.adminWorkReports_feedbackHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.adminWorkReports_feedbackCancel),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              Navigator.pop(context, text);
            }
          },
          child: Text(context.l10n.adminWorkReports_feedbackSubmit),
        ),
      ],
    );
  }
}
