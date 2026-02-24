import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/enums/user_role.dart';

void main() {
  group('UserRole displayName', () {
    test('guest returns ゲスト', () {
      expect(UserRole.guest.displayName, 'ゲスト');
    });

    test('user returns 一般ユーザー', () {
      expect(UserRole.user.displayName, '一般ユーザー');
    });

    test('admin returns 管理者', () {
      expect(UserRole.admin.displayName, '管理者');
    });
  });

  group('UserRole isAdmin', () {
    test('guest is not admin', () {
      expect(UserRole.guest.isAdmin, isFalse);
    });

    test('user is not admin', () {
      expect(UserRole.user.isAdmin, isFalse);
    });

    test('admin is admin', () {
      expect(UserRole.admin.isAdmin, isTrue);
    });
  });

  group('UserRole isAuthenticated', () {
    test('guest is not authenticated', () {
      expect(UserRole.guest.isAuthenticated, isFalse);
    });

    test('user is authenticated', () {
      expect(UserRole.user.isAuthenticated, isTrue);
    });

    test('admin is authenticated', () {
      expect(UserRole.admin.isAuthenticated, isTrue);
    });
  });

  group('UserRole isGuest', () {
    test('guest is guest', () {
      expect(UserRole.guest.isGuest, isTrue);
    });

    test('user is not guest', () {
      expect(UserRole.user.isGuest, isFalse);
    });

    test('admin is not guest', () {
      expect(UserRole.admin.isGuest, isFalse);
    });
  });
}
