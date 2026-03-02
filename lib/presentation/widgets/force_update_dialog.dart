import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';

class ForceUpdateDialog extends StatelessWidget {
  final bool isForced;
  final String storeUrl;
  final String? message;

  const ForceUpdateDialog({
    super.key,
    required this.isForced,
    required this.storeUrl,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLg),
      ),
      title: Text(
        isForced ? 'アップデートが必要です' : '新しいバージョンがあります',
        style: AppTextStyles.headingSmall,
      ),
      content: Text(
        message?.isNotEmpty == true
            ? message!
            : isForced
                ? '最新バージョンにアップデートしてください。'
                : '新機能が追加されました。最新バージョンをお使いください。',
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        if (!isForced)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('あとで', style: AppTextStyles.labelMedium),
          ),
        ElevatedButton(
          onPressed: () async {
            if (storeUrl.isNotEmpty) {
              await launchUrl(Uri.parse(storeUrl),
                  mode: LaunchMode.externalApplication);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ruri,
            foregroundColor: Colors.white,
          ),
          child: const Text('アップデート'),
        ),
      ],
    );
  }
}

Future<void> showForceUpdateDialog(
  BuildContext context, {
  required bool isForced,
  required String storeUrl,
  String? message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !isForced,
    builder: (context) => ForceUpdateDialog(
      isForced: isForced,
      storeUrl: storeUrl,
      message: message,
    ),
  );
}
