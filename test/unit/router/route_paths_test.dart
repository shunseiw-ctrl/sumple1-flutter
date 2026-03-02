import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/router/route_paths.dart';

void main() {
  group('RoutePaths', () {
    test('定数パスが定義されている', () {
      expect(RoutePaths.home, equals('/'));
      expect(RoutePaths.login, equals('/login'));
      expect(RoutePaths.jobList, equals('/jobs'));
      expect(RoutePaths.notifications, equals('/notifications'));
      expect(RoutePaths.adminHome, equals('/admin'));
    });

    test('jobDetailPathがIDを含むパスを返す', () {
      expect(RoutePaths.jobDetailPath('abc123'), equals('/jobs/abc123'));
    });

    test('workDetailPathがIDを含むパスを返す', () {
      expect(RoutePaths.workDetailPath('app456'), equals('/work/app456'));
    });

    test('chatRoomPathがIDを含むパスを返す', () {
      expect(RoutePaths.chatRoomPath('chat789'), equals('/chat/chat789'));
    });

    test('paymentDetailPathがIDを含むパスを返す', () {
      expect(RoutePaths.paymentDetailPath('pay001'), equals('/payments/pay001'));
    });

    test('jobEditPathがIDを含むパスを返す', () {
      expect(RoutePaths.jobEditPath('job001'), equals('/jobs/job001/edit'));
    });
  });
}
