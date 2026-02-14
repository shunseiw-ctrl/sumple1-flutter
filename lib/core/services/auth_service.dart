import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../enums/user_role.dart';
import '../constants/app_constants.dart';

/// 認証とユーザーロール管理を行うサービス
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 現在のユーザー
  User? get currentUser => _auth.currentUser;

  /// 現在のユーザーUID
  String get currentUserId => currentUser?.uid ?? '';

  /// 現在のユーザーメールアドレス
  String? get currentUserEmail => currentUser?.email;

  /// 認証状態の変更を監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 現在のユーザーロールを取得
  Future<UserRole> getCurrentUserRole() async {
    final user = currentUser;

    // 未認証ユーザー
    if (user == null) {
      _log('User is not authenticated -> guest');
      return UserRole.guest;
    }

    // 匿名ユーザー
    if (user.isAnonymous) {
      _log('User is anonymous -> user', userId: user.uid);
      return UserRole.user;
    }

    // メールアドレスがない場合
    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      _log('User has no email -> user', userId: user.uid);
      return UserRole.user;
    }

    // 管理者かどうかをチェック
    final isAdmin = await _checkIsAdmin(email);
    _log('User role determined', userId: user.uid, extra: {
      'email': email,
      'isAdmin': isAdmin,
    });

    return isAdmin ? UserRole.admin : UserRole.user;
  }

  /// 管理者かどうかをチェック
  Future<bool> _checkIsAdmin(String email) async {
    try {
      // 固定UIDチェック（MVP用）
      if (currentUserId == AppConstants.adminUid) {
        return true;
      }

      // Firestoreの管理者リストをチェック
      final doc = await _firestore.doc(AppConstants.adminConfigPath).get();

      if (!doc.exists) {
        _log('Admin config document not found');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>?;
      final adminEmails = (data?['emails'] as List?)
              ?.map((e) => e.toString().toLowerCase().trim())
              .toList() ??
          [];

      return adminEmails.contains(email.toLowerCase().trim());
    } catch (e) {
      _log('Error checking admin status', error: e);
      return false;
    }
  }

  /// 匿名ログイン
  Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      _log('Anonymous sign in successful', userId: credential.user?.uid);
      return credential.user;
    } catch (e) {
      _log('Anonymous sign in failed', error: e);
      rethrow;
    }
  }

  /// メールアドレスでログイン
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _log('Email sign in successful', userId: credential.user?.uid);
      return credential.user;
    } catch (e) {
      _log('Email sign in failed', error: e);
      rethrow;
    }
  }

  /// メールアドレスで新規登録
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _log('User creation successful', userId: credential.user?.uid);
      return credential.user;
    } catch (e) {
      _log('User creation failed', error: e);
      rethrow;
    }
  }

  /// ログアウト
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _log('Sign out successful');
    } catch (e) {
      _log('Sign out failed', error: e);
      rethrow;
    }
  }

  /// パスワードリセットメールを送信
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _log('Password reset email sent', extra: {'email': email});
    } catch (e) {
      _log('Password reset email failed', error: e);
      rethrow;
    }
  }

  /// デバッグログ出力
  void _log(String message, {String? userId, dynamic error, Map<String, dynamic>? extra}) {
    if (!kDebugMode) return;

    final buffer = StringBuffer('[AuthService] $message');

    if (userId != null) {
      final shortId = userId.length > 8 ? userId.substring(0, 8) : userId;
      buffer.write(' | uid=$shortId...');
    }

    if (extra != null && extra.isNotEmpty) {
      buffer.write(' | $extra');
    }

    if (error != null) {
      buffer.write(' | error=$error');
    }

    debugPrint(buffer.toString());
  }
}
