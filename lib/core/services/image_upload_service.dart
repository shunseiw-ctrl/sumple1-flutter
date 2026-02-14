import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../utils/logger.dart';

/// 画像アップロード機能を管理
class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// ギャラリーから画像を選択してアップロード
  Future<ImageUploadResult> pickAndUploadImage({
    required String userId,
    required String folder, // 'jobs' or 'messages'
    required String documentId,
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
    bool compress = true,
  }) async {
    try {
      // 画像を選択
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (pickedFile == null) {
        Logger.info('Image selection cancelled', tag: 'ImageUploadService');
        return ImageUploadResult.cancelled();
      }

      Logger.info(
        'Image selected',
        tag: 'ImageUploadService',
        data: {
          'path': pickedFile.path,
          'name': pickedFile.name,
        },
      );

      // アップロード
      return await uploadImageFile(
        file: File(pickedFile.path),
        userId: userId,
        folder: folder,
        documentId: documentId,
        compress: compress,
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to pick and upload image',
        tag: 'ImageUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      return ImageUploadResult.error('画像の選択に失敗しました');
    }
  }

  /// カメラで撮影してアップロード
  Future<ImageUploadResult> captureAndUploadImage({
    required String userId,
    required String folder,
    required String documentId,
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
    bool compress = true,
  }) async {
    try {
      // カメラで撮影
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (pickedFile == null) {
        Logger.info('Camera capture cancelled', tag: 'ImageUploadService');
        return ImageUploadResult.cancelled();
      }

      Logger.info(
        'Image captured',
        tag: 'ImageUploadService',
        data: {
          'path': pickedFile.path,
          'name': pickedFile.name,
        },
      );

      // アップロード
      return await uploadImageFile(
        file: File(pickedFile.path),
        userId: userId,
        folder: folder,
        documentId: documentId,
        compress: compress,
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to capture and upload image',
        tag: 'ImageUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      return ImageUploadResult.error('写真の撮影に失敗しました');
    }
  }

  /// 複数の画像を選択してアップロード
  Future<List<ImageUploadResult>> pickAndUploadMultipleImages({
    required String userId,
    required String folder,
    required String documentId,
    int maxImages = 5,
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
    bool compress = true,
  }) async {
    try {
      // 複数画像を選択
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (pickedFiles.isEmpty) {
        Logger.info('Image selection cancelled', tag: 'ImageUploadService');
        return [];
      }

      // 最大数を超える場合は制限
      final filesToUpload = pickedFiles.take(maxImages).toList();

      Logger.info(
        'Multiple images selected',
        tag: 'ImageUploadService',
        data: {'count': filesToUpload.length},
      );

      // 並列でアップロード
      final results = <ImageUploadResult>[];
      for (int i = 0; i < filesToUpload.length; i++) {
        final result = await uploadImageFile(
          file: File(filesToUpload[i].path),
          userId: userId,
          folder: folder,
          documentId: '$documentId\_$i',
          compress: compress,
        );
        results.add(result);
      }

      return results;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to pick and upload multiple images',
        tag: 'ImageUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      return [ImageUploadResult.error('画像の選択に失敗しました')];
    }
  }

  /// 画像ファイルをアップロード
  Future<ImageUploadResult> uploadImageFile({
    required File file,
    required String userId,
    required String folder,
    required String documentId,
    bool compress = true,
  }) async {
    try {
      // 圧縮
      File fileToUpload = file;
      if (compress) {
        fileToUpload = await _compressImage(file);
      }

      // ファイル名を生成
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$documentId\_$timestamp.jpg';

      // Storage パスを生成
      final path = '$folder/$userId/$fileName';

      Logger.info(
        'Uploading image',
        tag: 'ImageUploadService',
        data: {'path': path},
      );

      // アップロード
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(fileToUpload);

      // 進捗監視
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
        Logger.debug(
          'Upload progress',
          tag: 'ImageUploadService',
          data: {'progress': progress.toStringAsFixed(2)},
        );
      });

      // 完了を待つ
      await uploadTask;

      // URLを取得
      final downloadUrl = await ref.getDownloadURL();

      Logger.info(
        'Image uploaded successfully',
        tag: 'ImageUploadService',
        data: {'url': downloadUrl},
      );

      return ImageUploadResult.success(downloadUrl);
    } on FirebaseException catch (e) {
      Logger.error(
        'Firebase error during image upload',
        tag: 'ImageUploadService',
        error: e,
        data: {'code': e.code, 'message': e.message},
      );
      return ImageUploadResult.error(_getFirebaseErrorMessage(e));
    } catch (e, stackTrace) {
      Logger.error(
        'Unexpected error during image upload',
        tag: 'ImageUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      return ImageUploadResult.error('画像のアップロードに失敗しました');
    }
  }

  /// 画像を圧縮
  Future<File> _compressImage(File file) async {
    try {
      Logger.debug('Compressing image', tag: 'ImageUploadService');

      // 画像を読み込み
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        Logger.warning('Failed to decode image', tag: 'ImageUploadService');
        return file;
      }

      // リサイズ（長辺を1920pxに）
      img.Image resized;
      if (image.width > image.height) {
        resized = img.copyResize(image, width: 1920);
      } else {
        resized = img.copyResize(image, height: 1920);
      }

      // JPEG形式で圧縮
      final compressed = img.encodeJpg(resized, quality: 85);

      // 一時ファイルに保存
      final tempPath = '${file.path}_compressed.jpg';
      final compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressed);

      final originalSize = await file.length();
      final compressedSize = await compressedFile.length();

      Logger.info(
        'Image compressed',
        tag: 'ImageUploadService',
        data: {
          'original': '${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB',
          'compressed': '${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB',
          'ratio': '${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}% reduction',
        },
      );

      return compressedFile;
    } catch (e) {
      Logger.warning(
        'Image compression failed, using original',
        tag: 'ImageUploadService',
        data: {'error': e.toString()},
      );
      return file;
    }
  }

  /// 画像を削除
  Future<bool> deleteImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();

      Logger.info(
        'Image deleted',
        tag: 'ImageUploadService',
        data: {'url': downloadUrl},
      );

      return true;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to delete image',
        tag: 'ImageUploadService',
        error: e,
        stackTrace: stackTrace,
        data: {'url': downloadUrl},
      );
      return false;
    }
  }

  /// Firebaseエラーメッセージを取得
  String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
        return '権限がありません';
      case 'canceled':
        return 'アップロードがキャンセルされました';
      case 'unknown':
        return 'アップロード中にエラーが発生しました';
      default:
        return 'エラーが発生しました: ${e.code}';
    }
  }
}

/// 画像アップロード結果
class ImageUploadResult {
  final bool success;
  final String? downloadUrl;
  final String? errorMessage;
  final bool cancelled;

  ImageUploadResult._({
    required this.success,
    this.downloadUrl,
    this.errorMessage,
    this.cancelled = false,
  });

  factory ImageUploadResult.success(String downloadUrl) {
    return ImageUploadResult._(
      success: true,
      downloadUrl: downloadUrl,
    );
  }

  factory ImageUploadResult.error(String message) {
    return ImageUploadResult._(
      success: false,
      errorMessage: message,
    );
  }

  factory ImageUploadResult.cancelled() {
    return ImageUploadResult._(
      success: false,
      cancelled: true,
    );
  }
}
