import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/presentation/widgets/rating_stars_display.dart';
import 'package:sumple1/core/services/analytics_service.dart';

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

  final _introCtrl = TextEditingController();
  final _experienceYearsCtrl = TextEditingController();
  List<String> _qualifications = [];
  final _qualificationInputCtrl = TextEditingController();

  String? _gender;
  bool _isLoading = false;
  bool _loadedOnce = false;

  bool get _isAnonymous {
    final u = FirebaseAuth.instance.currentUser;
    return u == null || u.isAnonymous;
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('my_profile');
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
    _introCtrl.dispose();
    _experienceYearsCtrl.dispose();
    _qualificationInputCtrl.dispose();
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

        _introCtrl.text = (data['introduction'] ?? '').toString();
        _experienceYearsCtrl.text = (data['experienceYears'] ?? '').toString();
        final quals = data['qualifications'];
        if (quals is List) {
          _qualifications = quals.map((e) => e.toString()).toList();
        }

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
      'introduction': _introCtrl.text.trim(),
      'experienceYears': _experienceYearsCtrl.text.trim(),
      'qualifications': _qualifications,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AbsorbPointer(
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

              const _SectionTitle('プロフィール写真'),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('profiles').doc(FirebaseAuth.instance.currentUser?.uid ?? '').snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data();
                  final photoUrl = (data?['profilePhotoUrl'] ?? '').toString();
                  final locked = data?['profilePhotoLocked'] == true;

                  return Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.chipUnselected,
                          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl.isEmpty ? const Icon(Icons.person, size: 50, color: AppColors.textHint) : null,
                        ),
                        const SizedBox(height: 8),
                        if (locked)
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, size: 14, color: AppColors.success),
                              SizedBox(width: 4),
                              Text('本人確認済み', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                            ],
                          )
                        else
                          const Text('本人確認で写真が設定されます', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              const _SectionTitle('あなたの評価'),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('profiles')
                    .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                    .snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data();
                  final avg = (data?['ratingAverage'] ?? 0).toDouble();
                  final count = (data?['ratingCount'] ?? 0) as int;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      children: [
                        RatingStarsDisplay(
                          average: avg,
                          count: count,
                          starSize: 28,
                          fontSize: 16,
                        ),
                        if (count > 0) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '管理者からの評価',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              const _SectionTitle('Stripe連携'),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('profiles')
                    .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                    .snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data();
                  final stripeStatus = (data?['stripeAccountStatus'] ?? '').toString();
                  final hasAccount = (data?['stripeAccountId'] ?? '').toString().isNotEmpty;

                  IconData icon;
                  Color color;
                  String label;

                  if (!hasAccount) {
                    icon = Icons.account_balance_outlined;
                    color = AppColors.textHint;
                    label = '未設定 — 設定ページからStripe口座を登録してください';
                  } else if (stripeStatus == 'active') {
                    icon = Icons.check_circle;
                    color = AppColors.success;
                    label = '連携済み — 報酬を受け取れます';
                  } else {
                    icon = Icons.pending;
                    color = AppColors.warning;
                    label = '設定中 — Stripeでの確認をお待ちください';
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              const _SectionTitle('基本情報'),

              _twoColumnFields(
                left: TextFormField(
                  controller: _familyNameCtrl,
                  decoration: const InputDecoration(labelText: '姓（必須）'),
                  maxLength: AppConstants.maxDisplayNameLength,
                  validator: (v) => _requiredValidator(v, '姓'),
                  textInputAction: TextInputAction.next,
                ),
                right: TextFormField(
                  controller: _givenNameCtrl,
                  decoration: const InputDecoration(labelText: '名（必須）'),
                  maxLength: AppConstants.maxDisplayNameLength,
                  validator: (v) => _requiredValidator(v, '名'),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 12),

              _twoColumnFields(
                left: TextFormField(
                  controller: _familyNameKanaCtrl,
                  decoration: const InputDecoration(labelText: 'セイ（必須）'),
                  maxLength: AppConstants.maxDisplayNameLength,
                  validator: (v) => _requiredValidator(v, 'セイ'),
                  textInputAction: TextInputAction.next,
                ),
                right: TextFormField(
                  controller: _givenNameKanaCtrl,
                  decoration: const InputDecoration(labelText: 'メイ（必須）'),
                  maxLength: AppConstants.maxDisplayNameLength,
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
                initialValue: _gender,
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
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final regex = RegExp(AppConstants.postalCodePattern);
                  if (!regex.hasMatch(v.trim())) return '正しい郵便番号を入力してください（例: 123-4567）';
                  return null;
                },
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
                maxLength: AppConstants.maxAddressLength,
              ),

              const SizedBox(height: 20),
              const _SectionTitle('経験・スキル'),

              TextFormField(
                controller: _experienceYearsCtrl,
                decoration: const InputDecoration(
                  labelText: '経験年数',
                  hintText: '例）5年',
                  suffixText: '年',
                ),
                keyboardType: TextInputType.number,
                maxLength: AppConstants.maxExperienceYearsLength,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _introCtrl,
                decoration: const InputDecoration(
                  labelText: '自己紹介',
                  hintText: '得意な作業や経験をアピールしましょう',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: AppConstants.maxIntroductionLength,
              ),
              const SizedBox(height: 16),

              const _SectionTitle('保有資格'),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < _qualifications.length; i++)
                    Chip(
                      label: Text(_qualifications[i]),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: isAnon ? null : () {
                        setState(() => _qualifications.removeAt(i));
                      },
                      backgroundColor: AppColors.ruriPale,
                      labelStyle: const TextStyle(color: AppColors.ruri, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qualificationInputCtrl,
                      maxLength: AppConstants.maxQualificationLength,
                      decoration: InputDecoration(
                        hintText: '資格名を入力',
                        isDense: true,
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isAnon ? null : () {
                      final text = _qualificationInputCtrl.text.trim();
                      if (text.isEmpty) return;
                      setState(() {
                        _qualifications.add(text);
                        _qualificationInputCtrl.clear();
                      });
                    },
                    icon: const Icon(Icons.add_circle, color: AppColors.ruri, size: 32),
                    tooltip: '資格を追加',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final suggestion in ['足場組立', '玉掛け', 'フォークリフト', '電気工事士', '溶接', '危険物取扱者'])
                    ActionChip(
                      label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                      onPressed: isAnon ? null : () {
                        if (!_qualifications.contains(suggestion)) {
                          setState(() => _qualifications.add(suggestion));
                        }
                      },
                    ),
                ],
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
          style: const TextStyle(
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
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
