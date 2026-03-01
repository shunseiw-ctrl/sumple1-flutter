import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumple1/core/constants/app_colors.dart';

class JobEditPage extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const JobEditPage({
    super.key,
    required this.jobId,
    required this.jobData,
  });

  @override
  State<JobEditPage> createState() => _JobEditPageState();
}

class _JobEditPageState extends State<JobEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;
  late final TextEditingController _dateController;

  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(text: widget.jobData['title']?.toString() ?? '');
    _locationController =
        TextEditingController(text: widget.jobData['location']?.toString() ?? '');
    _priceController =
        TextEditingController(text: widget.jobData['price']?.toString() ?? '0');
    _dateController =
        TextEditingController(text: widget.jobData['date']?.toString() ?? '');

    _descriptionController =
        TextEditingController(text: widget.jobData['description']?.toString() ?? '');
    _notesController =
        TextEditingController(text: widget.jobData['notes']?.toString() ?? '');
    _latitudeController =
        TextEditingController(text: widget.jobData['latitude']?.toString() ?? '');
    _longitudeController =
        TextEditingController(text: widget.jobData['longitude']?.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
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

  Future<void> _update() async {
    if (_isLoading) return;

    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final priceText = _priceController.text.trim();
    final dateKey = _dateController.text.trim();

    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();

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

    final prefecture = _guessPrefecture(location);
    final monthKey = _monthKeyFromDateKey(dateKey);

    final lat = double.tryParse(_latitudeController.text.trim());
    final lng = double.tryParse(_longitudeController.text.trim());

    setState(() => _isLoading = true);

    try {
      final updateData = <String, dynamic>{
        'title': title,
        'location': location,
        'prefecture': prefecture,
        'price': price,

        'date': dateKey,
        'workDateKey': dateKey,
        'workMonthKey': monthKey,

        'description': description,
        'notes': notes,

        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (lat != null) updateData['latitude'] = lat;
      if (lng != null) updateData['longitude'] = lng;

      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update(updateData);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '案件を編集',
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
              onPressed: _isLoading ? null : _update,
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
                '更新する',
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
              title: '編集内容',
              subtitle: '案件の情報を更新してください',
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
                  ),
                  const _Divider(),
                  _LabeledField(
                    label: '場所',
                    hint: '例）千葉県千葉市花見川区',
                    controller: _locationController,
                    textInputAction: TextInputAction.next,
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
                    label: '仕事内容',
                    hint: '例）現場作業の補助、清掃、資材運搬など',
                    controller: _descriptionController,
                    textInputAction: TextInputAction.next,
                    maxLines: 6,
                  ),
                  const _Divider(),
                  _LabeledField(
                    label: '注意事項',
                    hint: '例）遅刻厳禁、安全第一、詳細はチャットで確認など',
                    controller: _notesController,
                    textInputAction: TextInputAction.done,
                    maxLines: 6,
                    onSubmitted: (_) => _update(),
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
              body: '更新後は一覧に戻ります。日程はカレンダーから選択できます。緯度・経度を設定するとQR出退勤時のGPS検証が有効になります。',
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
  final int maxLines;

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
    this.maxLines = 1,
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
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18),
            filled: true,
            fillColor: AppColors.chipUnselected,
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
