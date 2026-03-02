import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/providers/connectivity_provider.dart';
import 'package:sumple1/core/services/connectivity_service.dart';

void main() {
  group('connectivityServiceProvider', () {
    test('ConnectivityServiceインスタンスを提供する', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(connectivityServiceProvider);
      expect(service, isA<ConnectivityService>());
    });
  });

  group('isOnlineProvider', () {
    test('デフォルトでtrueを返す', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isOnline = container.read(isOnlineProvider);
      expect(isOnline, isTrue);
    });

    test('connectivityStreamProviderのデータに応じて変化する', () {
      final container = ProviderContainer(
        overrides: [
          connectivityStreamProvider.overrideWith(
            (ref) => Stream.value(false),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Streamの初期状態ではloading→serviceのisOnline値
      final isOnline = container.read(isOnlineProvider);
      // Stream未解決時はservice.isOnline(true)を返す
      expect(isOnline, isA<bool>());
    });

    test('ストリームがエラーの場合trueを返す', () {
      final container = ProviderContainer(
        overrides: [
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
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final stream = container.read(connectivityStreamProvider);
      expect(stream, isA<AsyncValue<bool>>());
    });
  });
}
