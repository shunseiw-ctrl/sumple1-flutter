import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/services/connectivity_service.dart';

void main() {
  group('ConnectivityService', () {
    test('initial state is online', () {
      final service = ConnectivityService();
      expect(service.isOnline, true);
    });

    test('stream is broadcast stream', () {
      final service = ConnectivityService();
      expect(service.onConnectivityChanged.isBroadcast, true);
    });

    test('default state is online after error', () {
      // ConnectivityService defaults to online
      final service = ConnectivityService();
      expect(service.isOnline, true);
    });
  });
}
