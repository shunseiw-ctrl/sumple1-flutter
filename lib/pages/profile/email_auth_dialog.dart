import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';

/// メール認証ダイアログを表示する
///
/// [onAuthStateChanged] はログイン/登録成功後に呼ばれるコールバック（setState用）
Future<void> showEmailAuthDialog({
  required BuildContext context,
  required VoidCallback onAuthStateChanged,
}) async {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool obscure = true;
  bool isLoading = false;

  int failedAttempts = 0;
  DateTime? lockoutUntil;
  const int maxAttempts = 5;
  const Duration lockoutDuration = Duration(minutes: 3);

  bool isLockedOut() =>
      lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);

  Future<void> showSnack(String msg) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String authErrorMessageJa(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが正しくありません';
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

  await showDialog<void>(
    context: context,
    barrierDismissible: !isLoading,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setLocalState) {
          Future<void> signIn() async {
            if (isLockedOut()) {
              await showSnack('ログイン試行回数の上限に達しました。しばらくお待ちください');
              return;
            }

            final email = emailController.text.trim();
            final pass = passController.text;

            if (email.isEmpty || pass.isEmpty) {
              await showSnack('メールアドレスとパスワードを入力してください');
              return;
            }

            setLocalState(() => isLoading = true);
            try {
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: pass,
              );

              failedAttempts = 0;
              lockoutUntil = null;

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              onAuthStateChanged();
              await showSnack('ログインしました');
            } on FirebaseAuthException catch (e) {
              failedAttempts++;
              if (failedAttempts >= maxAttempts) {
                lockoutUntil = DateTime.now().add(lockoutDuration);
              }
              await showSnack(authErrorMessageJa(e));
            } catch (e) {
              failedAttempts++;
              if (failedAttempts >= maxAttempts) {
                lockoutUntil = DateTime.now().add(lockoutDuration);
              }
              await showSnack('ログインに失敗しました');
            } finally {
              if (dialogContext.mounted) {
                setLocalState(() => isLoading = false);
              }
            }
          }

          Future<void> signUp() async {
            final email = emailController.text.trim();
            final pass = passController.text;

            if (email.isEmpty || pass.isEmpty) {
              await showSnack('メールアドレスとパスワードを入力してください');
              return;
            }
            if (pass.length < 6) {
              await showSnack('パスワードは6文字以上にしてください');
              return;
            }

            setLocalState(() => isLoading = true);
            try {
              final current = FirebaseAuth.instance.currentUser;

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
              onAuthStateChanged();
              await showSnack('登録しました（ログイン済み）');
            } on FirebaseAuthException catch (e) {
              await showSnack(authErrorMessageJa(e));
            } catch (e) {
              await showSnack('登録に失敗しました');
            } finally {
              if (dialogContext.mounted) {
                setLocalState(() => isLoading = false);
              }
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            title: Text('メールでログイン', style: AppTextStyles.headingSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: const BorderSide(color: AppColors.ruri, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.ruriSurface.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: Semantics(
                      button: true,
                      label: obscure ? 'パスワードを表示' : 'パスワードを隠す',
                      child: IconButton(
                        onPressed: () => setLocalState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: const BorderSide(color: AppColors.ruri, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.ruriSurface.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading) const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 8),
                Text(
                  '新規登録もこの画面からできます',
                  style: AppTextStyles.labelSmall,
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

  emailController.dispose();
  passController.dispose();
}
