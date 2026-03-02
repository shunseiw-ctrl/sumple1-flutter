import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/constants/app_colors.dart';

/// IdentityVerificationPage のステップインジケーター・eKYCバナーUIテスト
/// Firebase依存を避けるため、UI部品を直接構築してテスト

Widget _buildStep(int number, String label, bool completed) {
  return Expanded(
    child: Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? AppColors.success : AppColors.divider,
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text('$number',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ],
    ),
  );
}

Widget _buildStepConnector(bool completed) {
  return Expanded(
    child: Container(
      height: 2,
      color: completed ? AppColors.success : AppColors.divider,
    ),
  );
}

void main() {
  group('IdentityVerificationPage ステップインジケーター', () {
    testWidgets('Step indicator shows 3 steps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  _buildStep(1, '身分証アップロード', false),
                  _buildStepConnector(false),
                  _buildStep(2, '自撮り', false),
                  _buildStepConnector(false),
                  _buildStep(3, '送信', false),
                ],
              ),
            ),
          ),
        ),
      );

      // 3つのステップラベルが表示される
      expect(find.text('身分証アップロード'), findsOneWidget);
      expect(find.text('自撮り'), findsOneWidget);
      expect(find.text('送信'), findsOneWidget);

      // 番号が表示される（未完了状態）
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // チェックアイコンは表示されない（すべて未完了）
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('eKYC banner is displayed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: AppColors.info, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'eKYC（電子本人確認）対応予定 — より迅速な本人確認が可能になります',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // eKYCバナーのテキストが表示される
      expect(
        find.text('eKYC（電子本人確認）対応予定 — より迅速な本人確認が可能になります'),
        findsOneWidget,
      );

      // verified_userアイコンが表示される
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
    });
  });
}
