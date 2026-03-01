import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_constants.dart';

void main() {
  group('AppConstants prefectures', () {
    test('contains expected values', () {
      expect(AppConstants.prefectures, contains('千葉県'));
      expect(AppConstants.prefectures, contains('東京都'));
      expect(AppConstants.prefectures, contains('神奈川県'));
      expect(AppConstants.prefectures, contains('その他'));
    });

    test('has correct length', () {
      expect(AppConstants.prefectures.length, 4);
    });
  });

  group('AppConstants excludedPrefectures', () {
    test('contains expected values', () {
      expect(AppConstants.excludedPrefectures, contains('千葉県'));
      expect(AppConstants.excludedPrefectures, contains('東京都'));
      expect(AppConstants.excludedPrefectures, contains('神奈川県'));
    });

    test('does not contain その他', () {
      expect(AppConstants.excludedPrefectures.contains('その他'), isFalse);
    });

    test('has correct length', () {
      expect(AppConstants.excludedPrefectures.length, 3);
    });
  });

  group('AppConstants app info', () {
    test('appName is ALBAWORK', () {
      expect(AppConstants.appName, 'ALBAWORK');
    });

    test('appVersion is 1.0.0', () {
      expect(AppConstants.appVersion, '1.0.0');
    });
  });

  group('AppConstants collection names', () {
    test('collectionJobs is jobs', () {
      expect(AppConstants.collectionJobs, 'jobs');
    });

    test('collectionApplications is applications', () {
      expect(AppConstants.collectionApplications, 'applications');
    });

    test('collectionChats is chats', () {
      expect(AppConstants.collectionChats, 'chats');
    });

    test('collectionProfiles is profiles', () {
      expect(AppConstants.collectionProfiles, 'profiles');
    });

    test('collectionConfig is config', () {
      expect(AppConstants.collectionConfig, 'config');
    });
  });

  group('AppConstants validation limits', () {
    test('maxMessageLength is 5000', () {
      expect(AppConstants.maxMessageLength, 5000);
    });

    test('maxJobTitleLength is 100', () {
      expect(AppConstants.maxJobTitleLength, 100);
    });

    test('maxJobLocationLength is 200', () {
      expect(AppConstants.maxJobLocationLength, 200);
    });

    test('maxJobDescriptionLength is 5000', () {
      expect(AppConstants.maxJobDescriptionLength, 5000);
    });

    test('maxJobNotesLength is 2000', () {
      expect(AppConstants.maxJobNotesLength, 2000);
    });

    test('maxDisplayNameLength is 50', () {
      expect(AppConstants.maxDisplayNameLength, 50);
    });

    test('maxIntroductionLength is 2000', () {
      expect(AppConstants.maxIntroductionLength, 2000);
    });

    test('maxExperienceYearsLength is 3', () {
      expect(AppConstants.maxExperienceYearsLength, 3);
    });

    test('maxAddressLength is 200', () {
      expect(AppConstants.maxAddressLength, 200);
    });

    test('maxQualificationLength is 50', () {
      expect(AppConstants.maxQualificationLength, 50);
    });

    test('maxContactSubjectLength is 200', () {
      expect(AppConstants.maxContactSubjectLength, 200);
    });

    test('maxContactBodyLength is 5000', () {
      expect(AppConstants.maxContactBodyLength, 5000);
    });

    test('postalCodePattern matches valid postal codes', () {
      final regex = RegExp(AppConstants.postalCodePattern);
      expect(regex.hasMatch('123-4567'), isTrue);
      expect(regex.hasMatch('1234567'), isTrue);
      expect(regex.hasMatch('12-4567'), isFalse);
      expect(regex.hasMatch('abc-defg'), isFalse);
    });
  });

  group('AppConstants other values', () {
    test('adminConfigPath is config/admins', () {
      expect(AppConstants.adminConfigPath, 'config/admins');
    });

    test('defaultListLimit is 50', () {
      expect(AppConstants.defaultListLimit, 50);
    });

    test('maxUnreadDisplay is 99', () {
      expect(AppConstants.maxUnreadDisplay, 99);
    });

    test('minTapSize is 44.0', () {
      expect(AppConstants.minTapSize, 44.0);
    });

    test('defaultPadding is 16.0', () {
      expect(AppConstants.defaultPadding, 16.0);
    });

    test('defaultBorderRadius is 12.0', () {
      expect(AppConstants.defaultBorderRadius, 12.0);
    });
  });
}
