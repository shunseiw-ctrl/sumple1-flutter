import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/core/providers/firebase_providers.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

class ContactPage extends ConsumerStatefulWidget {
  const ContactPage({super.key});

  @override
  ConsumerState<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends ConsumerState<ContactPage> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;
  String _categoryKey = 'general';

  static const _categoryKeys = [
    'general',
    'account',
    'jobs',
    'payment',
    'bug',
    'other',
  ];

  static String _categoryLabel(BuildContext context, String key) {
    switch (key) {
      case 'general': return context.l10n.contact_categoryGeneral;
      case 'account': return context.l10n.contact_categoryAccount;
      case 'jobs': return context.l10n.contact_categoryJobs;
      case 'payment': return context.l10n.contact_categoryPayment;
      case 'bug': return context.l10n.contact_categoryBug;
      case 'other': return context.l10n.contact_categoryOther;
      default: return key;
    }
  }

  // Map keys to Japanese values for Firestore storage
  static const _categoryValues = {
    'general': '一般的な質問',
    'account': 'アカウントについて',
    'jobs': '案件・応募について',
    'payment': '決済・報酬について',
    'bug': '不具合の報告',
    'other': 'その他',
  };

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('contact');
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.contact_validationError)),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      await ref.read(firestoreProvider).collection('contacts').add({
        'uid': user?.uid ?? '',
        'email': user?.email ?? '',
        'category': _categoryValues[_categoryKey] ?? _categoryKey,
        'subject': subject,
        'body': body,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _subjectController.clear();
      _bodyController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.contact_sendSuccess)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.contact_sendError}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.contact_title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.l10n.contact_categoryLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textSecondary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _categoryKey,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: _categoryKeys
                .map((key) => DropdownMenuItem(value: key, child: Text(_categoryLabel(context, key), style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _categoryKey = v);
            },
          ),

          const SizedBox(height: 16),
          Text(context.l10n.contact_subjectLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectController,
            maxLength: AppConstants.maxContactSubjectLength,
            decoration: InputDecoration(
              hintText: context.l10n.contact_subjectHint,
              counterText: '',
            ),
          ),

          const SizedBox(height: 16),
          Text(context.l10n.contact_bodyLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            maxLines: 6,
            maxLength: AppConstants.maxContactBodyLength,
            decoration: InputDecoration(
              hintText: context.l10n.contact_bodyHint,
              counterText: '',
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(context.l10n.contact_submitButton),
            ),
          ),
        ],
      ),
    );
  }
}
