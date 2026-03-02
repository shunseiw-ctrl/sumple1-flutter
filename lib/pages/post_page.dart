import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/utils/prefecture_utils.dart';
import 'package:sumple1/core/utils/job_date_utils.dart' as date_utils;
import 'package:sumple1/presentation/widgets/section_title.dart';
import 'package:sumple1/presentation/widgets/white_card.dart';
import 'package:sumple1/presentation/widgets/form_divider.dart';
import 'package:sumple1/presentation/widgets/labeled_field.dart';
import 'package:sumple1/presentation/widgets/hint_card.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isLoading = false;

  bool _checkedAdmin = false;
  bool _isAdminUser = false;

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.trim().isEmpty) return false;

    final doc = await FirebaseFirestore.instance.doc('config/admins').get();
    final data = doc.data();
    final emails =
        (data?['emails'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    return emails.contains(email);
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('post');
    _guardAdmin();
  }

  Future<void> _guardAdmin() async {
    final ok = await _isAdmin();
    if (!mounted) return;
    setState(() {
      _checkedAdmin = true;
      _isAdminUser = ok;
    });
    if (!ok) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('権限がありません'),
          content: const Text('この画面は管理者のみ利用できます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    }
  }


  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    final text = _dateController.text.trim();
    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (iso.hasMatch(text)) {
      final parts = text.split('-').map(int.parse).toList();
      initial = DateTime(parts[0], parts[1], parts[2]);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: '日程を選択',
      cancelText: 'キャンセル',
      confirmText: '決定',
    );

    if (picked == null) return;

    _dateController.text = date_utils.dateKey(picked);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    if (!_checkedAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('権限確認中です。少し待ってください。')),
      );
      return;
    }
    if (!_isAdminUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('管理者のみ投稿できます')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final priceText = _priceController.text.trim();
    final dateKey = _dateController.text.trim();
    final prefecture = guessPrefecture(location);

    if (title.isEmpty || location.isEmpty || priceText.isEmpty || dateKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未入力の項目があります')),
      );
      return;
    }

    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!iso.hasMatch(dateKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日程はカレンダーから選択してください')),
      );
      return;
    }

    final price = int.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('金額は数字で入力してください')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }

    final monthKey = date_utils.monthKeyFromDateKey(dateKey);

    setState(() => _isLoading = true);

    final lat = double.tryParse(_latitudeController.text.trim());
    final lng = double.tryParse(_longitudeController.text.trim());

    try {
      await FirebaseFirestore.instance.collection('jobs').add({
        'title': title,
        'location': location,
        'prefecture': prefecture,
        'price': price,

        'date': dateKey,
        'workDateKey': dateKey,
        'workMonthKey': monthKey,

        'ownerId': user.uid,

        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        'description': '',
        'notes': '',
      });

      if (!mounted) return;
      AppHaptics.success();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('投稿失敗: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '案件を投稿',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ruri,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.ruri.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
                  : const Text(
                '投稿する',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          children: [
            const SectionTitle(
              title: '基本情報',
              subtitle: '案件の内容を入力してください',
            ),
            const SizedBox(height: 10),
            WhiteCard(
              child: Column(
                children: [
                  LabeledField(
                    label: 'タイトル',
                    hint: '例）クロス張替え（1LDK）',
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    maxLength: AppConstants.maxJobTitleLength,
                  ),
                  const FormDivider(),
                  LabeledField(
                    label: '場所',
                    hint: '例）千葉県千葉市花見川区',
                    controller: _locationController,
                    textInputAction: TextInputAction.next,
                    maxLength: AppConstants.maxJobLocationLength,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            WhiteCard(
              child: Column(
                children: [
                  LabeledField(
                    label: '報酬（円）',
                    hint: '例）30000',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.currency_yen,
                  ),
                  const FormDivider(),
                  LabeledField(
                    label: '日程',
                    hint: 'タップして日付を選択',
                    controller: _dateController,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.event,
                    readOnly: true,
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            WhiteCard(
              child: Column(
                children: [
                  LabeledField(
                    label: '緯度（任意）',
                    hint: '例）35.6812',
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.my_location,
                  ),
                  const FormDivider(),
                  LabeledField(
                    label: '経度（任意）',
                    hint: '例）139.7671',
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.my_location,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const HintCard(
              title: 'ヒント',
              body: '日程はカレンダーから選択できます。緯度・経度を入力するとQR出退勤時にGPS検証が有効になります。',
            ),
          ],
        ),
      ),
    );
  }
}
