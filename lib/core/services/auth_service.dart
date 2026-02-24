import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../enums/user_role.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  String get currentUserId => currentUser?.uid ?? '';

  String? get currentUserEmail => currentUser?.email;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserRole> getCurrentUserRole() async {
    final user = currentUser;

    if (user == null) {
      Logger.info('User is not authenticated -> guest', tag: 'AuthService');
      return UserRole.guest;
    }

    if (user.isAnonymous) {
      Logger.info('User is anonymous -> user', tag: 'AuthService', data: {'uid': _shortUid(user.uid)});
      return UserRole.user;
    }

    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      Logger.info('User has no email -> user', tag: 'AuthService', data: {'uid': _shortUid(user.uid)});
      return UserRole.user;
    }

    final isAdmin = await _checkIsAdmin(email);
    Logger.info('User role determined', tag: 'AuthService', data: {
      'uid': _shortUid(user.uid),
      'isAdmin': isAdmin,
    });

    return isAdmin ? UserRole.admin : UserRole.user;
  }

  Future<bool> _checkIsAdmin(String email) async {
    try {
      final doc = await _firestore.doc(AppConstants.adminConfigPath).get();

      if (!doc.exists) {
        Logger.warning('Admin config document not found', tag: 'AuthService');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>?;

      final adminUids = (data?['uids'] as List?)
              ?.map((e) => e.toString().trim())
              .toList() ??
          [];

      if (adminUids.contains(currentUserId)) {
        return true;
      }

      final adminEmails = (data?['emails'] as List?)
              ?.map((e) => e.toString().toLowerCase().trim())
              .toList() ??
          [];

      return adminEmails.contains(email.toLowerCase().trim());
    } catch (e) {
      Logger.error('Error checking admin status', tag: 'AuthService', error: e);
      return false;
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      Logger.info('Anonymous sign in successful', tag: 'AuthService', data: {'uid': _shortUid(credential.user?.uid)});
      return credential.user;
    } catch (e) {
      Logger.error('Anonymous sign in failed', tag: 'AuthService', error: e);
      rethrow;
    }
  }

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Logger.info('Email sign in successful', tag: 'AuthService', data: {'uid': _shortUid(credential.user?.uid)});
      return credential.user;
    } catch (e) {
      Logger.error('Email sign in failed', tag: 'AuthService', error: e);
      rethrow;
    }
  }

  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Logger.info('User creation successful', tag: 'AuthService', data: {'uid': _shortUid(credential.user?.uid)});
      return credential.user;
    } catch (e) {
      Logger.error('User creation failed', tag: 'AuthService', error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      Logger.info('Sign out successful', tag: 'AuthService');
    } catch (e) {
      Logger.error('Sign out failed', tag: 'AuthService', error: e);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      Logger.info('Password reset email sent', tag: 'AuthService');
    } catch (e) {
      Logger.error('Password reset email failed', tag: 'AuthService', error: e);
      rethrow;
    }
  }

  String _shortUid(String? uid) {
    if (uid == null) return 'null';
    return uid.length > 8 ? uid.substring(0, 8) : uid;
  }
}
