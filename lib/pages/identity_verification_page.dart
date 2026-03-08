import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/providers/firebase_providers.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/services/image_upload_service.dart';
import 'package:sumple1/core/services/face_match_service.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/core/services/ekyc_service.dart';
import 'package:sumple1/core/services/ekyc_manual_service.dart';
import 'package:sumple1/data/models/identity_verification_model.dart';

class IdentityVerificationPage extends ConsumerStatefulWidget {
  final EkycService? ekycService;
  const IdentityVerificationPage({super.key, this.ekycService});

  @override
  ConsumerState<IdentityVerificationPage> createState() => _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends ConsumerState<IdentityVerificationPage> {
  final _imageService = ImageUploadService();
  final _faceMatchService = FaceMatchService();
  // ignore: unused_field
  late final EkycService _ekycService;
  String? _idPhotoUrl;
  String? _idPhotoBackUrl;
  String? _selfieUrl;
  // ローカルバイト（即座にプレビュー表示用）
  Uint8List? _idPhotoFrontBytes;
  Uint8List? _idPhotoBackBytes;
  Uint8List? _selfieBytes;
  bool _uploading = false;
  String? _verificationStatus;
  String _documentType = 'drivers_license';
  String? _rejectionReason;
  bool _livenessVerified = false;
  String? _loadingMessage;

  String get _uid => ref.read(firebaseAuthProvider).currentUser?.uid ?? '';

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
      final doc = await ref.read(firestoreProvider)
          .collection('identity_verification')
          .doc(_uid)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _verificationStatus = (data['status'] ?? '').toString();
          _idPhotoUrl = (data['idPhotoUrl'] ?? '').toString();
          if (_idPhotoUrl!.isEmpty) _idPhotoUrl = null;
          _idPhotoBackUrl = data['idPhotoBackUrl']?.toString();
          if (_idPhotoBackUrl != null && _idPhotoBackUrl!.isEmpty) _idPhotoBackUrl = null;
          _selfieUrl = (data['selfieUrl'] ?? '').toString();
          if (_selfieUrl!.isEmpty) _selfieUrl = null;
          _documentType = (data['documentType'] ?? 'drivers_license').toString();
          _rejectionReason = data['rejectionReason']?.toString();
          _livenessVerified = data['livenessVerified'] == true;
        });

        // rejected/新規のみDL（approved/pendingは閲覧のみなのでDL不要）
        if (_verificationStatus == 'rejected' || _verificationStatus == null || _verificationStatus!.isEmpty) {
          _downloadImageBytes();
        }
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

  /// Firebase Storage URLからバイトデータをダウンロード
  Future<void> _downloadImageBytes() async {
    final storage = FirebaseStorage.instance;
    final futures = <Future>[];

    if (_idPhotoUrl != null && _idPhotoFrontBytes == null) {
      futures.add(_downloadFromUrl(storage, _idPhotoUrl!).then((bytes) {
        if (bytes != null && mounted) {
          setState(() => _idPhotoFrontBytes = bytes);
        }
      }));
    }
    if (_idPhotoBackUrl != null && _idPhotoBackBytes == null) {
      futures.add(_downloadFromUrl(storage, _idPhotoBackUrl!).then((bytes) {
        if (bytes != null && mounted) {
          setState(() => _idPhotoBackBytes = bytes);
        }
      }));
    }
    if (_selfieUrl != null && _selfieBytes == null) {
      futures.add(_downloadFromUrl(storage, _selfieUrl!).then((bytes) {
        if (bytes != null && mounted) {
          setState(() => _selfieBytes = bytes);
        }
      }));
    }

    await Future.wait(futures);
  }

  /// URLからStorageバイトデータを取得
  Future<Uint8List?> _downloadFromUrl(FirebaseStorage storage, String url) async {
    try {
      final ref = storage.refFromURL(url);
      final bytes = await ref.getData(10 * 1024 * 1024); // 10MB上限
      Logger.info('画像DL成功', tag: 'IdentityVerification',
          data: {'size': '${((bytes?.length ?? 0) / 1024).toStringAsFixed(0)} KB'});
      return bytes;
    } catch (e) {
      Logger.warning('画像DLに失敗', tag: 'IdentityVerification', data: {'error': '$e'});
      return null;
    }
  }

  /// カメラ撮影 or ギャラリー選択のボトムシート
  Future<void> _showPickerSheet({
    required String side,
    required String folder,
    required String documentId,
  }) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(context.l10n.idCapture_cameraCapture),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.l10n.idCapture_gallerySelect),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'camera') {
      await _captureWithCamera(side: side, documentId: documentId);
    } else {
      await _pickFromGallery(side: side, documentId: documentId);
    }
  }

  /// カメラ撮影（IdDocumentCapturePageに遷移）
  Future<void> _captureWithCamera({required String side, required String documentId}) async {
    final result = await context.push<Uint8List>(
      RoutePaths.idDocumentCapture,
      extra: {'side': side},
    );

    if (result != null && mounted) {
      await _uploadImageBytes(result, documentId: documentId, side: side);
    }
  }

  /// ギャラリーから選択
  Future<void> _pickFromGallery({required String side, required String documentId}) async {
    if (_uploading || _uid.isEmpty) return;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );
      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();
      if (mounted) {
        await _uploadImageBytes(bytes, documentId: documentId, side: side);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.identityVerification_submitFailed('$e'))),
        );
      }
    }
  }

  /// バイトデータをアップロード
  Future<void> _uploadImageBytes(Uint8List bytes, {required String documentId, required String side}) async {
    if (_uid.isEmpty) return;

    // ローカルバイトを即座に保持（プレビュー表示用）
    setState(() {
      _uploading = true;
      if (side == 'front') {
        _idPhotoFrontBytes = bytes;
      } else if (side == 'back') {
        _idPhotoBackBytes = bytes;
      } else {
        _selfieBytes = bytes;
      }
    });

    try {
      final result = await _imageService.uploadImageBytes(
        bytes: bytes,
        userId: _uid,
        folder: 'identity_verification',
        documentId: documentId,
      );

      if (result.isSuccess && result.downloadUrl != null) {
        setState(() {
          if (side == 'front') {
            _idPhotoUrl = result.downloadUrl;
          } else if (side == 'back') {
            _idPhotoBackUrl = result.downloadUrl;
          } else {
            _selfieUrl = result.downloadUrl;
          }
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? context.l10n.identityVerification_submitFailed(''))),
        );
      }
    } catch (e) {
      Logger.error('アップロード例外', tag: 'IdentityVerification', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.identityVerification_submitFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Liveness Detection 実行
  Future<void> _startLivenessDetection() async {
    final result = await context.push<Uint8List>(RoutePaths.livenessDetection);

    if (result != null && mounted) {
      setState(() => _livenessVerified = true);
      // 自撮り画像をアップロード
      await _uploadImageBytes(result, documentId: 'selfie', side: 'selfie');
    } else if (mounted && result == null) {
      // Livenessは完了したが自撮り撮影に失敗した場合
      // キャンセルした場合もここに来るので、何もしない
    }
  }

  /// 顔照合して申請
  Future<void> _submitWithFaceMatch() async {
    if (_idPhotoUrl == null || _selfieUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.identityVerification_uploadBoth)),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _loadingMessage = context.l10n.identityVerification_uploading;
    });

    try {
      // まずFirestoreに書き込み（顔照合用のデータ準備）
      await ref.read(firestoreProvider)
          .collection('identity_verification')
          .doc(_uid)
          .set({
        'idPhotoUrl': _idPhotoUrl,
        if (_idPhotoBackUrl != null) 'idPhotoBackUrl': _idPhotoBackUrl,
        'selfieUrl': _selfieUrl,
        'documentType': _documentType,
        'status': 'pending',
        'livenessVerified': _livenessVerified,
        if (_livenessVerified) 'livenessCompletedAt': FieldValue.serverTimestamp(),
        'submittedAt': FieldValue.serverTimestamp(),
        'uid': _uid,
      }, SetOptions(merge: true));

      // 顔照合実行
      setState(() => _loadingMessage = context.l10n.identityVerification_faceMatching);
      final faceResult = await _faceMatchService.verifyFaceMatch(_uid);

      if (!mounted) return;

      if (faceResult.matched) {
        // 顔照合成功 → プロフィールアイコン自動設定
        setState(() => _loadingMessage = context.l10n.identityVerification_settingProfile);
        await _setProfilePhoto();

        setState(() => _verificationStatus = 'pending');
        AppHaptics.success();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.identityVerification_faceMatchSuccess),
              backgroundColor: context.appColors.success,
            ),
          );
        }
      } else {
        // 顔照合失敗
        if (mounted) {
          _showFaceMatchFailedDialog(faceResult.score);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.identityVerification_submitFailed('$e'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _loadingMessage = null;
        });
      }
    }
  }

  /// プロフィールアイコン自動設定
  Future<void> _setProfilePhoto() async {
    try {
      if (_selfieUrl == null) return;

      await ref.read(firestoreProvider).collection('profiles').doc(_uid).set({
        'profilePhotoUrl': _selfieUrl,
        'profilePhotoLocked': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ノンブロッキング: 失敗しても本人確認の送信は続行
      Logger.warning('プロフィール写真設定に失敗', tag: 'IdentityVerification', data: {'error': '$e'});
    }
  }

  /// 顔照合失敗ダイアログ
  void _showFaceMatchFailedDialog(double score) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.identityVerification_faceMatchFailedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: context.appColors.warning),
            const SizedBox(height: 12),
            Text(
              context.l10n.identityVerification_faceMatchFailedMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.identityVerification_faceMatchScoreLabel(score.toStringAsFixed(0)),
              style: TextStyle(
                fontSize: 13,
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: Text(context.l10n.common_close),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ctx.pop();
              // 写真をリセットして再撮影を促す
              setState(() {
                _selfieUrl = null;
                _selfieBytes = null;
                _livenessVerified = false;
              });
            },
            icon: const Icon(Icons.camera_alt, size: 18),
            label: Text(context.l10n.identityVerification_retakePhoto),
          ),
        ],
      ),
    );
  }

  // --- UI構築 ---

  int get _currentStep {
    if (_idPhotoUrl == null && _idPhotoFrontBytes == null) return 0;
    if (_idPhotoBackUrl == null && _idPhotoBackBytes == null) return 1;
    if (!_livenessVerified || (_selfieUrl == null && _selfieBytes == null)) return 2;
    return 3;
  }

  Widget _buildStep(int number, String label, bool completed, bool isCurrent) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? context.appColors.success
                  : isCurrent
                      ? context.appColors.primary
                      : context.appColors.divider,
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
    Uint8List? localBytes,
    required VoidCallback onTap,
  }) {
    final hasImage = localBytes != null || photoUrl != null;

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
            border: Border.all(
              color: hasImage ? context.appColors.success : context.appColors.divider,
              width: hasImage ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              if (localBytes != null)
                // ローカルバイトがある場合はImage.memoryで即座に表示
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    localBytes,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    cacheWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
                  ),
                )
              else if (photoUrl != null)
                // URLあり・バイト未ダウンロード → ローディング表示
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.appColors.chipUnselected,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
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
                  if (hasImage)
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

  Widget _buildLivenessCard() {
    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _uploading ? null : _startLivenessDetection,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _livenessVerified ? context.appColors.success : context.appColors.divider,
              width: _livenessVerified ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _livenessVerified
                      ? context.appColors.success.withValues(alpha: 0.1)
                      : context.appColors.primaryPale,
                ),
                child: Icon(
                  _livenessVerified ? Icons.check_circle : Icons.face_retouching_natural,
                  color: _livenessVerified ? context.appColors.success : context.appColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.liveness_title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _livenessVerified
                          ? context.l10n.liveness_completed
                          : context.l10n.identityVerification_livenessSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _livenessVerified
                            ? context.appColors.success
                            : context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_livenessVerified)
                Icon(Icons.arrow_forward_ios, size: 16, color: context.appColors.textHint),
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
    final isEditable = !isApproved && !isPending;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.identityVerification_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // 4ステップインジケーター
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                _buildStep(1, context.l10n.identityVerification_stepIdFront, _idPhotoUrl != null || _idPhotoFrontBytes != null, _currentStep == 0),
                _buildStepConnector(_idPhotoUrl != null || _idPhotoFrontBytes != null),
                _buildStep(2, context.l10n.identityVerification_stepIdBack, _idPhotoBackUrl != null || _idPhotoBackBytes != null, _currentStep == 1),
                _buildStepConnector(_idPhotoBackUrl != null || _idPhotoBackBytes != null),
                _buildStep(3, context.l10n.identityVerification_stepLiveness, _livenessVerified && (_selfieUrl != null || _selfieBytes != null), _currentStep == 2),
                _buildStepConnector(_livenessVerified && (_selfieUrl != null || _selfieBytes != null)),
                _buildStep(4, context.l10n.identityVerification_stepSubmit, isPending || isApproved, _currentStep == 3),
              ],
            ),
          ),
          _buildStatusBanner(),
          // 説明バナー
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
          // eKYC バナー
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
          // 書類の種類選択
          if (isEditable)
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
                  if (value != null) setState(() => _documentType = value);
                },
              ),
            ),
          // 身分証表面
          _buildPhotoUploadCard(
            title: context.l10n.identityVerification_idDocumentTitle,
            subtitle: context.l10n.identityVerification_idDocumentSubtitle,
            icon: Icons.credit_card,
            photoUrl: _idPhotoUrl,
            localBytes: _idPhotoFrontBytes,
            onTap: isEditable
                ? () => _showPickerSheet(side: 'front', folder: 'identity_verification', documentId: 'id_front')
                : () {},
          ),
          const SizedBox(height: 16),
          // 身分証裏面
          _buildPhotoUploadCard(
            title: context.l10n.identityVerification_idDocumentBack,
            subtitle: context.l10n.identityVerification_idDocumentBackSubtitle,
            icon: Icons.credit_card,
            photoUrl: _idPhotoBackUrl,
            localBytes: _idPhotoBackBytes,
            onTap: isEditable
                ? () => _showPickerSheet(side: 'back', folder: 'identity_verification', documentId: 'id_back')
                : () {},
          ),
          const SizedBox(height: 16),
          // Liveness Detection
          _buildLivenessCard(),
          if (_selfieUrl != null || _selfieBytes != null) ...[
            const SizedBox(height: 12),
            // 自撮りプレビュー
            _buildPhotoUploadCard(
              title: context.l10n.identityVerification_selfieTitle,
              subtitle: context.l10n.identityVerification_selfieSubtitle,
              icon: Icons.face,
              photoUrl: _selfieUrl,
              localBytes: _selfieBytes,
              onTap: () {}, // Livenessで自動撮影のため手動選択不可
            ),
          ],
          const SizedBox(height: 24),
          // ローディング表示
          if (_uploading)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  if (_loadingMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _loadingMessage!,
                      style: TextStyle(fontSize: 13, color: context.appColors.textSecondary),
                    ),
                  ],
                ],
              ),
            )
          // 送信ボタン
          else if (isEditable)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_idPhotoUrl != null && _selfieUrl != null && _livenessVerified)
                    ? _submitWithFaceMatch
                    : null,
                icon: const Icon(Icons.verified_user),
                label: Text(
                  context.l10n.identityVerification_submitWithFaceMatch,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          // 再申請ボタン
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
                      _idPhotoBackUrl = null;
                      _selfieUrl = null;
                      _idPhotoFrontBytes = null;
                      _idPhotoBackBytes = null;
                      _selfieBytes = null;
                      _rejectionReason = null;
                      _documentType = 'drivers_license';
                      _livenessVerified = false;
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
