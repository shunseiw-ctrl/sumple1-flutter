import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumple1/core/services/chat_image_service.dart';
import 'package:sumple1/core/services/image_upload_service.dart';

class MockImagePicker extends Mock implements ImagePicker {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  group('ChatImageService', () {
    late MockImagePicker mockPicker;
    late MockFirebaseStorage mockStorage;

    setUp(() {
      mockPicker = MockImagePicker();
      mockStorage = MockFirebaseStorage();
    });

    test('DIコンストラクタ動作確認', () {
      final uploadService = ImageUploadService(
        storage: mockStorage,
        picker: mockPicker,
      );
      final chatImageService = ChatImageService(imageUploadService: uploadService);

      expect(chatImageService, isNotNull);
    });

    test('pickAndUpload: キャンセル→cancelled result', () async {
      when(() => mockPicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            imageQuality: any(named: 'imageQuality'),
          )).thenAnswer((_) async => null);

      final uploadService = ImageUploadService(
        storage: mockStorage,
        picker: mockPicker,
      );
      final chatImageService = ChatImageService(imageUploadService: uploadService);

      final result = await chatImageService.pickAndUpload(
        userId: 'user-001',
        applicationId: 'app-001',
      );

      expect(result.isSuccess, isFalse);
      expect(result.cancelled, isTrue);
    });

    test('captureAndUpload: キャンセル→cancelled result', () async {
      when(() => mockPicker.pickImage(
            source: ImageSource.camera,
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            imageQuality: any(named: 'imageQuality'),
          )).thenAnswer((_) async => null);

      final uploadService = ImageUploadService(
        storage: mockStorage,
        picker: mockPicker,
      );
      final chatImageService = ChatImageService(imageUploadService: uploadService);

      final result = await chatImageService.captureAndUpload(
        userId: 'user-001',
        applicationId: 'app-001',
      );

      expect(result.isSuccess, isFalse);
      expect(result.cancelled, isTrue);
    });
  });
}
