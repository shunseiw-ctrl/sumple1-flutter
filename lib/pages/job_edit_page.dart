import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/services/image_upload_service.dart';
import '../core/utils/logger.dart';

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

  bool _isLoading = false;

  // 画像関連
  final _imageService = ImageUploadService();
  final List<String> _imageUrls = [];
  bool _uploadingImage = false;
  static const int _maxImages = 5;

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

    // 既存の画像URLを読み込み
    final existingImages = widget.jobData['imageUrls'];
    if (existingImages is List) {
      for (final url in existingImages) {
        if (url is String && url.isNotEmpty) {
          _imageUrls.add(url);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
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

  // YYYY-MM-DD
  String _dateKey(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // YYYY-MM
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

  /// 画像を追加
  Future<void> _addImage() async {
    if (_imageUrls.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像は最大${_maxImages}枚までです')),
      );
      return;
    }

    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  '写真を追加',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('カメラで撮影'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
                title: const Text('ギャラリーから選択'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    setState(() => _uploadingImage = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      ImageUploadResult result;
      if (source == 'camera') {
        result = await _imageService.captureAndUploadImage(
          userId: user.uid,
          folder: 'jobs',
          documentId: widget.jobId,
        );
      } else {
        result = await _imageService.pickAndUploadImage(
          userId: user.uid,
          folder: 'jobs',
          documentId: widget.jobId,
        );
      }

      if (!mounted) return;

      if (result.success && result.downloadUrl != null) {
        setState(() {
          _imageUrls.add(result.downloadUrl!);
        });
        Logger.info('Image added to edit', tag: 'JobEditPage',
            data: {'count': _imageUrls.length});
      } else if (!result.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? '画像のアップロードに失敗しました')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像のアップロードに失敗しました')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  /// 画像を削除
  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  Future<void> _update() async {
    if (_isLoading) return;

    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final priceText = _priceController.text.trim();
    final dateKey = _dateController.text.trim(); // YYYY-MM-DD

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

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'title': title,
        'location': location,
        'prefecture': prefecture,
        'price': price,

        // 表示＆検索キー
        'date': dateKey,
        'workDateKey': dateKey,
        'workMonthKey': monthKey,

        'description': description,
        'notes': notes,

        // 画像URL配列
        'imageUrls': _imageUrls,

        'updatedAt': FieldValue.serverTimestamp(),
      });

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
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          '案件を編集',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
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
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black54,
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

            // 写真セクション
            _WhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '写真',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_imageUrls.length}/$_maxImages',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // 既存の画像
                        for (int i = 0; i < _imageUrls.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _imageUrls[i],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(i),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 追加ボタン
                        if (_imageUrls.length < _maxImages)
                          GestureDetector(
                            onTap: _uploadingImage ? null : _addImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F3F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE6E8EB),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: _uploadingImage
                                  ? const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate,
                                            color: Colors.black54, size: 28),
                                        SizedBox(height: 4),
                                        Text(
                                          '追加',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const _HintCard(
              title: 'ヒント',
              body: '更新後は一覧に戻ります。日程はカレンダーから選択できます。写真は最大5枚まで添付できます。',
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
        Text(subtitle, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
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
            fillColor: const Color(0xFFF2F3F5),
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
          Text(body, style: const TextStyle(color: Colors.black87, height: 1.35)),
        ],
      ),
    );
  }
}
