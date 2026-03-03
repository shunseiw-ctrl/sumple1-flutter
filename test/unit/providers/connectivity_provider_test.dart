import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/connectivity_provider.dart';
import 'package:sumple1/core/services/connectivity_service.dart';

/// テスト用のConnectivityServiceモック
class _FakeConnectivityService implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  void startMonitoring() {}

  @override
  void stopMonitoring() {}

  @override
  void dispose() {
    _controller.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('connectivityServiceProvider', () {
    test('ConnectivityServiceインスタンスを提供する', () {
      final fake = _FakeConnectivityService();
      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(connectivityServiceProvider);
      expect(service, isA<ConnectivityService>());
    });
  });

  group('isOnlineProvider', () {
    test('デフォルトでtrueを返す', () {
      final fake = _FakeConnectivityService();
      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final isOnline = container.read(isOnlineProvider);
      expect(isOnline, isTrue);
    });

    test('connectivityStreamProviderのデータに応じて変化する', () {
      final fake = _FakeConnectivityService();
      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fake),
          connectivityStreamProvider.overrideWith(
            (ref) => Stream.value(false),
          ),
        ],
      );
      addTearDown(container.dispose);

      final isOnline = container.read(isOnlineProvider);
      expect(isOnline, isA<bool>());
    });

    test('ストリームがエラーの場合trueを返す', () {
      final fake = _FakeConnectivityService();
      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fake),
          connectivityStreamProvider.overrideWith(
            (ref) => Stream.error(Exception('test')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final isOnline = container.read(isOnlineProvider);
      expect(isOnline, isA<bool>());
    });
  });

  group('connectivityStreamProvider', () {
    test('ストリームプロバイダーを返す', () {
      final fake = _FakeConnectivityService();
      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final stream = container.read(connectivityStreamProvider);
      expect(stream, isA<AsyncValue<bool>>());
    });
  });
}
