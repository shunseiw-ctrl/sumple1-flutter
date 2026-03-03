import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/services/connectivity_service.dart';

class OfflineBanner extends StatefulWidget {
  final VoidCallback? onRetry;

  const OfflineBanner({super.key, this.onRetry});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  late final ConnectivityService _connectivity;
  late bool _isOffline;
  StreamSubscription<bool>? _subscription;
  bool _showRecoverySnackBar = false;

  @override
  void initState() {
    super.initState();
    _connectivity = ConnectivityService();
    _isOffline = !_connectivity.isOnline;
    _subscription = _connectivity.onConnectivityChanged.listen((online) {
      if (mounted) {
        final wasOffline = _isOffline;
        setState(() => _isOffline = !online);
        if (wasOffline && online) {
          _showRecoverySnackBar = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('接続が復旧しました'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    return Material(
      color: Colors.orange.shade800,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'オフラインモード — キャッシュデータを表示中',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.onRetry != null)
                GestureDetector(
                  onTap: widget.onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '再試行',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
