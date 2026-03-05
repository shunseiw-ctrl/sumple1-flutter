import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
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

  String authErrorMessage(BuildContext ctx, FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return ctx.l10n.emailAuthDialog_invalidEmail;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return ctx.l10n.emailAuthDialog_wrongCredentials;
      case 'email-already-in-use':
        return ctx.l10n.emailAuthDialog_emailAlreadyInUse;
      case 'weak-password':
        return ctx.l10n.emailAuthDialog_weakPassword;
      case 'operation-not-allowed':
        return ctx.l10n.emailAuthDialog_operationNotAllowed;
      default:
        return ctx.l10n.emailAuthDialog_authError(e.code);
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
              await showSnack(dialogContext.l10n.emailAuthDialog_loginLocked);
              return;
            }

            final email = emailController.text.trim();
            final pass = passController.text;

            if (email.isEmpty || pass.isEmpty) {
              await showSnack(dialogContext.l10n.emailAuthDialog_enterEmailAndPassword);
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
              await showSnack(dialogContext.l10n.emailAuthDialog_loginSuccess);
            } on FirebaseAuthException catch (e) {
              failedAttempts++;
              if (failedAttempts >= maxAttempts) {
                lockoutUntil = DateTime.now().add(lockoutDuration);
              }
              await showSnack(authErrorMessage(dialogContext, e));
            } catch (e) {
              failedAttempts++;
              if (failedAttempts >= maxAttempts) {
                lockoutUntil = DateTime.now().add(lockoutDuration);
              }
              await showSnack(dialogContext.l10n.emailAuthDialog_loginFailed);
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
              await showSnack(dialogContext.l10n.emailAuthDialog_enterEmailAndPassword);
              return;
            }
            if (pass.length < 6) {
              await showSnack(dialogContext.l10n.emailAuthDialog_passwordMinLength);
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
              await showSnack(dialogContext.l10n.emailAuthDialog_signUpSuccess);
            } on FirebaseAuthException catch (e) {
              await showSnack(authErrorMessage(dialogContext, e));
            } catch (e) {
              await showSnack(dialogContext.l10n.emailAuthDialog_signUpFailed);
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
            title: Text(dialogContext.l10n.emailAuthDialog_title, style: AppTextStyles.headingSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: dialogContext.l10n.emailAuthDialog_emailLabel,
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide(color: dialogContext.appColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide(color: dialogContext.appColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: dialogContext.appColors.primarySurface.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: dialogContext.l10n.emailAuthDialog_passwordLabel,
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: Semantics(
                      button: true,
                      label: obscure ? dialogContext.l10n.emailAuthDialog_showPassword : dialogContext.l10n.emailAuthDialog_hidePassword,
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
                      borderSide: BorderSide(color: dialogContext.appColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide(color: dialogContext.appColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: dialogContext.appColors.primarySurface.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading) const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 8),
                Text(
                  dialogContext.l10n.emailAuthDialog_signUpHint,
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                child: Text(dialogContext.l10n.common_cancel),
              ),
              TextButton(
                onPressed: isLoading ? null : signUp,
                child: Text(dialogContext.l10n.emailAuthDialog_signUpButton),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : signIn,
                child: Text(dialogContext.l10n.emailAuthDialog_loginButton),
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
