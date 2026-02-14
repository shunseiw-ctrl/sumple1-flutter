import 'package:flutter/material.dart';

import '../../core/services/image_upload_service.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';

/// 画像選択ダイアログ
class ImagePickerDialog {
  /// 画像選択方法を選択するダイアログを表示
  static Future<ImageUploadResult?> show(
    BuildContext context, {
    required String userId,
    required String folder,
    required String documentId,
    bool allowMultiple = false,
  }) async {
    return showModalBottomSheet<ImageUploadResult>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // タイトル
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    '画像を選択',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(),

                // カメラで撮影
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.blue),
                  ),
                  title: const Text('カメラで撮影'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _captureImage(
                      context,
                      userId: userId,
                      folder: folder,
                      documentId: documentId,
                    );
                  },
                ),

                // ギャラリーから選択
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.green),
                  ),
                  title: Text(allowMultiple ? 'ギャラリーから選択（複数可）' : 'ギャラリーから選択'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (allowMultiple) {
                      await _pickMultipleImages(
                        context,
                        userId: userId,
                        folder: folder,
                        documentId: documentId,
                      );
                    } else {
                      await _pickImage(
                        context,
                        userId: userId,
                        folder: folder,
                        documentId: documentId,
                      );
                    }
                  },
                ),

                // キャンセル
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// カメラで撮影
  static Future<void> _captureImage(
    BuildContext context, {
    required String userId,
    required String folder,
    required String documentId,
  }) async {
    if (!context.mounted) return;

    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final service = ImageUploadService();
    final result = await service.captureAndUploadImage(
      userId: userId,
      folder: folder,
      documentId: documentId,
    );

    if (!context.mounted) return;

    // ローディングを閉じる
    Navigator.pop(context);

    _handleResult(context, result);
  }

  /// ギャラリーから1枚選択
  static Future<void> _pickImage(
    BuildContext context, {
    required String userId,
    required String folder,
    required String documentId,
  }) async {
    if (!context.mounted) return;

    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final service = ImageUploadService();
    final result = await service.pickAndUploadImage(
      userId: userId,
      folder: folder,
      documentId: documentId,
    );

    if (!context.mounted) return;

    // ローディングを閉じる
    Navigator.pop(context);

    _handleResult(context, result);
  }

  /// ギャラリーから複数選択
  static Future<void> _pickMultipleImages(
    BuildContext context, {
    required String userId,
    required String folder,
    required String documentId,
  }) async {
    if (!context.mounted) return;

    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final service = ImageUploadService();
    final results = await service.pickAndUploadMultipleImages(
      userId: userId,
      folder: folder,
      documentId: documentId,
    );

    if (!context.mounted) return;

    // ローディングを閉じる
    Navigator.pop(context);

    if (results.isEmpty) {
      ErrorHandler.showInfo(context, '画像が選択されませんでした');
      return;
    }

    final successCount = results.where((r) => r.success).length;
    final failedCount = results.length - successCount;

    if (failedCount == 0) {
      ErrorHandler.showSuccess(context, '$successCount枚の画像をアップロードしました');
    } else {
      ErrorHandler.showError(
        context,
        '$successCount枚成功、$failedCount枚失敗しました',
      );
    }

    Logger.info(
      'Multiple images uploaded',
      tag: 'ImagePickerDialog',
      data: {'success': successCount, 'failed': failedCount},
    );
  }

  /// 結果を処理
  static void _handleResult(BuildContext context, ImageUploadResult result) {
    if (result.success) {
      ErrorHandler.showSuccess(context, '画像をアップロードしました');
      Logger.info(
        'Image uploaded',
        tag: 'ImagePickerDialog',
        data: {'url': result.downloadUrl},
      );
    } else if (result.cancelled) {
      // キャンセル時は何も表示しない
      Logger.info('Image selection cancelled', tag: 'ImagePickerDialog');
    } else {
      ErrorHandler.showError(context, result.errorMessage ?? 'エラーが発生しました');
    }
  }
}
