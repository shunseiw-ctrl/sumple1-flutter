import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumple1/core/services/image_upload_service.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockImagePicker extends Mock implements ImagePicker {}

class MockReference extends Mock implements Reference {}

class MockUploadTask extends Mock implements UploadTask {}

class MockTaskSnapshot extends Mock implements TaskSnapshot {}

void main() {
  late MockFirebaseStorage mockStorage;
  late MockImagePicker mockPicker;
  late ImageUploadService service;

  setUp(() {
    mockStorage = MockFirebaseStorage();
    mockPicker = MockImagePicker();
    service = ImageUploadService(storage: mockStorage, picker: mockPicker);
  });

  group('ImageUploadService constructor', () {
    test('accepts DI parameters', () {
      expect(service, isNotNull);
    });
  });

  group('ImageUploadService.pickAndUploadImage', () {
    test('returns cancelled when no image selected', () async {
      when(() => mockPicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
      )).thenAnswer((_) async => null);

      final result = await service.pickAndUploadImage(
        userId: 'user1',
        folder: 'images',
        documentId: 'doc1',
      );

      expect(result.cancelled, isTrue);
      expect(result.isSuccess, isFalse);
    });
  });

  group('ImageUploadService.captureAndUploadImage', () {
    test('returns cancelled when no image captured', () async {
      when(() => mockPicker.pickImage(
        source: ImageSource.camera,
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
      )).thenAnswer((_) async => null);

      final result = await service.captureAndUploadImage(
        userId: 'user1',
        folder: 'images',
        documentId: 'doc1',
      );

      // On non-web, should return cancelled (on web, returns error)
      expect(result.isSuccess, isFalse);
    });
  });

  group('ImageUploadService.pickAndUploadMultipleImages', () {
    test('returns empty list when no images selected', () async {
      when(() => mockPicker.pickMultiImage(
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
      )).thenAnswer((_) async => []);

      final results = await service.pickAndUploadMultipleImages(
        userId: 'user1',
        folder: 'images',
        documentId: 'doc1',
      );

      expect(results, isEmpty);
    });
  });

  group('ImageUploadService.deleteImage', () {
    test('returns false on failure', () async {
      when(() => mockStorage.refFromURL(any())).thenThrow(Exception('not found'));

      final result = await service.deleteImage('https://example.com/image.jpg');
      expect(result, isFalse);
    });
  });

  group('ImageUploadResult', () {
    test('success factory creates success result', () {
      final result = ImageUploadResult.success('https://example.com/image.jpg');
      expect(result.isSuccess, isTrue);
      expect(result.success, isTrue);
      expect(result.downloadUrl, 'https://example.com/image.jpg');
      expect(result.cancelled, isFalse);
    });

    test('error factory creates error result', () {
      final result = ImageUploadResult.error('エラーが発生しました');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'エラーが発生しました');
      expect(result.cancelled, isFalse);
    });

    test('cancelled factory creates cancelled result', () {
      final result = ImageUploadResult.cancelled();
      expect(result.isSuccess, isFalse);
      expect(result.cancelled, isTrue);
    });
  });
}
