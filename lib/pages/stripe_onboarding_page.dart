import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/services/payment_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';

class StripeOnboardingPage extends StatefulWidget {
  final String? email;

  const StripeOnboardingPage({super.key, this.email});

  @override
  State<StripeOnboardingPage> createState() => _StripeOnboardingPageState();
}

class _StripeOnboardingPageState extends State<StripeOnboardingPage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('stripe_onboarding');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            // リターンURLを検出したら完了
            if (request.url.contains('stripe/return')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            if (request.url.contains('stripe/refresh')) {
              _loadOnboardingUrl();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    _loadOnboardingUrl();
  }

  Future<void> _loadOnboardingUrl() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final result = await PaymentService().createConnectAccount(
        email: widget.email,
      );

      final url = result['url'] as String?;
      if (url != null && url.isNotEmpty) {
        _controller.loadRequest(Uri.parse(url));
      } else {
        setState(() => _error = 'URLの取得に失敗しました');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Stripeの初期化に失敗しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stripe口座設定',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadOnboardingUrl,
                      child: const Text('リトライ'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
