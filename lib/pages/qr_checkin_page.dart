import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/checkin_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';

class QrCheckinPage extends StatefulWidget {
  final String applicationId;
  final bool isCheckOut;

  const QrCheckinPage({
    super.key,
    required this.applicationId,
    this.isCheckOut = false,
  });

  @override
  State<QrCheckinPage> createState() => _QrCheckinPageState();
}

class _QrCheckinPageState extends State<QrCheckinPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _processing = false;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('qr_checkin');
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _scanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() {
      _processing = true;
      _scanned = true;
    });

    try {
      final result = await CheckinService.performCheckin(
        applicationId: widget.applicationId,
        qrData: qrData,
        isCheckOut: widget.isCheckOut,
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: context.appColors.error),
                SizedBox(width: 8),
                Expanded(
                  child: Text(context.l10n.qrCheckin_error, style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        setState(() {
          _processing = false;
          _scanned = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.qrCheckin_errorOccurred(e.toString()))),
      );
      setState(() {
        _processing = false;
        _scanned = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.isCheckOut ? context.l10n.qrCheckin_clockOut : context.l10n.qrCheckin_clockIn;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          context.l10n.qrCheckin_title(action),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // スキャンガイド
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // 下部テキスト
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Column(
              children: [
                if (_processing)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  Text(
                    context.l10n.qrCheckin_scanAdminQr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.qrCheckin_gpsVerification(action),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
