import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../utils/logger.dart';

class ImageUploadService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  ImageUploadService({FirebaseStorage? storage, ImagePicker? picker})
      : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  Future<ImageUploadResult> pickAndUploadImage({
    required String userId,
    required String folder,
    required String documentId,
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 85,
    bool compress = true,
  }) async {
    try {
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
        data: {'name': pickedFile.name},
      );

      final bytes = await pickedFile.readAsBytes();
      return await uploadImageBytes(
        bytes: bytes,
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
      if (kIsWeb) {
        return ImageUploadResult.error('Web版ではカメラ撮影は利用できません。ギャラリーから選択してください');
      }

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
        data: {'name': pickedFile.name},
      );

      final bytes = await pickedFile.readAsBytes();
      return await uploadImageBytes(
        bytes: bytes,
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
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (pickedFiles.isEmpty) {
        Logger.info('Image selection cancelled', tag: 'ImageUploadService');
        return [];
      }

      final filesToUpload = pickedFiles.take(maxImages).toList();

      Logger.info(
        'Multiple images selected',
        tag: 'ImageUploadService',
        data: {'count': filesToUpload.length},
      );

      final results = <ImageUploadResult>[];
      for (int i = 0; i < filesToUpload.length; i++) {
        final bytes = await filesToUpload[i].readAsBytes();
        final result = await uploadImageBytes(
          bytes: bytes,
          userId: userId,
          folder: folder,
          documentId: '${documentId}_$i',
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

  Future<ImageUploadResult> uploadImageBytes({
    required Uint8List bytes,
    required String userId,
    required String folder,
    required String documentId,
    bool compress = true,
  }) async {
    try {
      Uint8List dataToUpload = bytes;
      if (compress) {
        dataToUpload = _compressImageBytes(bytes);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${documentId}_$timestamp.jpg';
      final path = '$folder/$userId/$fileName';

      Logger.info(
        'Uploading image',
        tag: 'ImageUploadService',
        data: {'path': path, 'size': '${(dataToUpload.length / 1024).toStringAsFixed(1)} KB'},
      );

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putData(dataToUpload, metadata);

      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
          Logger.debug(
            'Upload progress',
            tag: 'ImageUploadService',
            data: {'progress': progress.toStringAsFixed(1)},
          );
        }
      });

      await uploadTask;

      final downloadUrl = await ref.getDownloadURL();

      Logger.info(
        'Image uploaded successfully',
        tag: 'ImageUploadService',
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

  Uint8List _compressImageBytes(Uint8List bytes) {
    try {
      Logger.debug('Compressing image', tag: 'ImageUploadService');

      final image = img.decodeImage(bytes);

      if (image == null) {
        Logger.warning('Failed to decode image, using original', tag: 'ImageUploadService');
        return bytes;
      }

      img.Image resized;
      if (image.width > 1920 || image.height > 1920) {
        if (image.width > image.height) {
          resized = img.copyResize(image, width: 1920);
        } else {
          resized = img.copyResize(image, height: 1920);
        }
      } else {
        resized = image;
      }

      final compressed = Uint8List.fromList(img.encodeJpg(resized, quality: 85));

      Logger.info(
        'Image compressed',
        tag: 'ImageUploadService',
        data: {
          'original': '${(bytes.length / 1024).toStringAsFixed(1)} KB',
          'compressed': '${(compressed.length / 1024).toStringAsFixed(1)} KB',
        },
      );

      return compressed;
    } catch (e) {
      Logger.warning(
        'Image compression failed, using original',
        tag: 'ImageUploadService',
        data: {'error': e.toString()},
      );
      return bytes;
    }
  }

  Future<bool> deleteImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();

      Logger.info(
        'Image deleted',
        tag: 'ImageUploadService',
      );

      return true;
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to delete image',
        tag: 'ImageUploadService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

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

class ImageUploadResult {
  final bool isSuccess;
  final String? downloadUrl;
  final String? errorMessage;
  final bool cancelled;

  ImageUploadResult._({
    required this.isSuccess,
    this.downloadUrl,
    this.errorMessage,
    this.cancelled = false,
  });

  bool get success => isSuccess;

  factory ImageUploadResult.success(String downloadUrl) {
    return ImageUploadResult._(
      isSuccess: true,
      downloadUrl: downloadUrl,
    );
  }

  factory ImageUploadResult.error(String message) {
    return ImageUploadResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  factory ImageUploadResult.cancelled() {
    return ImageUploadResult._(
      isSuccess: false,
      cancelled: true,
    );
  }
}
