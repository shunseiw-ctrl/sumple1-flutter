import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/services/image_upload_service.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/services/ekyc_service.dart';
import 'package:sumple1/core/services/ekyc_manual_service.dart';
import 'package:sumple1/data/models/identity_verification_model.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';

class IdentityVerificationPage extends StatefulWidget {
  final EkycService? ekycService;
  const IdentityVerificationPage({super.key, this.ekycService});

  @override
  State<IdentityVerificationPage> createState() => _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  final _imageService = ImageUploadService();
  // ignore: unused_field
  late final EkycService _ekycService;
  String? _idPhotoUrl;
  String? _selfieUrl;
  bool _uploading = false;
  String? _verificationStatus;
  String _documentType = 'drivers_license';
  String? _rejectionReason;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _ekycService = widget.ekycService ?? ManualEkycService();
    AnalyticsService.logScreenView('identity_verification');
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    if (_uid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('identity_verification')
          .doc(_uid)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _verificationStatus = (data['status'] ?? '').toString();
          _idPhotoUrl = (data['idPhotoUrl'] ?? '').toString();
          _selfieUrl = (data['selfieUrl'] ?? '').toString();
          if (_idPhotoUrl!.isEmpty) _idPhotoUrl = null;
          if (_selfieUrl!.isEmpty) _selfieUrl = null;
          _documentType = (data['documentType'] ?? 'drivers_license').toString();
          _rejectionReason = data['rejectionReason']?.toString();
        });
      }
    } catch (e) {
      Logger.warning('本人確認ステータスの読み込みに失敗', tag: 'IdentityVerification', data: {'error': '$e'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.identityVerification_loadStatusFailed)),
        );
      }
    }
  }

  Future<void> _pickIdPhoto() async {
    if (_uploading || _uid.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final result = await _imageService.pickAndUploadImage(
        userId: _uid,
        folder: 'identity_verification',
        documentId: 'id_photo',
        maxWidth: 1920,
        maxHeight: 1080,
        quality: 90,
      );
      if (result.isSuccess && result.downloadUrl != null) {
        setState(() => _idPhotoUrl = result.downloadUrl);
      } else if (!result.cancelled && result.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage!)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickSelfie() async {
    if (_uploading || _uid.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final result = await _imageService.pickAndUploadImage(
        userId: _uid,
        folder: 'identity_verification',
        documentId: 'selfie',
        maxWidth: 1080,
        maxHeight: 1080,
        quality: 90,
      );
      if (result.isSuccess && result.downloadUrl != null) {
        setState(() => _selfieUrl = result.downloadUrl);
      } else if (!result.cancelled && result.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage!)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (_idPhotoUrl == null || _selfieUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.identityVerification_uploadBoth)),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      await FirebaseFirestore.instance
          .collection('identity_verification')
          .doc(_uid)
          .set({
        'idPhotoUrl': _idPhotoUrl,
        'selfieUrl': _selfieUrl,
        'documentType': _documentType,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'uid': _uid,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('profiles').doc(_uid).set({
        'profilePhotoUrl': _selfieUrl,
        'profilePhotoLocked': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _verificationStatus = 'pending');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.identityVerification_submitted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.identityVerification_submitFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _buildStep(int number, String label, bool completed) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? context.appColors.success : context.appColors.divider,
            ),
            child: Center(
              child: completed
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: context.appColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool completed) {
    return Expanded(
      child: Container(
        height: 2,
        color: completed ? context.appColors.success : context.appColors.divider,
      ),
    );
  }

  Widget _buildPhotoUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? photoUrl,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _uploading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: photoUrl != null ? context.appColors.success : context.appColors.divider, width: photoUrl != null ? 2 : 1),
          ),
          child: Column(
            children: [
              if (photoUrl != null)
                AppCachedImage(
                  imageUrl: photoUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: 12,
                  errorWidget: Container(
                    height: 160,
                    color: context.appColors.chipUnselected,
                    child: Icon(icon, size: 48, color: context.appColors.textHint),
                  ),
                )
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.appColors.chipUnselected,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 40, color: context.appColors.textHint),
                      const SizedBox(height: 8),
                      Text(context.l10n.identityVerification_tapToSelect, style: TextStyle(fontSize: 13, color: context.appColors.textHint)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (photoUrl != null)
                    Icon(Icons.check_circle, color: context.appColors.success, size: 20)
                  else
                    Icon(Icons.upload_file, color: context.appColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(subtitle, style: TextStyle(fontSize: 12, color: context.appColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_verificationStatus == null || _verificationStatus!.isEmpty) return const SizedBox.shrink();

    IconData icon;
    Color color;
    String message;

    switch (_verificationStatus) {
      case 'pending':
        icon = Icons.hourglass_empty;
        color = context.appColors.warning;
        message = context.l10n.identityVerification_statusPending;
        break;
      case 'approved':
        icon = Icons.verified;
        color = context.appColors.success;
        message = context.l10n.identityVerification_statusApproved;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = context.appColors.error;
        message = context.l10n.identityVerification_statusRejected;
        if (_rejectionReason != null && _rejectionReason!.isNotEmpty) {
          message += '\n${context.l10n.identityVerification_rejectionReason(_rejectionReason!)}';
        }
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = _verificationStatus == 'approved';
    final isPending = _verificationStatus == 'pending';

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.identityVerification_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Step indicator
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                _buildStep(1, context.l10n.identityVerification_stepUploadId, _idPhotoUrl != null),
                _buildStepConnector(_idPhotoUrl != null),
                _buildStep(2, context.l10n.identityVerification_stepSelfie, _selfieUrl != null),
                _buildStepConnector(_selfieUrl != null),
                _buildStep(3, context.l10n.identityVerification_stepSubmit, _verificationStatus == 'pending' || _verificationStatus == 'approved'),
              ],
            ),
          ),
          _buildStatusBanner(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.appColors.primaryPale,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: context.appColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.identityVerification_instructions,
                    style: TextStyle(fontSize: 13, color: context.appColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // eKYC banner
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.appColors.infoLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: context.appColors.info, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.identityVerification_ekycBanner,
                    style: TextStyle(fontSize: 12, color: context.appColors.info, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (!isApproved && !isPending)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.appColors.divider),
              ),
              child: DropdownButtonFormField<String>(
                value: _documentType,
                decoration: InputDecoration(
                  labelText: context.l10n.identityVerification_documentTypeLabel,
                  border: InputBorder.none,
                ),
                items: IdentityVerificationModel.documentTypes.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _documentType = value);
                  }
                },
              ),
            ),
          _buildPhotoUploadCard(
            title: context.l10n.identityVerification_idDocumentTitle,
            subtitle: context.l10n.identityVerification_idDocumentSubtitle,
            icon: Icons.credit_card,
            photoUrl: _idPhotoUrl,
            onTap: (isApproved || isPending) ? () {} : _pickIdPhoto,
          ),
          const SizedBox(height: 16),
          _buildPhotoUploadCard(
            title: context.l10n.identityVerification_selfieTitle,
            subtitle: context.l10n.identityVerification_selfieSubtitle,
            icon: Icons.face,
            photoUrl: _selfieUrl,
            onTap: (isApproved || isPending) ? () {} : _pickSelfie,
          ),
          const SizedBox(height: 24),
          if (_uploading)
            const Center(child: CircularProgressIndicator())
          else if (!isApproved && !isPending)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_idPhotoUrl != null && _selfieUrl != null) ? _submit : null,
                icon: const Icon(Icons.send),
                label: Text(context.l10n.identityVerification_submitButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          if (_verificationStatus == 'rejected' && !_uploading)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _verificationStatus = null;
                      _idPhotoUrl = null;
                      _selfieUrl = null;
                      _rejectionReason = null;
                      _documentType = 'drivers_license';
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.identityVerification_resubmitButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
