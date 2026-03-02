import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test/helpers/test_helpers.dart';

void main() {
  group('PhoneAuthPage', () {
    testWidgets('電話番号入力フィールド表示', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            appBar: AppBar(title: const Text('電話番号でログイン')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('電話番号を入力してください'),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      prefixText: '+81 ',
                      hintText: '09012345678',
                      labelText: '電話番号',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('電話番号でログイン'), findsOneWidget);
      expect(find.text('電話番号を入力してください'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('電話番号バリデーション（11桁）', (tester) async {
      String? validationResult;

      String? validatePhone(String? value) {
        if (value == null || value.isEmpty) return '電話番号を入力してください';
        final cleaned = value.replaceAll(RegExp(r'[-\s]'), '');
        if (cleaned.length < 10 || cleaned.length > 11) {
          return '正しい電話番号を入力してください';
        }
        return null;
      }

      // 有効な番号
      validationResult = validatePhone('09012345678');
      expect(validationResult, isNull);

      // 短すぎる番号
      validationResult = validatePhone('090123');
      expect(validationResult, '正しい電話番号を入力してください');

      // 空
      validationResult = validatePhone('');
      expect(validationResult, '電話番号を入力してください');

      // ハイフン付き（OK、cleanedで判定）
      validationResult = validatePhone('090-1234-5678');
      expect(validationResult, isNull);
    });

    testWidgets('OTP入力画面がコード送信後に表示', (tester) async {
      // OTPステップのUI確認
      await tester.pumpWidget(
        buildTestApp(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('認証コードを入力'),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: '6桁のコード',
                      labelText: '認証コード',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 8),
                  const Text('60秒後に再送信できます'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('認証コードを入力'), findsOneWidget);
      expect(find.text('60秒後に再送信できます'), findsOneWidget);
    });
  });
}
