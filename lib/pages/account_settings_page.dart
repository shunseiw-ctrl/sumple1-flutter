import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/services/account_service.dart';
import 'package:sumple1/l10n/app_localizations.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _nameController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('account_settings');
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';
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
      final user = FirebaseAuth.instance.currentUser;
      await user?.updateDisplayName(name);

      // Firestoreのprofileも更新
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .set({'displayName': name}, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('表示名を更新しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
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
        const SnackBar(content: Text('現在のパスワードと新しいパスワードを入力してください')),
      );
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('パスワードは6文字以上にしてください')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user == null || email == null) throw Exception('ログインが必要です');

      // 再認証
      final cred = EmailAuthProvider.credential(email: email, password: currentPass);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPass);

      _currentPassController.clear();
      _newPassController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('パスワードを変更しました')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = e.code == 'wrong-password'
            ? '現在のパスワードが正しくありません'
            : 'パスワード変更に失敗しました: ${e.code}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
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
          const SnackBar(content: Text('データをクリップボードにコピーしました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データエクスポートに失敗しました: $e')),
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
        title: Text(AppLocalizations.of(context)!.deleteAccount),
        content: const Text(
          'アカウントを削除すると、全てのデータが完全に失われます。\n\n'
          '・プロフィール情報\n'
          '・応募履歴\n'
          '・チャット履歴\n'
          '・お気に入り\n'
          '・通知\n\n'
          'この操作は取り消せません。本当に削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: AppColors.error)),
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
          title: Text(AppLocalizations.of(context)!.confirm),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(hintText: '現在のパスワード'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(AppLocalizations.of(context)!.confirm, style: const TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );

    if (password == null || password.isEmpty || !mounted) return;

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user == null || email == null) throw Exception('ログインが必要です');

      // 再認証
      final cred = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(cred);

      // Step 3: アカウント削除 CF 呼び出し
      final accountService = AccountService();
      await accountService.deleteAccount();

      // Step 4: サインアウト → ゲストホーム画面へ遷移
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        context.go(RoutePaths.home);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = e.code == 'wrong-password'
            ? 'パスワードが正しくありません'
            : 'アカウント削除に失敗しました: ${e.code}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アカウント削除に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '未設定';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountSettings, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // メールアドレス表示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6E8EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
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
          Text(AppLocalizations.of(context)!.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: '名前を入力',
              suffixIcon: IconButton(
                onPressed: _saving ? null : _updateDisplayName,
                icon: const Icon(Icons.check, color: AppColors.ruri),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // パスワード変更
          Text(AppLocalizations.of(context)!.changePassword, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _currentPassController,
            obscureText: true,
            decoration: const InputDecoration(hintText: '現在のパスワード'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newPassController,
            obscureText: true,
            decoration: const InputDecoration(hintText: '新しいパスワード（6文字以上）'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _changePassword,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(AppLocalizations.of(context)!.changePassword),
            ),
          ),

          const SizedBox(height: 32),

          // データダウンロード
          Center(
            child: TextButton.icon(
              onPressed: _saving ? null : _exportData,
              icon: const Icon(Icons.download, color: AppColors.ruri, size: 18),
              label: Text(AppLocalizations.of(context)!.downloadData, style: const TextStyle(color: AppColors.ruri, fontSize: 13)),
            ),
          ),

          const SizedBox(height: 8),

          // アカウント削除
          Center(
            child: TextButton(
              onPressed: _saving ? null : _showDeleteConfirmation,
              child: Text(AppLocalizations.of(context)!.deleteAccount, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
