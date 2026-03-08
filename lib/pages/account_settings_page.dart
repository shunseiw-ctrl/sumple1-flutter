import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/providers/firebase_providers.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/services/account_service.dart';
import 'package:sumple1/core/providers/locale_provider.dart';

class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  ConsumerState<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  final _nameController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _saving = false;
  bool _reengagementEnabled = true;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('account_settings');
    final user = ref.read(firebaseAuthProvider).currentUser;
    _nameController.text = user?.displayName ?? '';
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    try {
      final doc = await ref.read(firestoreProvider).collection('profiles').doc(user.uid).get();
      final data = doc.data() ?? {};
      final prefs = data['notificationPreferences'] as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          _reengagementEnabled = prefs['reengagement'] != false;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleReengagement(bool value) async {
    setState(() => _reengagementEnabled = value);
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    try {
      await ref.read(firestoreProvider).collection('profiles').doc(user.uid).set({
        'notificationPreferences': {'reengagement': value},
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  Future<void> _updateDisplayName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      await user?.updateDisplayName(name);

      // Firestoreのprofileも更新
      if (user != null) {
        await ref.read(firestoreProvider)
            .collection('profiles')
            .doc(user.uid)
            .set({'displayName': name}, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountSettings_snackNameUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountSettings_snackUpdateFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final currentPass = _currentPassController.text;
    final newPass = _newPassController.text;

    if (currentPass.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountSettings_snackEnterBothPasswords)),
      );
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountSettings_snackPasswordMinLength)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      final email = user?.email;
      if (user == null || email == null) throw Exception(context.l10n.accountSettings_loginRequired);

      // 再認証
      final cred = EmailAuthProvider.credential(email: email, password: currentPass);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPass);

      _currentPassController.clear();
      _newPassController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountSettings_snackPasswordChanged)),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = e.code == 'wrong-password'
            ? context.l10n.accountSettings_snackWrongPassword
            : context.l10n.accountSettings_snackPasswordChangeFailed(e.code);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountSettings_snackError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportData() async {
    setState(() => _saving = true);
    try {
      final accountService = AccountService();
      final data = await accountService.exportUserData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountSettings_snackDataCopied)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountSettings_snackExportFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showDeleteConfirmation() async {
    // Step 1: 警告ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.accountSettings_deleteAccount),
        content: Text(
          context.l10n.accountSettings_deleteConfirmMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.accountSettings_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.accountSettings_delete, style: TextStyle(color: context.appColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Step 2: 再認証
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(context.l10n.accountSettings_confirm),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(hintText: context.l10n.accountSettings_currentPasswordHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.accountSettings_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(context.l10n.accountSettings_confirm, style: TextStyle(color: context.appColors.error)),
            ),
          ],
        );
      },
    );

    if (password == null || password.isEmpty || !mounted) return;

    setState(() => _saving = true);
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      final email = user?.email;
      if (user == null || email == null) throw Exception(context.l10n.accountSettings_loginRequired);

      // 再認証
      final cred = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(cred);

      // Step 3: アカウント削除 CF 呼び出し
      final accountService = AccountService();
      await accountService.deleteAccount();

      // Step 4: サインアウト → ゲストホーム画面へ遷移
      await ref.read(firebaseAuthProvider).signOut();

      if (mounted) {
        context.go(RoutePaths.home);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = e.code == 'wrong-password'
            ? context.l10n.accountSettings_snackWrongPassword
            : context.l10n.accountSettings_snackDeleteFailed(e.code);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountSettings_snackDeleteFailedGeneric(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(firebaseAuthProvider).currentUser;
    final email = user?.email ?? context.l10n.accountSettings_notSet;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.accountSettings_title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // メールアドレス表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined, color: context.appColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.accountSettings_emailLabel, style: TextStyle(fontSize: 12, color: context.appColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(email, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 表示名変更
          Text(context.l10n.accountSettings_displayNameLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: context.l10n.accountSettings_nameHint,
              suffixIcon: IconButton(
                onPressed: _saving ? null : _updateDisplayName,
                icon: Icon(Icons.check, color: context.appColors.primary),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // パスワード変更
          Text(context.l10n.accountSettings_changePasswordLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _currentPassController,
            obscureText: true,
            decoration: InputDecoration(hintText: context.l10n.accountSettings_currentPasswordHint),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newPassController,
            obscureText: true,
            decoration: InputDecoration(hintText: context.l10n.accountSettings_newPasswordHint),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _changePassword,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(context.l10n.accountSettings_changePasswordButton),
            ),
          ),

          const SizedBox(height: 28),
          Text(context.l10n.accountSettings_notificationSettings, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined, color: context.appColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(context.l10n.accountSettings_receiveNotifications, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: _reengagementEnabled,
                  onChanged: _toggleReengagement,
                  activeTrackColor: context.appColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 言語設定
          Text(
            context.l10n.accountSettings_languageLabel,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.divider),
            ),
            child: Column(
              children: [
                RadioListTile<Locale>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('日本語', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  value: const Locale('ja'),
                  groupValue: ref.watch(localeProvider),
                  activeColor: context.appColors.primary,
                  onChanged: (v) {
                    if (v != null) ref.read(localeProvider.notifier).setLocale(v);
                  },
                ),
                Divider(height: 1, color: context.appColors.divider),
                RadioListTile<Locale>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('English', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  value: const Locale('en'),
                  groupValue: ref.watch(localeProvider),
                  activeColor: context.appColors.primary,
                  onChanged: (v) {
                    if (v != null) ref.read(localeProvider.notifier).setLocale(v);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // データダウンロード
          Center(
            child: TextButton.icon(
              onPressed: _saving ? null : _exportData,
              icon: Icon(Icons.download, color: context.appColors.primary, size: 18),
              label: Text(context.l10n.accountSettings_downloadData, style: TextStyle(color: context.appColors.primary, fontSize: 13)),
            ),
          ),

          const SizedBox(height: 8),

          // アカウント削除
          Center(
            child: TextButton(
              onPressed: _saving ? null : _showDeleteConfirmation,
              child: Text(context.l10n.accountSettings_deleteAccount, style: TextStyle(color: context.appColors.error, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
