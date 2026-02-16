import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_login_page.dart';
import 'email_login_page.dart';
import 'my_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isAnonymous(User? user) => user == null || user.isAnonymous;

  // ✅ ここで保持（disposed raceを根絶）
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  String _authErrorMessageJa(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-not-found':
        return 'このメールアドレスのユーザーが見つかりません';
      case 'wrong-password':
        return 'パスワードが違います';
      case 'email-already-in-use':
        return 'そのメールアドレスは既に使われています';
      case 'weak-password':
        return 'パスワードが弱すぎます（6文字以上推奨）';
      case 'operation-not-allowed':
        return 'Firebase側でメール/パスワード認証が有効化されていません';
      default:
        return '認証エラー: ${e.code}';
    }
  }

  Future<void> _showSnack(String msg) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showEmailAuthDialog() async {
    // ✅ 前回入力の残りが嫌ならここでクリア
    // _emailController.clear();
    // _passController.clear();

    bool obscure = true;
    bool isLoading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isLoading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocalState) {
            Future<void> signIn() async {
              final email = _emailController.text.trim();
              final pass = _passController.text;

              if (email.isEmpty || pass.isEmpty) {
                await _showSnack('メールアドレスとパスワードを入力してください');
                return;
              }

              setLocalState(() => isLoading = true);
              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: email,
                  password: pass,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) setState(() {});
                await _showSnack('ログインしました');
              } on FirebaseAuthException catch (e) {
                await _showSnack(_authErrorMessageJa(e));
              } catch (e) {
                await _showSnack('ログインに失敗しました: $e');
              } finally {
                if (dialogContext.mounted) {
                  setLocalState(() => isLoading = false);
                }
              }
            }

            Future<void> signUp() async {
              final email = _emailController.text.trim();
              final pass = _passController.text;

              if (email.isEmpty || pass.isEmpty) {
                await _showSnack('メールアドレスとパスワードを入力してください');
                return;
              }
              if (pass.length < 6) {
                await _showSnack('パスワードは6文字以上にしてください');
                return;
              }

              setLocalState(() => isLoading = true);
              try {
                final current = FirebaseAuth.instance.currentUser;

                // ✅ 匿名なら同じ uid のままメールアカウントへ昇格（応募履歴などを守れる）
                if (current != null && current.isAnonymous) {
                  final cred = EmailAuthProvider.credential(
                    email: email,
                    password: pass,
                  );
                  await current.linkWithCredential(cred);
                } else {
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: email,
                    password: pass,
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) setState(() {});
                await _showSnack('登録しました（ログイン済み）');
              } on FirebaseAuthException catch (e) {
                await _showSnack(_authErrorMessageJa(e));
              } catch (e) {
                await _showSnack('登録に失敗しました: $e');
              } finally {
                if (dialogContext.mounted) {
                  setLocalState(() => isLoading = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('メールでログイン'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'メールアドレス'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'パスワード',
                      suffixIcon: IconButton(
                        onPressed: () => setLocalState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLoading) const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 8),
                  const Text(
                    '新規登録もこの画面からできます',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: isLoading ? null : signUp,
                  child: const Text('新規登録'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : signIn,
                  child: const Text('ログイン'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAnon = _isAnonymous(user);

    final displayName = isAnon
        ? 'ゲスト'
        : (user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email?.trim().isNotEmpty == true ? user!.email!.trim() : 'ログインユーザー'));

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _ProfileHeaderCard(
            displayName: displayName,
            subtitle: isAnon ? 'ログインすると応募・チャットが使えます' : 'ログイン済み',
            isLoggedIn: !isAnon,
          ),
          const SizedBox(height: 12),

          if (isAnon) ...[
            _InfoBanner(
              title: 'ログインが必要です',
              message: '応募・チャットなど一部機能を利用するにはログインが必要です。',
              buttonText: 'ログイン / 新規登録',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmailLoginPage()),
                ).then((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
            const SizedBox(height: 16),
          ],

          const _SectionHeader(title: 'アカウント'),
          _MenuTile(
            icon: Icons.settings_outlined,
            title: 'アカウント設定',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('アカウント設定（準備中）')),
              );
            },
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.badge_outlined,
            title: 'あなたのプロフィール',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyProfilePage()),
              );
            },
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: 'サポート'),
          _MenuTile(
            icon: Icons.help_outline,
            title: 'よくある質問',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('よくある質問（準備中）')),
              );
            },
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.mail_outline,
            title: 'お問い合わせ',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('お問い合わせ（準備中）')),
              );
            },
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: 'その他'),
          _MenuTile(
            icon: Icons.privacy_tip_outlined,
            title: 'プライバシーポリシー',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('プライバシーポリシー（準備中）')),
              );
            },
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.description_outlined,
            title: '利用規約',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('利用規約（準備中）')),
              );
            },
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: '管理者'),
          _MenuTile(
            icon: Icons.admin_panel_settings_outlined,
            title: '管理者ログイン',
            subtitle: '案件の投稿・編集ができます',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginPage()),
              );
            },
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.logout,
            title: '管理者ログアウト',
            subtitle: isAnon ? '現在ログインしていません' : 'ログアウトして一般ユーザー表示に戻す',
            onTap: () async {
              final auth = FirebaseAuth.instance;
              await auth.signOut();
              await auth.signInAnonymously();

              if (!context.mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ログアウトしました（ゲストに戻りました）')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String displayName;
  final String subtitle;
  final bool isLoggedIn;

  const _ProfileHeaderCard({
    required this.displayName,
    required this.subtitle,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.black12,
            child: Icon(Icons.person, color: Colors.black54, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isLoggedIn ? Colors.green.shade50 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.black12),
            ),
            child: Text(
              isLoggedIn ? 'ログイン済み' : 'ゲスト',
              style: TextStyle(
                fontSize: 12,
                color: isLoggedIn ? Colors.green.shade800 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _InfoBanner({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black54),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(color: Colors.black54)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
