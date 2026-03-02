import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';
import 'image_upload_service.dart';

/// プロフィール画像アップロードサービス
class ProfileImageService {
  final ImageUploadService _imageUploadService;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  ProfileImageService({
    ImageUploadService? imageUploadService,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _imageUploadService = imageUploadService ?? ImageUploadService(),
        _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// ギャラリーから選択してアバターをアップロード
  Future<ProfileImageResult> pickAndUploadAvatar() async {
    final user = _auth.currentUser;
    if (user == null) {
      return ProfileImageResult.error('認証が必要です');
    }
    if (user.isAnonymous) {
      return ProfileImageResult.error('匿名ユーザーはプロフィール画像を設定できません');
    }

    final locked = await _isPhotoLocked(user.uid);
    if (locked) {
      return ProfileImageResult.error('本人確認済みのプロフィール画像は変更できません');
    }

    final result = await _imageUploadService.pickAndUploadImage(
      userId: user.uid,
      folder: 'profile_images',
      documentId: 'avatar',
      maxWidth: 512,
      maxHeight: 512,
      quality: 85,
    );

    return _handleResult(user.uid, result);
  }

  /// カメラ撮影してアバターをアップロード
  Future<ProfileImageResult> captureAndUploadAvatar() async {
    final user = _auth.currentUser;
    if (user == null) {
      return ProfileImageResult.error('認証が必要です');
    }
    if (user.isAnonymous) {
      return ProfileImageResult.error('匿名ユーザーはプロフィール画像を設定できません');
    }

    final locked = await _isPhotoLocked(user.uid);
    if (locked) {
      return ProfileImageResult.error('本人確認済みのプロフィール画像は変更できません');
    }

    final result = await _imageUploadService.captureAndUploadImage(
      userId: user.uid,
      folder: 'profile_images',
      documentId: 'avatar',
      maxWidth: 512,
      maxHeight: 512,
      quality: 85,
    );

    return _handleResult(user.uid, result);
  }

  Future<bool> _isPhotoLocked(String uid) async {
    try {
      final doc = await _db.collection('profiles').doc(uid).get();
      return doc.data()?['profilePhotoLocked'] == true;
    } catch (e) {
      Logger.warning('Failed to check profilePhotoLocked',
          tag: 'ProfileImageService', data: {'error': e.toString()});
      return false;
    }
  }

  Future<ProfileImageResult> _handleResult(
      String uid, ImageUploadResult result) async {
    if (result.cancelled) {
      return ProfileImageResult.cancelled();
    }

    if (!result.isSuccess) {
      return ProfileImageResult.error(
          result.errorMessage ?? '画像のアップロードに失敗しました');
    }

    try {
      await _db.collection('profiles').doc(uid).set({
        'profilePhotoUrl': result.downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Logger.info('Profile photo updated',
          tag: 'ProfileImageService', data: {'uid': uid});

      return ProfileImageResult.success(result.downloadUrl!);
    } catch (e) {
      Logger.error('Failed to update profilePhotoUrl',
          tag: 'ProfileImageService', error: e);
      return ProfileImageResult.error('プロフィール画像の保存に失敗しました');
    }
  }
}

class ProfileImageResult {
  final bool isSuccess;
  final String? downloadUrl;
  final String? errorMessage;
  final bool isCancelled;

  ProfileImageResult._({
    required this.isSuccess,
    this.downloadUrl,
    this.errorMessage,
    this.isCancelled = false,
  });

  factory ProfileImageResult.success(String downloadUrl) {
    return ProfileImageResult._(isSuccess: true, downloadUrl: downloadUrl);
  }

  factory ProfileImageResult.error(String message) {
    return ProfileImageResult._(isSuccess: false, errorMessage: message);
  }

  factory ProfileImageResult.cancelled() {
    return ProfileImageResult._(isSuccess: false, isCancelled: true);
  }
}
