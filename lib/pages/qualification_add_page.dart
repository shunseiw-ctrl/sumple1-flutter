import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/extensions/build_context_extensions.dart';
import '../core/services/qualification_service.dart';
import '../core/utils/haptic_utils.dart';

/// 資格追加ページ
class QualificationAddPage extends StatefulWidget {
  const QualificationAddPage({super.key});

  @override
  State<QualificationAddPage> createState() => _QualificationAddPageState();
}

class _QualificationAddPageState extends State<QualificationAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCategory = 'other';
  String? _expiryDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        _expiryDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await QualificationService().addQualification(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        expiryDate: _expiryDate,
      );
      AppHaptics.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.qualificationAdd_registered)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.qualificationAdd_registerFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.qualificationAdd_title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: context.l10n.qualificationAdd_categoryLabel,
                border: const OutlineInputBorder(),
              ),
              items: AppConstants.qualificationCategories.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              maxLength: AppConstants.maxQualificationNameLength,
              decoration: InputDecoration(
                labelText: context.l10n.qualificationAdd_nameLabel,
                hintText: context.l10n.qualificationAdd_nameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return context.l10n.qualificationAdd_nameRequired;
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(context.l10n.qualificationAdd_expiryDate),
              subtitle: Text(_expiryDate ?? context.l10n.qualificationAdd_noExpiry),
              trailing: const Icon(Icons.edit),
              onTap: _pickExpiryDate,
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
                            strokeWidth: 2, color: Colors.white))
                    : Text(context.l10n.qualificationAdd_register, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
