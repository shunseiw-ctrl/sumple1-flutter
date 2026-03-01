import '../constants/app_constants.dart';

class InputValidators {
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldNameは必須です';
    }
    return null;
  }

  static String? postalCode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(AppConstants.postalCodePattern);
    if (!regex.hasMatch(value.trim())) {
      return '正しい郵便番号を入力してください（例: 123-4567）';
    }
    return null;
  }

  static String? experienceYears(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return '正しい数値を入力してください';
    }
    return null;
  }

  static String? maxLengthValidator(String? value, int maxLength, String fieldName) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.length > maxLength) {
      return '$fieldNameは$maxLength文字以内で入力してください';
    }
    return null;
  }
}
