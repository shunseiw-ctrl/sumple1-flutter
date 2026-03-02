import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_service.dart';

/// ConnectivityService インスタンスプロバイダー（シングルトン）
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.startMonitoring();
  ref.onDispose(() => service.stopMonitoring());
  return service;
});

/// 接続状態ストリーム
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// オンラインフラグ（初期値 true、ストリームの最新値を反映）
final isOnlineProvider = Provider<bool>((ref) {
  final streamState = ref.watch(connectivityStreamProvider);
  return streamState.when(
    data: (isOnline) => isOnline,
    loading: () => ref.read(connectivityServiceProvider).isOnline,
    error: (_, __) => true,
  );
});
