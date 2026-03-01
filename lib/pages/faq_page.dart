import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static const _faqItems = <Map<String, String>>[
    {
      'q': 'ALBAWORKとは何ですか？',
      'a': 'ALBAWORKは建設業界に特化した求人マッチングアプリです。管理者（事業者）が案件を掲載し、職人が応募・作業・報酬受取まで一貫して行えます。',
    },
    {
      'q': '利用料金はかかりますか？',
      'a': 'アプリの利用自体は無料です。決済時にプラットフォーム手数料が発生します。詳細は利用規約をご確認ください。',
    },
    {
      'q': '応募するにはどうすればいいですか？',
      'a': 'ホーム画面で案件を探し、「応募する」ボタンをタップしてください。応募にはログインが必要です。',
    },
    {
      'q': '出退勤はどのように記録しますか？',
      'a': '管理者が生成したQRコードをスキャンし、GPS位置情報で現場にいることを確認して出退勤を記録します。現場から100m以内にいる必要があります。',
    },
    {
      'q': '報酬はどのように受け取れますか？',
      'a': 'Stripe Connectを通じて報酬をお支払いします。マイページの「Stripe口座設定」から銀行口座を登録してください。',
    },
    {
      'q': '本人確認は必要ですか？',
      'a': '案件への応募や報酬受取には本人確認が推奨されます。マイページの「本人確認」から身分証明書を提出してください。',
    },
    {
      'q': '退会するにはどうすればいいですか？',
      'a': 'マイページの「アカウント設定」から退会手続きについてご確認いただけます。お問い合わせフォームからもご連絡いただけます。',
    },
    {
      'q': 'パスワードを忘れました',
      'a': 'ログイン画面から「パスワードを忘れた方」リンクをタップし、登録メールアドレスを入力してください。リセットメールが送信されます。',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('よくある質問', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqItems.length,
        itemBuilder: (context, i) {
          final item = _faqItems[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6E8EB)),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              shape: const Border(),
              leading: Icon(Icons.help_outline, color: AppColors.ruri, size: 20),
              title: Text(
                item['q']!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              children: [
                Text(
                  item['a']!,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
