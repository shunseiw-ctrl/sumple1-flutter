import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/inspection_service.dart';
import '../../core/services/activity_log_service.dart';
import '../../core/utils/haptic_utils.dart';
import '../../data/models/inspection_model.dart';

/// 検査チェックリストページ（管理者用）
class InspectionPage extends StatefulWidget {
  final String applicationId;

  const InspectionPage({super.key, required this.applicationId});

  @override
  State<InspectionPage> createState() => _InspectionPageState();
}

class _InspectionPageState extends State<InspectionPage> {
  final _commentController = TextEditingController();
  late final List<_CheckState> _checks;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checks = InspectionModel.defaultCheckItems
        .map((label) => _CheckState(label: label))
        .toList();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _computeResult() {
    final hasFail = _checks.any((c) => c.result == 'fail');
    final allPass = _checks.every((c) => c.result == 'pass' || c.result == 'na');
    if (hasFail) return 'failed';
    if (allPass) return 'passed';
    return 'partial';
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      final result = _computeResult();
      final items = _checks
          .map((c) => InspectionCheckItem(
                label: c.label,
                result: c.result,
                comment: c.comment.isEmpty ? null : c.comment,
              ))
          .toList();

      await InspectionService().submitInspection(
        applicationId: widget.applicationId,
        result: result,
        items: items,
        overallComment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      // 検査結果に応じてステータス自動遷移
      final newStatus = result == 'passed' ? 'done' : 'fixing';
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await ActivityLogService().logEvent(
        applicationId: widget.applicationId,
        eventType: 'inspection_completed',
        description: '検査完了: ${result == 'passed' ? '合格' : '要修正'}',
        metadata: {'result': result},
      );

      AppHaptics.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result == 'passed' ? '検査合格 → 完了' : '検査不合格 → 修正依頼'),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('検査提出に失敗: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('施工検査')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'チェックリスト',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ..._checks.map((check) => _CheckItemWidget(
                check: check,
                onChanged: () => setState(() {}),
              )),
          const SizedBox(height: 16),
          TextFormField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '総合コメント',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ruri,
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('検査結果を提出',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckState {
  final String label;
  String result; // 'pass' | 'fail' | 'na'
  String comment;

  // ignore: unused_element_parameter
  _CheckState({required this.label, this.result = 'na', this.comment = ''});
}

class _CheckItemWidget extends StatelessWidget {
  final _CheckState check;
  final VoidCallback onChanged;

  const _CheckItemWidget({required this.check, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(check.label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                _ResultChip(
                  label: '合格',
                  selected: check.result == 'pass',
                  color: Colors.green,
                  onTap: () {
                    check.result = 'pass';
                    onChanged();
                  },
                ),
                const SizedBox(width: 8),
                _ResultChip(
                  label: '不合格',
                  selected: check.result == 'fail',
                  color: Colors.red,
                  onTap: () {
                    check.result = 'fail';
                    onChanged();
                  },
                ),
                const SizedBox(width: 8),
                _ResultChip(
                  label: 'N/A',
                  selected: check.result == 'na',
                  color: Colors.grey,
                  onTap: () {
                    check.result = 'na';
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ResultChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
