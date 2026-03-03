import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sumple1/core/services/auth_service.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/core/services/analytics_service.dart';

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _authService = AuthService();

  // ログインフォーム
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // 新規登録フォーム
  final _registerFormKey = GlobalKey<FormState>();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmController = TextEditingController();

  bool _isLoading = false;
  bool _loginPasswordVisible = false;
  bool _registerPasswordVisible = false;
  bool _registerConfirmVisible = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('email_auth');
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return context.l10n.emailAuth_errorEmailInUse;
      case 'wrong-password':
      case 'invalid-credential':
        return context.l10n.emailAuth_errorWrongPassword;
      case 'user-not-found':
        return context.l10n.emailAuth_errorUserNotFound;
      case 'invalid-email':
        return context.l10n.emailAuth_errorInvalidEmail;
      case 'user-disabled':
        return context.l10n.emailAuth_errorUserDisabled;
      case 'too-many-requests':
        return context.l10n.emailAuth_errorTooManyRequests;
      case 'weak-password':
        return context.l10n.emailAuth_errorWeakPassword;
      case 'network-request-failed':
        return context.l10n.emailAuth_errorNetwork;
      default:
        return context.l10n.emailAuth_errorGeneric(e.code);
    }
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailAndPassword(
        email: _loginEmailController.text,
        password: _loginPasswordController.text,
      );
      Logger.info('Email login successful', tag: 'EmailAuthPage');
      // AuthGate が authStateChanges で自動遷移
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_firebaseAuthErrorMessage(e))),
      );
    } catch (e) {
      Logger.error('Email login failed', tag: 'EmailAuthPage', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.emailAuth_snackLoginFailed)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.createUserWithEmailAndPassword(
        email: _registerEmailController.text,
        password: _registerPasswordController.text,
      );
      Logger.info('Email registration successful', tag: 'EmailAuthPage');
      // AuthGate が authStateChanges で自動遷移
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_firebaseAuthErrorMessage(e))),
      );
    } catch (e) {
      Logger.error('Email registration failed', tag: 'EmailAuthPage', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.emailAuth_snackRegisterFailed)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showPasswordResetDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            context.l10n.emailAuth_passwordResetTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.l10n.emailAuth_emailLabel,
                hintText: 'example@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return context.l10n.emailAuth_emailRequired;
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                  return context.l10n.emailAuth_emailInvalid;
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.emailAuth_cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await _authService
                      .sendPasswordResetEmail(emailController.text.trim());
                  if (!context.mounted) return;
                  final outerContext = this.context;
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    SnackBar(
                      content: Text(outerContext.l10n.emailAuth_snackResetSent),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_firebaseAuthErrorMessage(e))),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.emailAuth_snackSendFailed)),
                  );
                }
              },
              child: Text(context.l10n.emailAuth_sendButton),
            ),
          ],
        );
      },
    );
    emailController.dispose();
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return context.l10n.emailAuth_emailRequired;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
      return context.l10n.emailAuth_emailInvalid;
    }
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return context.l10n.emailAuth_passwordRequired;
    if (v.length < 6) return context.l10n.emailAuth_passwordMinLength;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.emailAuth_title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.emailAuth_tabLogin),
            Tab(text: context.l10n.emailAuth_tabRegister),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginForm(),
          _buildRegisterForm(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            TextFormField(
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.emailAuth_emailLabel,
                hintText: 'example@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: _emailValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loginPasswordController,
              obscureText: !_loginPasswordVisible,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: context.l10n.emailAuth_passwordLabel,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _loginPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(
                        () => _loginPasswordVisible = !_loginPasswordVisible);
                  },
                ),
              ),
              validator: _passwordValidator,
              onFieldSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showPasswordResetDialog,
                child: Text(
                  context.l10n.emailAuth_forgotPassword,
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(context.l10n.emailAuth_loginButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            TextFormField(
              controller: _registerEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.emailAuth_emailLabel,
                hintText: 'example@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: _emailValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerPasswordController,
              obscureText: !_registerPasswordVisible,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.emailAuth_passwordWithMinLength,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _registerPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() =>
                        _registerPasswordVisible = !_registerPasswordVisible);
                  },
                ),
              ),
              validator: _passwordValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerConfirmController,
              obscureText: !_registerConfirmVisible,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: context.l10n.emailAuth_passwordConfirmLabel,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _registerConfirmVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() =>
                        _registerConfirmVisible = !_registerConfirmVisible);
                  },
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return context.l10n.emailAuth_passwordConfirmRequired;
                if (v != _registerPasswordController.text) {
                  return context.l10n.emailAuth_passwordMismatch;
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleRegister(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(context.l10n.emailAuth_registerButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
