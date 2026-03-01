import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/core/services/analytics_service.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;
  String _category = '一般的な質問';

  static const _categories = [
    '一般的な質問',
    'アカウントについて',
    '案件・応募について',
    '決済・報酬について',
    '不具合の報告',
    'その他',
  ];

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
        const SnackBar(content: Text('件名と内容を入力してください')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('contacts').add({
        'uid': user?.uid ?? '',
        'email': user?.email ?? '',
        'category': _category,
        'subject': subject,
        'body': body,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _subjectController.clear();
      _bodyController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('お問い合わせを送信しました。ご回答までお待ちください。')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送信に失敗しました: $e')),
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
        title: const Text('お問い合わせ', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('カテゴリ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),

          const SizedBox(height: 16),
          Text('件名', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectController,
            maxLength: AppConstants.maxContactSubjectLength,
            decoration: const InputDecoration(
              hintText: '件名を入力',
              counterText: '',
            ),
          ),

          const SizedBox(height: 16),
          Text('内容', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            maxLines: 6,
            maxLength: AppConstants.maxContactBodyLength,
            decoration: const InputDecoration(
              hintText: 'お問い合わせ内容を入力してください',
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
                  : const Text('送信する'),
            ),
          ),
        ],
      ),
    );
  }
}
