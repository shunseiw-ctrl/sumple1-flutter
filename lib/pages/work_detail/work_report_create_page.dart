import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/build_context_extensions.dart';
import '../../core/services/work_report_service.dart';
import '../../core/services/activity_log_service.dart';
import '../../core/utils/haptic_utils.dart';

/// 日報作成ページ
class WorkReportCreatePage extends StatefulWidget {
  final String applicationId;

  const WorkReportCreatePage({super.key, required this.applicationId});

  @override
  State<WorkReportCreatePage> createState() => _WorkReportCreatePageState();
}

class _WorkReportCreatePageState extends State<WorkReportCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _notesController = TextEditingController();
  final _hoursController = TextEditingController(text: '8.0');
  String _reportDate = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _reportDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _contentController.dispose();
    _notesController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _reportDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final hours = double.tryParse(_hoursController.text) ?? 8.0;
      await WorkReportService().createReport(
        applicationId: widget.applicationId,
        reportDate: _reportDate,
        workContent: _contentController.text.trim(),
        hoursWorked: hours,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // タイムラインにもログ
      await ActivityLogService().logEvent(
        applicationId: widget.applicationId,
        eventType: 'report_submitted',
        description: context.l10n.workReportCreate_logSubmitted(_reportDate),
      );

      AppHaptics.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.workReportCreate_submitted)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.workReportCreate_saveFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.workReportCreate_title),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(context.l10n.workReportCreate_date),
              subtitle: Text(_reportDate),
              trailing: const Icon(Icons.edit),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              maxLines: 5,
              maxLength: AppConstants.maxWorkReportContentLength,
              decoration: InputDecoration(
                labelText: context.l10n.workReportCreate_contentLabel,
                hintText: context.l10n.workReportCreate_contentHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return context.l10n.workReportCreate_contentRequired;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hoursController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: context.l10n.workReportCreate_hoursLabel,
                border: const OutlineInputBorder(),
                suffixText: context.l10n.workReportCreate_hoursSuffix,
              ),
              validator: (v) {
                final hours = double.tryParse(v ?? '');
                if (hours == null || hours <= 0 || hours > 24) {
                  return context.l10n.workReportCreate_hoursValidation;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              maxLength: AppConstants.maxWorkReportNotesLength,
              decoration: InputDecoration(
                labelText: context.l10n.workReportCreate_notesLabel,
                hintText: context.l10n.workReportCreate_notesHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(context.l10n.workReportCreate_submit, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
