import 'image_upload_service.dart';

/// チャット画像の選択・アップロード管理
class ChatImageService {
  final ImageUploadService _imageUploadService;

  ChatImageService({ImageUploadService? imageUploadService})
      : _imageUploadService = imageUploadService ?? ImageUploadService();

  /// ギャラリーから選択→アップロード
  Future<ImageUploadResult> pickAndUpload({
    required String userId,
    required String applicationId,
  }) async {
    return _imageUploadService.pickAndUploadImage(
      userId: userId,
      folder: 'chat_images',
      documentId: applicationId,
      maxWidth: 1920,
      maxHeight: 1080,
      quality: 80,
    );
  }

  /// カメラ撮影→アップロード
  Future<ImageUploadResult> captureAndUpload({
    required String userId,
    required String applicationId,
  }) async {
    return _imageUploadService.captureAndUploadImage(
      userId: userId,
      folder: 'chat_images',
      documentId: applicationId,
      maxWidth: 1920,
      maxHeight: 1080,
      quality: 80,
    );
  }
}
