import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/services/image_upload_service.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/core/services/analytics_service.dart';

class IdentityVerificationPage extends StatefulWidget {
  const IdentityVerificationPage({super.key});

  @override
  State<IdentityVerificationPage> createState() => _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  final _imageService = ImageUploadService();
  String? _idPhotoUrl;
  String? _selfieUrl;
  bool _uploading = false;
  String? _verificationStatus;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
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
        });
      }
    } catch (e) {
      Logger.warning('本人確認ステータスの読み込みに失敗', tag: 'IdentityVerification', data: {'error': '$e'});
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
        const SnackBar(content: Text('身分証明書と顔写真の両方をアップロードしてください')),
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
          const SnackBar(content: Text('本人確認を申請しました。審査をお待ちください。')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('申請に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _buildPhotoUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? photoUrl,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _uploading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: photoUrl != null ? AppColors.success : AppColors.divider, width: photoUrl != null ? 2 : 1),
          ),
          child: Column(
            children: [
              if (photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photoUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: AppColors.chipUnselected,
                      child: Icon(icon, size: 48, color: AppColors.textHint),
                    ),
                  ),
                )
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.chipUnselected,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 40, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      const Text('タップして選択', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (photoUrl != null)
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                  else
                    const Icon(Icons.upload_file, color: AppColors.ruri, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
        color = AppColors.warning;
        message = '本人確認を審査中です。しばらくお待ちください。';
        break;
      case 'approved':
        icon = Icons.verified;
        color = AppColors.success;
        message = '本人確認が承認されました。';
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = AppColors.error;
        message = '本人確認が却下されました。再度お試しください。';
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
      appBar: AppBar(title: const Text('本人確認')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildStatusBanner(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.ruriPale,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.ruri, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '身分証明書（運転免許証・マイナンバーカード等）と顔写真を提出してください。顔写真はプロフィール写真として使用されます。',
                    style: TextStyle(fontSize: 13, color: AppColors.ruri, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPhotoUploadCard(
            title: '身分証明書',
            subtitle: '運転免許証・マイナンバーカード・パスポート等',
            icon: Icons.credit_card,
            photoUrl: _idPhotoUrl,
            onTap: (isApproved || isPending) ? () {} : _pickIdPhoto,
          ),
          const SizedBox(height: 16),
          _buildPhotoUploadCard(
            title: '顔写真（プロフィール写真）',
            subtitle: '正面からのはっきりした写真',
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
                label: const Text('本人確認を申請する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}
