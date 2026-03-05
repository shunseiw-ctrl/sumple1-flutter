import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';

class BankAccountSettingsPage extends StatefulWidget {
  const BankAccountSettingsPage({super.key});

  @override
  State<BankAccountSettingsPage> createState() =>
      _BankAccountSettingsPageState();
}

class _BankAccountSettingsPageState extends State<BankAccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _bankNameCtrl = TextEditingController();
  final _branchNameCtrl = TextEditingController();
  final _branchCodeCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();

  String _accountType = 'ordinary'; // ordinary | current
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('bank_account_settings');
    _loadBankAccount();
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _branchNameCtrl.dispose();
    _branchCodeCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBankAccount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(uid)
          .get();
      final data = doc.data();
      final bank = data?['bankAccount'];
      if (bank is Map<String, dynamic>) {
        _bankNameCtrl.text = (bank['bankName'] ?? '').toString();
        _branchNameCtrl.text = (bank['branchName'] ?? '').toString();
        _branchCodeCtrl.text = (bank['branchCode'] ?? '').toString();
        _accountNumberCtrl.text = (bank['accountNumber'] ?? '').toString();
        _accountHolderCtrl.text = (bank['accountHolder'] ?? '').toString();
        _accountType = (bank['accountType'] ?? 'ordinary').toString();
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('profiles').doc(uid).set({
        'bankAccount': {
          'bankName': _bankNameCtrl.text.trim(),
          'branchName': _branchNameCtrl.text.trim(),
          'branchCode': _branchCodeCtrl.text.trim(),
          'accountType': _accountType,
          'accountNumber': _accountNumberCtrl.text.trim(),
          'accountHolder': _accountHolderCtrl.text.trim(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ErrorHandler.showSuccess(context, context.l10n.bankAccount_saved);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e,
          customMessage: context.l10n.bankAccount_saveFailed);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  static final _katakanaRegex = RegExp(r'^[ァ-ヶー　 ]+$');
  static final _digitRegex = RegExp(r'^\d+$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.bankAccount_title),
        actions: [
          TextButton(
            onPressed: (_isLoading || _isSaving) ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.bankAccount_save),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AbsorbPointer(
                  absorbing: _isSaving,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.pagePadding),
                      children: [
                        // 銀行名
                        TextFormField(
                          controller: _bankNameCtrl,
                          decoration: InputDecoration(
                            labelText: context.l10n.bankAccount_bankName,
                            hintText: context.l10n.bankAccount_bankNameHint,
                          ),
                          maxLength: 50,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return context.l10n.bankAccount_required;
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),

                        // 支店名
                        TextFormField(
                          controller: _branchNameCtrl,
                          decoration: InputDecoration(
                            labelText: context.l10n.bankAccount_branchName,
                          ),
                          maxLength: 50,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return context.l10n.bankAccount_required;
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),

                        // 支店コード（3桁）
                        TextFormField(
                          controller: _branchCodeCtrl,
                          decoration: InputDecoration(
                            labelText: context.l10n.bankAccount_branchCode,
                            hintText: '001',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return context.l10n.bankAccount_required;
                            }
                            if (v.trim().length != 3 ||
                                !_digitRegex.hasMatch(v.trim())) {
                              return context.l10n.bankAccount_branchCodeInvalid;
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),

                        // 口座種別
                        DropdownButtonFormField<String>(
                          value: _accountType,
                          decoration: InputDecoration(
                            labelText: context.l10n.bankAccount_accountType,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'ordinary',
                              child: Text(
                                  context.l10n.bankAccount_accountTypeOrdinary),
                            ),
                            DropdownMenuItem(
                              value: 'current',
                              child: Text(
                                  context.l10n.bankAccount_accountTypeCurrent),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _accountType = v);
                          },
                        ),
                        const SizedBox(height: 12),

                        // 口座番号（7桁）
                        TextFormField(
                          controller: _accountNumberCtrl,
                          decoration: InputDecoration(
                            labelText: context.l10n.bankAccount_accountNumber,
                            hintText: '1234567',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 7,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return context.l10n.bankAccount_required;
                            }
                            if (v.trim().length != 7 ||
                                !_digitRegex.hasMatch(v.trim())) {
                              return context
                                  .l10n.bankAccount_accountNumberInvalid;
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),

                        // 口座名義（カタカナ）
                        TextFormField(
                          controller: _accountHolderCtrl,
                          decoration: InputDecoration(
                            labelText:
                                context.l10n.bankAccount_accountHolderName,
                            hintText:
                                context.l10n.bankAccount_accountHolderHint,
                          ),
                          maxLength: 60,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return context.l10n.bankAccount_required;
                            }
                            if (!_katakanaRegex.hasMatch(v.trim())) {
                              return context
                                  .l10n.bankAccount_accountHolderInvalid;
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _isSaving) ? null : _save,
                            child: Text(context.l10n.bankAccount_save),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
