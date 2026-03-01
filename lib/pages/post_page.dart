import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/core/services/analytics_service.dart';

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
    final data = doc.data() as Map<String, dynamic>?;
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

  String _guessPrefecture(String location) {
    const prefs = [
      '千葉県','東京都','神奈川県',
      '北海道','青森県','岩手県','宮城県','秋田県','山形県','福島県',
      '茨城県','栃木県','群馬県','埼玉県',
      '新潟県','富山県','石川県','福井県','山梨県','長野県','岐阜県','静岡県','愛知県',
      '三重県','滋賀県','京都府','大阪府','兵庫県','奈良県','和歌山県',
      '鳥取県','島根県','岡山県','広島県','山口県',
      '徳島県','香川県','愛媛県','高知県',
      '福岡県','佐賀県','長崎県','熊本県','大分県','宮崎県','鹿児島県',
      '沖縄県',
    ];

    for (final p in prefs) {
      if (location.contains(p)) return p;
    }
    if (location.contains('東京')) return '東京都';
    if (location.contains('千葉')) return '千葉県';
    if (location.contains('神奈川')) return '神奈川県';
    if (location.contains('大阪')) return '大阪府';
    if (location.contains('京都')) return '京都府';
    return '未設定';
  }

  String _dateKey(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _monthKeyFromDateKey(String dateKey) {
    if (dateKey.length >= 7) return dateKey.substring(0, 7);
    return '';
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

    _dateController.text = _dateKey(picked);
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
    final prefecture = _guessPrefecture(location);

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

    final monthKey = _monthKeyFromDateKey(dateKey);

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
        title: Text(
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
                disabledBackgroundColor: AppColors.ruri.withOpacity(0.4),
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
            const _SectionTitle(
              title: '基本情報',
              subtitle: '案件の内容を入力してください',
            ),
            const SizedBox(height: 10),
            _WhiteCard(
              child: Column(
                children: [
                  _LabeledField(
                    label: 'タイトル',
                    hint: '例）クロス張替え（1LDK）',
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    maxLength: AppConstants.maxJobTitleLength,
                  ),
                  const _Divider(),
                  _LabeledField(
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
            _WhiteCard(
              child: Column(
                children: [
                  _LabeledField(
                    label: '報酬（円）',
                    hint: '例）30000',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.currency_yen,
                  ),
                  const _Divider(),
                  _LabeledField(
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
            _WhiteCard(
              child: Column(
                children: [
                  _LabeledField(
                    label: '緯度（任意）',
                    hint: '例）35.6812',
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.my_location,
                  ),
                  const _Divider(),
                  _LabeledField(
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
            const _HintCard(
              title: 'ヒント',
              body: '日程はカレンダーから選択できます。緯度・経度を入力するとQR出退勤時にGPS検証が有効になります。',
            ),
          ],
        ),
      ),
    );
  }
}

// ===== UI Parts =====

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E8EB)),
        ),
        child: child,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;

  final bool readOnly;
  final VoidCallback? onTap;

  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.textInputAction,
    this.keyboardType,
    this.prefixIcon,
    this.onSubmitted,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          maxLength: maxLength,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18),
            filled: true,
            fillColor: AppColors.chipUnselected,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  final String title;
  final String body;
  const _HintCard({required this.title, required this.body});

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
          Text(body, style: TextStyle(color: AppColors.textPrimary, height: 1.35)),
        ],
      ),
    );
  }
}
