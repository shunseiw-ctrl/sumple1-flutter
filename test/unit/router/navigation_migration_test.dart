import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/router/route_paths.dart';

void main() {
  group('RoutePaths helpers', () {
    test('jobDetailPath generates correct path', () {
      expect(RoutePaths.jobDetailPath('abc123'), '/jobs/abc123');
    });

    test('jobEditPath generates correct path', () {
      expect(RoutePaths.jobEditPath('abc123'), '/jobs/abc123/edit');
    });

    test('workDetailPath generates correct path', () {
      expect(RoutePaths.workDetailPath('app456'), '/work/app456');
    });

    test('chatRoomPath generates correct path', () {
      expect(RoutePaths.chatRoomPath('app456'), '/chat/app456');
    });

    test('qrCheckinPath generates correct path', () {
      expect(RoutePaths.qrCheckinPath('app456'), '/work/app456/qr-checkin');
    });

    test('shiftQrPath generates correct path', () {
      expect(RoutePaths.shiftQrPath('job789'), '/work/job789/shift-qr');
    });

    test('paymentDetailPath generates correct path', () {
      expect(RoutePaths.paymentDetailPath('pay001'), '/payments/pay001');
    });

    test('static paths are correct', () {
      expect(RoutePaths.home, '/');
      expect(RoutePaths.login, '/login');
      expect(RoutePaths.postJob, '/jobs/new');
      expect(RoutePaths.notifications, '/notifications');
      expect(RoutePaths.earningsCreate, '/earnings/new');
      expect(RoutePaths.accountSettings, '/account-settings');
      expect(RoutePaths.myProfile, '/my-profile');
      expect(RoutePaths.faq, '/faq');
      expect(RoutePaths.contact, '/contact');
      expect(RoutePaths.legal, '/legal');
    });
  });
}
