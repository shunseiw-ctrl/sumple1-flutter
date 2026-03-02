import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../enums/user_role.dart';

/// AuthService インスタンスプロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Firebase Auth 状態ストリーム
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// 現在のユーザーロール
final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return UserRole.guest;
      final authService = ref.read(authServiceProvider);
      return authService.getCurrentUserRole();
    },
    loading: () => UserRole.guest,
    error: (_, __) => UserRole.guest,
  );
});

/// 認証済みフラグ
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// 現在のユーザーUID
final currentUserUidProvider = Provider<String>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.uid ?? '',
    loading: () => '',
    error: (_, __) => '',
  );
});
