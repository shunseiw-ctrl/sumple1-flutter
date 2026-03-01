import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/services/analytics_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '未設定';

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント設定', style: TextStyle(fontWeight: FontWeight.w800)),
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
                Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('メールアドレス', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
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
          Text('表示名', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: '名前を入力',
              suffixIcon: IconButton(
                onPressed: _saving ? null : _updateDisplayName,
                icon: Icon(Icons.check, color: AppColors.ruri),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // パスワード変更
          Text('パスワード変更', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
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
                  : const Text('パスワードを変更'),
            ),
          ),

          const SizedBox(height: 32),

          // アカウント削除
          Center(
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('アカウント削除'),
                    content: const Text('アカウントを削除すると、全てのデータが失われます。この操作は取り消せません。\n\n削除を希望される場合は、お問い合わせよりご連絡ください。'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる')),
                    ],
                  ),
                );
              },
              child: Text('アカウントを削除', style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
