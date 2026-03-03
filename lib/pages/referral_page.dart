import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
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
      _showSnackBar(context.l10n.referral_loginRequired);
      return;
    }

    setState(() => _isApplying = true);

    try {
      await _referralService.applyCode(code, uid);
      await AnalyticsService.logReferralApply(code);
      if (mounted) {
        _codeController.clear();
        _showSnackBar(context.l10n.referral_codeApplied);
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
    _showSnackBar(context.l10n.referral_codeCopied);
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
        title: Text(context.l10n.referral_title, style: AppTextStyles.appBarTitle),
        backgroundColor: context.appColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: context.appColors.background,
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
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Text(
            context.l10n.referral_yourCode,
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.base,
            ),
            decoration: BoxDecoration(
              color: context.appColors.primaryPale,
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              border: Border.all(color: context.appColors.primary.withValues(alpha: 0.2)),
            ),
            child: SelectableText(
              _myCode ?? '------',
              style: AppTextStyles.displayMedium.copyWith(
                color: context.appColors.primary,
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
                  label: Text(context.l10n.referral_copy, style: AppTextStyles.buttonSmall),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.appColors.primary,
                    side: BorderSide(color: context.appColors.primary),
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
                    context.l10n.referral_share,
                    style: AppTextStyles.buttonSmall.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.primary,
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
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.referral_enterCode,
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.referral_enterCodeDescription,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.base),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: InputDecoration(
              // TODO: i18n - referral_codeHint
              hintText: '例: ABC123',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: context.appColors.textHint),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: BorderSide(color: context.appColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: BorderSide(color: context.appColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: BorderSide(color: context.appColors.primary, width: 2),
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
                backgroundColor: context.appColors.success,
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
                      // TODO: i18n - referral_applyButton
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
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 40,
            color: context.appColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            // TODO: i18n - referral_stats
            '紹介実績',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            // TODO: i18n - referral_statsCount
            '$_referralCount 人',
            style: AppTextStyles.displayMedium.copyWith(
              color: context.appColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            // TODO: i18n - referral_inviteDescription
            '友達を招待して特典を受け取ろう',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
