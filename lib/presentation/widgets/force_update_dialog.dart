import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

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
        isForced ? context.l10n.forceUpdate_required : context.l10n.forceUpdate_available,
        style: AppTextStyles.headingSmall,
      ),
      content: Text(
        message?.isNotEmpty == true
            ? message!
            : isForced
                ? context.l10n.forceUpdate_requiredMessage
                : context.l10n.forceUpdate_availableMessage,
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        if (!isForced)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.forceUpdate_later, style: AppTextStyles.labelMedium),
          ),
        ElevatedButton(
          onPressed: () async {
            if (storeUrl.isNotEmpty) {
              await launchUrl(Uri.parse(storeUrl),
                  mode: LaunchMode.externalApplication);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(context.l10n.forceUpdate_update),
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
