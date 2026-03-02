import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/core/services/referral_service.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/services/share_service.dart';

class ReferralPage extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? firebaseAuth;

  const ReferralPage({super.key, this.firestore, this.firebaseAuth});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  late final ReferralService _referralService;
  late final FirebaseAuth _auth;

  final _codeController = TextEditingController();
  String? _myCode;
  int _referralCount = 0;
  bool _isLoading = true;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _auth = widget.firebaseAuth ?? FirebaseAuth.instance;
    _referralService = ReferralService(
      firestore: widget.firestore,
      auth: _auth,
    );
    AnalyticsService.logScreenView('referral');
    _loadData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final code = await _referralService.generateCode(uid);
      final stats = await _referralService.getReferralStats(uid);
      if (mounted) {
        setState(() {
          _myCode = code;
          _referralCount = stats;
          _isLoading = false;
        });
      }
      await AnalyticsService.logReferralCreate();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _showSnackBar('ログインが必要です');
      return;
    }

    setState(() => _isApplying = true);

    try {
      await _referralService.applyCode(code, uid);
      await AnalyticsService.logReferralApply(code);
      if (mounted) {
        _codeController.clear();
        _showSnackBar('紹介コードを適用しました');
        // 統計を更新
        final stats = await _referralService.getReferralStats(uid);
        setState(() {
          _referralCount = stats;
          _isApplying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _copyCode() {
    if (_myCode == null) return;
    Clipboard.setData(ClipboardData(text: _myCode!));
    _showSnackBar('コードをコピーしました');
  }

  void _shareCode() {
    if (_myCode == null) return;
    ShareService.shareReferral(_myCode!);
    AnalyticsService.logShareReferral();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('友達を招待', style: AppTextStyles.appBarTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  children: [
                    _buildMyCodeCard(),
                    const SizedBox(height: AppSpacing.sectionGap),
                    _buildApplyCodeCard(),
                    const SizedBox(height: AppSpacing.sectionGap),
                    _buildStatsCard(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMyCodeCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Text(
            'あなたの紹介コード',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.base,
            ),
            decoration: BoxDecoration(
              color: AppColors.ruriPale,
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              border: Border.all(color: AppColors.ruri.withValues(alpha: 0.2)),
            ),
            child: SelectableText(
              _myCode ?? '------',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.ruri,
                letterSpacing: 6,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _myCode != null ? _copyCode : null,
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text('コピー', style: AppTextStyles.buttonSmall),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ruri,
                    side: const BorderSide(color: AppColors.ruri),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _myCode != null ? _shareCode : null,
                  icon: const Icon(Icons.share, size: 18),
                  label: Text(
                    'シェア',
                    style: AppTextStyles.buttonSmall.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ruri,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplyCodeCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '紹介コードを入力',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '友達から受け取った紹介コードを入力してください',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.base),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '例: ABC123',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: const BorderSide(color: AppColors.ruri, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
            ),
            style: AppTextStyles.bodyLarge.copyWith(
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isApplying ? null : _applyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: _isApplying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      '適用する',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_alt_outlined,
            size: 40,
            color: AppColors.ruri,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '紹介実績',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$_referralCount 人',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.ruri,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '友達を招待して特典を受け取ろう',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
