import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';

class HintCard extends StatelessWidget {
  final String title;
  final String body;
  const HintCard({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE65100))),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: AppColors.textPrimary, height: 1.35)),
        ],
      ),
    );
  }
}
