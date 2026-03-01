import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LegalPage extends StatefulWidget {
  final String title;
  final String htmlContent;

  const LegalPage({super.key, required this.title, required this.htmlContent});

  /// プライバシーポリシー
  static const privacyPolicyHtml = '''
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 16px; line-height: 1.8; color: #333; font-size: 15px; }
  h1 { color: #1a237e; font-size: 20px; border-bottom: 2px solid #1a237e; padding-bottom: 8px; }
  h2 { color: #283593; font-size: 17px; margin-top: 24px; }
  ul { padding-left: 20px; }
  li { margin: 4px 0; }
  .updated { color: #666; font-size: 13px; }
</style>
</head>
<body>
<h1>プライバシーポリシー</h1>
<p class="updated">最終更新日: 2026年2月28日</p>

<h2>1. はじめに</h2>
<p>ALBAWORK（以下「当サービス」）は、ユーザーの個人情報の保護を重要視しています。本プライバシーポリシーは、当サービスがどのように個人情報を収集、使用、保護するかについて説明します。</p>

<h2>2. 収集する情報</h2>
<ul>
<li>氏名、メールアドレス、電話番号</li>
<li>生年月日、住所</li>
<li>本人確認書類の画像</li>
<li>プロフィール写真</li>
<li>位置情報（出退勤記録時のみ、ユーザーの同意のもと）</li>
<li>決済関連情報（Stripeを通じて処理）</li>
<li>端末情報（プッシュ通知トークン）</li>
</ul>

<h2>3. 情報の利用目的</h2>
<ul>
<li>サービスの提供および改善</li>
<li>求人マッチングの実施</li>
<li>出退勤管理（GPS検証を含む）</li>
<li>報酬の支払い処理</li>
<li>本人確認</li>
<li>お知らせやサービスに関する通知</li>
</ul>

<h2>4. 情報の共有</h2>
<p>当サービスは、以下の場合を除き、ユーザーの個人情報を第三者に提供しません：</p>
<ul>
<li>ユーザーの同意がある場合</li>
<li>法令に基づく場合</li>
<li>サービス提供に必要な業務委託先への提供（Stripe等の決済処理）</li>
</ul>

<h2>5. 情報の保護</h2>
<p>当サービスは、適切な技術的・組織的措置を講じて、個人情報の安全管理に努めます。</p>

<h2>6. 位置情報について</h2>
<p>当サービスでは、QR出退勤機能において位置情報を使用します。位置情報は出退勤の記録時にのみ取得され、バックグラウンドでの継続的な追跡は行いません。</p>

<h2>7. お問い合わせ</h2>
<p>プライバシーポリシーに関するお問い合わせは、アプリ内のお問い合わせフォームよりご連絡ください。</p>

<h2>8. 改定</h2>
<p>本ポリシーは、必要に応じて改定することがあります。重要な変更がある場合は、アプリ内で通知します。</p>
</body>
</html>
''';

  /// 利用規約
  static const termsHtml = '''
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 16px; line-height: 1.8; color: #333; font-size: 15px; }
  h1 { color: #1a237e; font-size: 20px; border-bottom: 2px solid #1a237e; padding-bottom: 8px; }
  h2 { color: #283593; font-size: 17px; margin-top: 24px; }
  ul { padding-left: 20px; }
  li { margin: 4px 0; }
  .updated { color: #666; font-size: 13px; }
</style>
</head>
<body>
<h1>利用規約</h1>
<p class="updated">最終更新日: 2026年2月28日</p>

<h2>第1条（適用）</h2>
<p>本規約は、ALBAWORK（以下「当サービス」）の利用に関する条件を定めるものです。ユーザーは本規約に同意の上、当サービスを利用するものとします。</p>

<h2>第2条（定義）</h2>
<ul>
<li>「ユーザー」とは、当サービスを利用する全ての方を指します。</li>
<li>「管理者」とは、求人を掲載する事業者または個人を指します。</li>
<li>「職人」とは、求人に応募し作業を行う方を指します。</li>
</ul>

<h2>第3条（アカウント）</h2>
<p>ユーザーは、正確な情報を登録する義務を負います。アカウント情報の管理はユーザーの責任とし、第三者への貸与・譲渡を禁止します。</p>

<h2>第4条（サービス内容）</h2>
<p>当サービスは、建設業界における求人マッチングプラットフォームです。</p>
<ul>
<li>求人情報の掲載・閲覧</li>
<li>応募・マッチング</li>
<li>チャットによるコミュニケーション</li>
<li>QR + GPS による出退勤管理</li>
<li>Stripe Connect を利用した報酬支払い</li>
<li>評価システム</li>
</ul>

<h2>第5条（決済・手数料）</h2>
<p>当サービスでは、Stripe Connect を利用して決済を処理します。プラットフォーム手数料は決済金額に対して所定の割合で発生します。</p>

<h2>第6条（出退勤管理）</h2>
<p>出退勤管理機能は、QRコードスキャンとGPS位置情報の二重認証により行います。</p>

<h2>第7条（禁止事項）</h2>
<ul>
<li>虚偽の情報の登録</li>
<li>他のユーザーへの嫌がらせ・誹謗中傷</li>
<li>サービスの不正利用（位置情報の偽装等）</li>
<li>法令に違反する行為</li>
<li>当サービスの運営を妨害する行為</li>
</ul>

<h2>第8条（免責事項）</h2>
<p>当サービスは、ユーザー間のトラブルについて一切の責任を負いません。</p>

<h2>第9条（規約の変更）</h2>
<p>当サービスは、必要に応じて本規約を変更することがあります。</p>

<h2>第10条（準拠法・管轄裁判所）</h2>
<p>本規約の解釈は日本法に準拠します。紛争が生じた場合は、東京地方裁判所を第一審の専属的合意管轄裁判所とします。</p>
</body>
</html>
''';

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
