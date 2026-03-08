import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

class HintCard extends StatelessWidget {
  final String title;
  final String body;
  const HintCard({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.hintCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.hintCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: context.appColors.hintCardTitle)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: context.appColors.textPrimary, height: 1.35)),
        ],
      ),
    );
  }
}
