import 'package:flutter/material.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static List<Map<String, String>> _faqItems(BuildContext context) => [
    {
      'q': context.l10n.faq_q1,
      'a': context.l10n.faq_a1,
    },
    {
      'q': context.l10n.faq_q2,
      'a': context.l10n.faq_a2,
    },
    {
      'q': context.l10n.faq_q3,
      'a': context.l10n.faq_a3,
    },
    {
      'q': context.l10n.faq_q4,
      'a': context.l10n.faq_a4,
    },
    {
      'q': context.l10n.faq_q5,
      'a': context.l10n.faq_a5,
    },
    {
      'q': context.l10n.faq_q6,
      'a': context.l10n.faq_a6,
    },
    {
      'q': context.l10n.faq_q7,
      'a': context.l10n.faq_a7,
    },
    {
      'q': context.l10n.faq_q8,
      'a': context.l10n.faq_a8,
    },
  ];

  @override
  Widget build(BuildContext context) {
    AnalyticsService.logScreenView('faq');
    final items = _faqItems(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.faq_title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6E8EB)),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              shape: const Border(),
              leading: Icon(Icons.help_outline, color: context.appColors.primary, size: 20),
              title: Text(
                item['q']!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              children: [
                Text(
                  item['a']!,
                  style: TextStyle(fontSize: 14, color: context.appColors.textSecondary, height: 1.6),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
