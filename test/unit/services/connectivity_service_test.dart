import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    late ConnectivityService service;

    setUp(() {
      service = ConnectivityService();
    });

    tearDown(() {
      service.stopMonitoring();
    });

    test('シングルトンパターン: 同一インスタンスを返す', () {
      final service1 = ConnectivityService();
      final service2 = ConnectivityService();
      expect(identical(service1, service2), isTrue);
    });

    test('デフォルトでオンライン', () {
      expect(service.isOnline, isTrue);
    });

    test('onConnectivityChangedはbroadcast Stream', () {
      final stream = service.onConnectivityChanged;
      expect(stream.isBroadcast, isTrue);
    });

    test('startMonitoringを複数回呼んでもエラーにならない', () {
      expect(() {
        service.startMonitoring();
        service.startMonitoring();
      }, returnsNormally);
    });

    test('stopMonitoringを複数回呼んでもエラーにならない', () {
      service.startMonitoring();
      expect(() {
        service.stopMonitoring();
        service.stopMonitoring();
      }, returnsNormally);
    });

    test('監視開始前にstopを呼んでもエラーにならない', () {
      expect(() {
        service.stopMonitoring();
      }, returnsNormally);
    });
  });
}
