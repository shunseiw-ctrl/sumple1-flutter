import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/presentation/widgets/rating_stars_display.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/services/quality_score_service.dart';
import 'package:sumple1/core/services/profile_image_service.dart';
import 'package:sumple1/core/utils/error_handler.dart';

class MyProfilePage extends StatefulWidget {
  final ProfileImageService? profileImageService;

  const MyProfilePage({super.key, this.profileImageService});

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
  bool _isUploadingAvatar = false;

  late final ProfileImageService _profileImageService;

  bool get _isAnonymous {
    final u = FirebaseAuth.instance.currentUser;
    return u == null || u.isAnonymous;
  }

  @override
  void initState() {
    super.initState();
    _profileImageService = widget.profileImageService ?? ProfileImageService();
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
      ErrorHandler.showError(context, e, customMessage: context.l10n.myProfile_loadError);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAvatarPicker(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.l10n.myProfile_pickFromGallery),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(context.l10n.myProfile_takePhoto),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(context.l10n.common_cancel),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);

    final result = choice == 'camera'
        ? await _profileImageService.captureAndUploadAvatar()
        : await _profileImageService.pickAndUploadAvatar();

    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);

    if (result.isCancelled) return;
    if (result.isSuccess) {
      ErrorHandler.showSuccess(context, context.l10n.myProfile_avatarUpdated);
    } else {
      ErrorHandler.showError(context, null, customMessage: result.errorMessage ?? context.l10n.myProfile_avatarUploadError);
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
      helpText: context.l10n.myProfile_selectBirthDate,
      cancelText: context.l10n.common_cancel,
      confirmText: context.l10n.common_ok,
    );

    if (picked == null) return;

    final yyyy = picked.year.toString().padLeft(4, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    final dd = picked.day.toString().padLeft(2, '0');
    _birthDateCtrl.text = '$yyyy-$mm-$dd';
    if (mounted) setState(() {});
  }

  String? _requiredValidator(String? v, String label) {
    if (v == null || v.trim().isEmpty) return context.l10n.myProfile_requiredField(label);
    return null;
  }

  Future<void> _save() async {
    if (_isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ErrorHandler.showError(context, null, customMessage: context.l10n.myProfile_loginRequired);
      return;
    }

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_gender == null || _gender!.trim().isEmpty) {
      ErrorHandler.showError(context, null, customMessage: context.l10n.myProfile_selectGender);
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
      ErrorHandler.showSuccess(context, context.l10n.myProfile_saveSuccess);

      Navigator.pop(context);
      return;
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e, customMessage: context.l10n.myProfile_saveError);
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
        title: Text(context.l10n.myProfile_title),
        actions: [
          TextButton(
            onPressed: (_isLoading || isAnon) ? null : _save,
            child: _isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(context.l10n.common_save),
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
                _Banner(
                  title: context.l10n.myProfile_loginRequiredTitle,
                  message: context.l10n.myProfile_loginRequiredMessage,
                ),
                const SizedBox(height: 12),
              ],

              _SectionTitle(context.l10n.myProfile_profilePhoto),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('profiles').doc(FirebaseAuth.instance.currentUser?.uid ?? '').snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data();
                  final photoUrl = (data?['profilePhotoUrl'] ?? '').toString();
                  final locked = data?['profilePhotoLocked'] == true;
                  final canUpload = !isAnon && !locked;

                  return Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: canUpload ? () => _showAvatarPicker(context) : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: context.appColors.chipUnselected,
                                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                child: _isUploadingAvatar
                                    ? const CircularProgressIndicator(strokeWidth: 2)
                                    : photoUrl.isEmpty
                                        ? Icon(Icons.person, size: 50, color: context.appColors.textHint)
                                        : null,
                              ),
                              if (canUpload)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: context.appColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (locked)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, size: 14, color: context.appColors.success),
                              const SizedBox(width: 4),
                              Text(context.l10n.myProfile_identityVerified, style: TextStyle(fontSize: 12, color: context.appColors.success, fontWeight: FontWeight.w600)),
                            ],
                          )
                        else if (!isAnon)
                          Text(context.l10n.myProfile_tapToChangePhoto, style: TextStyle(fontSize: 12, color: context.appColors.textHint))
                        else
                          Text(context.l10n.myProfile_photoSetByVerification, style: TextStyle(fontSize: 12, color: context.appColors.textHint)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _SectionTitle(context.l10n.myProfile_yourRating),
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
                          Text(
                            context.l10n.myProfile_adminRating,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _QualityScoreCard(
                uid: FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
              const SizedBox(height: 16),

              _SectionTitle(context.l10n.myProfile_stripeIntegration),
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
                    color = context.appColors.textHint;
                    label = context.l10n.myProfile_stripeNotConfigured;
                  } else if (stripeStatus == 'active') {
                    icon = Icons.check_circle;
                    color = context.appColors.success;
                    label = context.l10n.myProfile_stripeActive;
                  } else {
                    icon = Icons.pending;
                    color = context.appColors.warning;
                    label = context.l10n.myProfile_stripePending;
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
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              _SectionTitle(context.l10n.myProfile_basicInfo),

              _twoColumnFields(
                left: TextFormField(
                  controller: _familyNameCtrl,
                  decoration: InputDecoration(labelText: context.l10n.myProfile_familyNameLabel),
                  maxLength: AppConstants.maxDisplayNameLength,
                  validator: (v) => _requiredValidator(v, context.l10n.myProfile_familyName),
                  textInputAction: TextInputAction.next,
                ),
                right: TextFormField(
                  controller: _givenNameCtrl,
                  decoration: InputDecoration(labelText: context.l10n.myProfile_givenNameLabel),
                  maxLength: AppConstants.maxDisplayNameLength,
                  validator: (v) => _requiredValidator(v, context.l10n.myProfile_givenName),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 12),

              _twoColumnFields(
                left: TextFormField(
                  controller: _familyNameKanaCtrl,
                  decoration: InputDecoration(labelText: context.l10n.myProfile_familyNameKanaLabel),
                  maxLength: AppConstants.maxDisplayNameLength,
                  validator: (v) => _requiredValidator(v, context.l10n.myProfile_familyNameKana),
                  textInputAction: TextInputAction.next,
                ),
                right: TextFormField(
                  controller: _givenNameKanaCtrl,
                  decoration: InputDecoration(labelText: context.l10n.myProfile_givenNameKanaLabel),
                  maxLength: AppConstants.maxDisplayNameLength,
                  validator: (v) => _requiredValidator(v, context.l10n.myProfile_givenNameKana),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _birthDateCtrl,
                readOnly: true,
                onTap: isAnon ? null : _pickBirthDate,
                decoration: InputDecoration(
                  labelText: context.l10n.myProfile_birthDateLabel,
                  hintText: 'YYYY-MM-DD',
                  suffixIcon: IconButton(
                    onPressed: isAnon ? null : _pickBirthDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                ),
                validator: (v) => _requiredValidator(v, context.l10n.myProfile_birthDate),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(labelText: context.l10n.myProfile_genderLabel),
                items: [
                  DropdownMenuItem(value: '未回答', child: Text(context.l10n.myProfile_genderNotAnswered)),
                  DropdownMenuItem(value: '男性', child: Text(context.l10n.myProfile_genderMale)),
                  DropdownMenuItem(value: '女性', child: Text(context.l10n.myProfile_genderFemale)),
                  DropdownMenuItem(value: 'その他', child: Text(context.l10n.myProfile_genderOther)),
                ],
                onChanged: isAnon ? null : (v) => setState(() => _gender = v),
                validator: (v) {
                  if (isAnon) return null;
                  if (v == null || v.trim().isEmpty) return context.l10n.myProfile_genderRequired;
                  return null;
                },
              ),

              const SizedBox(height: 20),
              _SectionTitle(context.l10n.myProfile_addressSection),

              TextFormField(
                controller: _postalCodeCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.myProfile_postalCodeLabel,
                  hintText: context.l10n.myProfile_postalCodeHint,
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final regex = RegExp(AppConstants.postalCodePattern);
                  if (!regex.hasMatch(v.trim())) return context.l10n.myProfile_postalCodeInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.myProfile_addressLabel,
                  hintText: context.l10n.myProfile_addressHint,
                ),
                keyboardType: TextInputType.text,
                maxLines: 2,
                maxLength: AppConstants.maxAddressLength,
              ),

              const SizedBox(height: 20),
              _SectionTitle(context.l10n.myProfile_experienceSkills),

              TextFormField(
                controller: _experienceYearsCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.myProfile_experienceYearsLabel,
                  hintText: context.l10n.myProfile_experienceYearsHint,
                  suffixText: context.l10n.myProfile_yearsSuffix,
                ),
                keyboardType: TextInputType.number,
                maxLength: AppConstants.maxExperienceYearsLength,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _introCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.myProfile_introLabel,
                  hintText: context.l10n.myProfile_introHint,
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: AppConstants.maxIntroductionLength,
              ),
              const SizedBox(height: 16),

              _SectionTitle(context.l10n.myProfile_qualifications),

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
                      backgroundColor: context.appColors.primaryPale,
                      labelStyle: TextStyle(color: context.appColors.primary, fontWeight: FontWeight.w600),
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
                        hintText: context.l10n.myProfile_qualificationHint,
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
                    icon: Icon(Icons.add_circle, color: context.appColors.primary, size: 32),
                    tooltip: context.l10n.myProfile_addQualification,
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
                  child: Text(context.l10n.myProfile_saveButton),
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _QualityScoreCard extends StatelessWidget {
  final String uid;
  const _QualityScoreCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<WorkerQualityScore>(
      future: QualityScoreService().calculateScore(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appColors.primaryPale.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.primaryPale),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snap.hasError || !snap.hasData) {
          return const SizedBox.shrink();
        }

        final score = snap.data!;
        final overallScore = score.overallScore;
        final completionPercent = (score.completionRate * 100).round();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appColors.primaryPale.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.primaryPale),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.myProfile_qualityScore,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(5, (i) {
                    final starNum = i + 1;
                    if (overallScore >= starNum) {
                      return const Icon(Icons.star_rounded, size: 20, color: Colors.amber);
                    } else if (overallScore >= starNum - 0.5) {
                      return const Icon(Icons.star_half_rounded, size: 20, color: Colors.amber);
                    } else {
                      return Icon(Icons.star_outline_rounded, size: 20, color: context.appColors.textHint);
                    }
                  }),
                  const SizedBox(width: 6),
                  Text(
                    overallScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ScoreRow(
                label: context.l10n.myProfile_ratingAverage,
                value: '${score.ratingsAverage.toStringAsFixed(1)} (${score.ratingsCount}${context.l10n.common_itemsCount})',
              ),
              const SizedBox(height: 4),
              _ScoreRow(
                label: context.l10n.myProfile_completionRate,
                value: '$completionPercent% (${score.totalCompleted}/${score.totalAssigned})',
              ),
              const SizedBox(height: 4),
              _ScoreRow(
                label: context.l10n.myProfile_verifiedQualifications,
                value: '${score.verifiedQualificationCount}${context.l10n.common_itemsCount}',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  const _ScoreRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Text('├ ', style: TextStyle(fontSize: 12, color: context.appColors.textHint)),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.appColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
      ],
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
        color: context.appColors.chipUnselected,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, style: TextStyle(color: context.appColors.textSecondary)),
        ],
      ),
    );
  }
}
