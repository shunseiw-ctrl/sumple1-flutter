import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _familyNameCtrl = TextEditingController();
  final _givenNameCtrl = TextEditingController();
  final _familyNameKanaCtrl = TextEditingController();
  final _givenNameKanaCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _gender;
  bool _isLoading = false;
  bool _loadedOnce = false;

  bool get _isAnonymous {
    final u = FirebaseAuth.instance.currentUser;
    return u == null || u.isAnonymous;
  }

  @override
  void dispose() {
    _familyNameCtrl.dispose();
    _givenNameCtrl.dispose();
    _familyNameKanaCtrl.dispose();
    _givenNameKanaCtrl.dispose();
    _birthDateCtrl.dispose();
    _postalCodeCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) return;
    _loadedOnce = true;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();

      final data = doc.data();
      if (data != null) {
        _familyNameCtrl.text = (data['familyName'] ?? '').toString();
        _givenNameCtrl.text = (data['givenName'] ?? '').toString();
        _familyNameKanaCtrl.text = (data['familyNameKana'] ?? '').toString();
        _givenNameKanaCtrl.text = (data['givenNameKana'] ?? '').toString();
        _birthDateCtrl.text = (data['birthDate'] ?? '').toString();
        _postalCodeCtrl.text = (data['postalCode'] ?? '').toString();
        _addressCtrl.text = (data['address'] ?? '').toString();

        final g = data['gender'];
        if (g is String && g.trim().isNotEmpty) {
          _gender = g.trim();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プロフィールの読み込みに失敗しました: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickBirthDate() async {
    if (_isLoading) return;
    if (_isAnonymous) return;

    DateTime initial = DateTime(2000, 1, 1);
    final current = _birthDateCtrl.text.trim();
    final match = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(current);
    if (match) {
      final parts = current.split('-').map(int.parse).toList();
      initial = DateTime(parts[0], parts[1], parts[2]);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
      helpText: '生年月日を選択',
      cancelText: 'キャンセル',
      confirmText: 'OK',
    );

    if (picked == null) return;

    final yyyy = picked.year.toString().padLeft(4, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    final dd = picked.day.toString().padLeft(2, '0');
    _birthDateCtrl.text = '$yyyy-$mm-$dd';
    if (mounted) setState(() {});
  }

  String? _requiredValidator(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$labelは必須です';
    return null;
  }

  Future<void> _save() async {
    if (_isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールの保存にはログインが必要です')),
      );
      return;
    }

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_gender == null || _gender!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('性別を選択してください')),
      );
      return;
    }

    final now = FieldValue.serverTimestamp();

    final data = <String, dynamic>{
      'familyName': _familyNameCtrl.text.trim(),
      'givenName': _givenNameCtrl.text.trim(),
      'familyNameKana': _familyNameKanaCtrl.text.trim(),
      'givenNameKana': _givenNameKanaCtrl.text.trim(),
      'birthDate': _birthDateCtrl.text.trim(),
      'gender': _gender,
      'postalCode': _postalCodeCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'updatedAt': now,
    };

    setState(() => _isLoading = true);
    try {
      final ref = FirebaseFirestore.instance.collection('profiles').doc(user.uid);

      final existing = await ref.get();
      if (!existing.exists) {
        data['createdAt'] = now;
      }

      await ref.set(data, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールを保存しました')),
      );

      Navigator.pop(context);
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Widget _twoColumnFields({
    required Widget left,
    required Widget right,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;

        if (narrow) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAnon = _isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text('あなたのプロフィール'),
        actions: [
          TextButton(
            onPressed: (_isLoading || isAnon) ? null : _save,
            child: _isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('保存'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (isAnon) ...[
                const _Banner(
                  title: 'ログインが必要です',
                  message: 'プロフィールの入力・保存にはログインが必要です（Google/メール/SMS いずれでもOK）。',
                ),
                const SizedBox(height: 12),
              ],

              const _SectionTitle('基本情報'),

              _twoColumnFields(
                left: TextFormField(
                  controller: _familyNameCtrl,
                  decoration: const InputDecoration(labelText: '姓（必須）'),
                  validator: (v) => _requiredValidator(v, '姓'),
                  textInputAction: TextInputAction.next,
                ),
                right: TextFormField(
                  controller: _givenNameCtrl,
                  decoration: const InputDecoration(labelText: '名（必須）'),
                  validator: (v) => _requiredValidator(v, '名'),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 12),

              _twoColumnFields(
                left: TextFormField(
                  controller: _familyNameKanaCtrl,
                  decoration: const InputDecoration(labelText: 'セイ（必須）'),
                  validator: (v) => _requiredValidator(v, 'セイ'),
                  textInputAction: TextInputAction.next,
                ),
                right: TextFormField(
                  controller: _givenNameKanaCtrl,
                  decoration: const InputDecoration(labelText: 'メイ（必須）'),
                  validator: (v) => _requiredValidator(v, 'メイ'),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _birthDateCtrl,
                readOnly: true,
                onTap: isAnon ? null : _pickBirthDate,
                decoration: InputDecoration(
                  labelText: '生年月日（必須）',
                  hintText: 'YYYY-MM-DD',
                  suffixIcon: IconButton(
                    onPressed: isAnon ? null : _pickBirthDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                ),
                validator: (v) => _requiredValidator(v, '生年月日'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: '性別（必須）'),
                items: const [
                  DropdownMenuItem(value: '未回答', child: Text('未回答')),
                  DropdownMenuItem(value: '男性', child: Text('男性')),
                  DropdownMenuItem(value: '女性', child: Text('女性')),
                  DropdownMenuItem(value: 'その他', child: Text('その他')),
                ],
                onChanged: isAnon ? null : (v) => setState(() => _gender = v),
                validator: (v) {
                  if (isAnon) return null;
                  if (v == null || v.trim().isEmpty) return '性別は必須です';
                  return null;
                },
              ),

              const SizedBox(height: 20),
              const _SectionTitle('住所'),

              TextFormField(
                controller: _postalCodeCtrl,
                decoration: const InputDecoration(
                  labelText: '郵便番号',
                  hintText: '例）123-4567',
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: '住所',
                  hintText: '例）千葉県…',
                ),
                keyboardType: TextInputType.text,
                maxLines: 2,
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isAnon ? null : _save,
                  child: const Text('保存する'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String title;
  final String message;

  const _Banner({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.chipUnselected,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
