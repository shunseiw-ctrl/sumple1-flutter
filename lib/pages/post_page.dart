import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
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

  final List<XFile> _selectedImages = [];
  static const _maxImages = 5;
  final _picker = ImagePicker();

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
          title: Text(context.l10n.post_noPermissionTitle),
          content: Text(context.l10n.post_noPermissionMessage),
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


  Future<void> _pickImages() async {
    final remaining = _maxImages - _selectedImages.length;
    if (remaining <= 0) return;

    final images = await _picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (images.isEmpty) return;

    setState(() {
      _selectedImages.addAll(images.take(remaining));
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages(String jobId) async {
    final urls = <String>[];
    for (int i = 0; i < _selectedImages.length; i++) {
      final file = File(_selectedImages[i].path);
      final ref = FirebaseStorage.instance
          .ref('job_images/$jobId/image_$i.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
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
      helpText: context.l10n.post_datePickerHelp,
      cancelText: context.l10n.post_datePickerCancel,
      confirmText: context.l10n.post_datePickerConfirm,
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
        SnackBar(content: Text(context.l10n.post_snackCheckingPermission)),
      );
      return;
    }
    if (!_isAdminUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.post_snackAdminOnly)),
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
        SnackBar(content: Text(context.l10n.post_snackEmptyFields)),
      );
      return;
    }

    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!iso.hasMatch(dateKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.post_snackSelectDateFromCalendar)),
      );
      return;
    }

    final price = int.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.post_snackPriceNumeric)),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.post_snackLoginRequired)),
      );
      return;
    }

    final monthKey = date_utils.monthKeyFromDateKey(dateKey);

    setState(() => _isLoading = true);

    final lat = double.tryParse(_latitudeController.text.trim());
    final lng = double.tryParse(_longitudeController.text.trim());

    try {
      final docRef = await FirebaseFirestore.instance.collection('jobs').add({
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

      // 画像アップロード
      if (_selectedImages.isNotEmpty) {
        final imageUrls = await _uploadImages(docRef.id);
        await docRef.update({
          'imageUrls': imageUrls,
          'imageUrl': imageUrls.first,
        });
      }

      if (!mounted) return;
      AppHaptics.success();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.post_snackPostFailed(e.toString()))),
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
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(
          context.l10n.post_title,
          style: TextStyle(color: context.appColors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: context.appColors.surface,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.appColors.primary.withValues(alpha: 0.4),
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
                  : Text(
                context.l10n.post_submitButton,
                style: const TextStyle(fontWeight: FontWeight.w900),
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
            SectionTitle(
              title: context.l10n.post_sectionBasicInfo,
              subtitle: context.l10n.post_sectionBasicInfoSubtitle,
            ),
            const SizedBox(height: 10),
            WhiteCard(
              child: Column(
                children: [
                  LabeledField(
                    label: context.l10n.post_titleLabel,
                    hint: context.l10n.post_titleHint,
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    maxLength: AppConstants.maxJobTitleLength,
                  ),
                  const FormDivider(),
                  LabeledField(
                    label: context.l10n.post_locationLabel,
                    hint: context.l10n.post_locationHint,
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
                    label: context.l10n.post_priceLabel,
                    hint: context.l10n.post_priceHint,
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.currency_yen,
                  ),
                  const FormDivider(),
                  LabeledField(
                    label: context.l10n.post_dateLabel,
                    hint: context.l10n.post_dateHint,
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
                    label: context.l10n.post_latitudeLabel,
                    hint: context.l10n.post_latitudeHint,
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.my_location,
                  ),
                  const FormDivider(),
                  LabeledField(
                    label: context.l10n.post_longitudeLabel,
                    hint: context.l10n.post_longitudeHint,
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.my_location,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SectionTitle(
              title: context.l10n.post_sectionImages,
              subtitle: context.l10n.post_sectionImagesSubtitle,
            ),
            const SizedBox(height: 10),
            WhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                child: Image.file(
                                  File(_selectedImages[i].path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(i),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: context.appColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  if (_selectedImages.isNotEmpty) const SizedBox(height: AppSpacing.md),
                  if (_selectedImages.length < _maxImages)
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(context.l10n.post_addImages(_selectedImages.length.toString(), _maxImages.toString())),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            HintCard(
              title: context.l10n.post_hintTitle,
              body: context.l10n.post_hintBody,
            ),
          ],
        ),
      ),
    );
  }
}
