import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

class WhiteCard extends StatelessWidget {
  final Widget child;
  const WhiteCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.borderLight),
        ),
        child: child,
      ),
    );
  }
}
