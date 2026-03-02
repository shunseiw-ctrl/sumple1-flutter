import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sumple1/core/services/analytics_service.dart';

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

  /// 労災保険について
  static const laborInsuranceHtml = '''
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
<h1>労災保険について</h1>
<p class="updated">最終更新日: 2026年3月1日</p>

<h2>1. ALBAWORKの位置づけ</h2>
<p>ALBAWORK（以下「当サービス」）は、建設業界における求人情報を提供するマッチングプラットフォームです。当サービスは、ユーザーと求人掲載企業との間の雇用関係の当事者ではなく、雇用主としての地位を有しません。</p>

<h2>2. 労働者災害補償保険法について</h2>
<p>労働者災害補償保険法（昭和22年法律第50号）に基づく労働者災害補償保険（労災保険）は、業務上の事由または通勤による労働者の負傷、疾病、障害、死亡等に対して保険給付を行う制度です。</p>

<h2>3. ユーザーと求人掲載企業間の直接契約</h2>
<p>当サービスを通じてマッチングが成立した場合、労働契約はユーザー（職人）と求人掲載企業との間で直接締結されます。当サービスは当該契約の当事者ではありません。</p>
<ul>
<li>雇用条件の決定は、ユーザーと求人掲載企業が直接行います。</li>
<li>労働時間、作業内容、報酬等の詳細は両者間の合意に基づきます。</li>
<li>労働契約に関する紛争は、両当事者間で解決するものとします。</li>
</ul>

<h2>4. 労災保険の適用と責任所在</h2>
<p>作業中の事故・怪我に関する労災保険の適用については、以下のとおりです。</p>
<ul>
<li>労災保険の加入義務は、労働者を使用する事業主（求人掲載企業）にあります。</li>
<li>求人掲載企業は、労働者を1人でも雇用する場合、労災保険に加入する義務があります（農林水産の一部事業を除く）。</li>
<li>作業中の事故・怪我が発生した場合の保険給付の責任は、雇用主である求人掲載企業が負います。</li>
<li>当サービスは、ユーザーの作業中に発生した事故・怪我について、労災保険に基づく補償義務を負いません。</li>
</ul>

<h2>5. ユーザーへの推奨事項</h2>
<ul>
<li>就業前に、求人掲載企業が労災保険に加入していることを確認してください。</li>
<li>作業中の安全管理について、求人掲載企業と十分に確認してください。</li>
<li>万が一事故が発生した場合は、速やかに求人掲載企業および関係機関に連絡してください。</li>
</ul>

<h2>6. 免責事項</h2>
<p>当サービスは、マッチングプラットフォームとしての情報提供を行うものであり、労災保険に関する法的助言を提供するものではありません。具体的な労災保険の適用については、所轄の労働基準監督署または社会保険労務士にご相談ください。</p>
</body>
</html>
''';

  /// 労働者派遣法について
  static const dispatchLawHtml = '''
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
<h1>労働者派遣法について</h1>
<p class="updated">最終更新日: 2026年3月1日</p>

<h2>1. 直接マッチングサービスの明示</h2>
<p>ALBAWORK（以下「当サービス」）は、求人情報を掲載する企業と仕事を探すユーザーとの直接マッチングを提供するプラットフォームです。当サービスは労働者派遣事業を行うものではなく、ユーザーを派遣労働者として他の事業者に派遣することは一切ありません。</p>
<ul>
<li>当サービスを通じた就業は、ユーザーと求人掲載企業との直接雇用契約に基づきます。</li>
<li>当サービスは、派遣元事業主としての地位を有しません。</li>
<li>当サービスは、ユーザーに対する指揮命令権を有しません。</li>
</ul>

<h2>2. 労働者派遣事業法について</h2>
<p>労働者派遣事業の適正な運営の確保及び派遣労働者の保護等に関する法律（昭和60年法律第88号、以下「労働者派遣法」）は、労働者派遣事業の適正な運営を確保し、派遣労働者の雇用の安定と福祉の増進を図ることを目的としています。</p>

<h2>3. 建設業務における派遣の禁止</h2>
<p>労働者派遣法第4条第1項により、建設業務（土木、建築その他工作物の建設、改造、保存、修理、変更、破壊もしくは解体の作業またはこれらの準備の作業に係る業務）への労働者派遣は禁止されています。</p>

<h2>4. 求人掲載企業の義務</h2>
<p>求人掲載企業が労働者派遣事業に関与する場合、以下の義務を負います。</p>
<ul>
<li>労働者派遣事業を行う場合は、厚生労働大臣の許可を受ける必要があります（労働者派遣法第5条）。</li>
<li>建設業務への労働者派遣は法律により禁止されているため、これに違反した場合は罰則の対象となります。</li>
<li>当サービスを利用して、実質的な労働者派遣を行うことは禁止します。</li>
</ul>

<h2>5. ユーザーへの注意事項</h2>
<ul>
<li>当サービスを通じてマッチングした場合、就業先企業と直接雇用契約を締結してください。</li>
<li>第三者を介した間接的な雇用形態が提案された場合は、当サービスまでご報告ください。</li>
<li>不明な点がある場合は、最寄りの労働局にご相談ください。</li>
</ul>

<h2>6. 違反行為への対応</h2>
<p>当サービスを利用して実質的な労働者派遣が行われていることが確認された場合、当該求人掲載企業のアカウントを停止し、関係機関に通報する場合があります。</p>
</body>
</html>
''';

  /// 職業安定法について
  static const employmentSecurityLawHtml = '''
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
<h1>職業安定法に基づく表示</h1>
<p class="updated">最終更新日: 2026年3月1日</p>

<h2>1. 募集情報等提供事業としての義務</h2>
<p>ALBAWORK（以下「当サービス」）は、職業安定法（昭和22年法律第141号）に定める「募集情報等提供事業」として、求人情報の提供を行っています。当サービスは、同法に基づき以下の義務を遵守します。</p>
<ul>
<li>求人情報の的確な表示に努めます（職業安定法第5条の4）。</li>
<li>求職者の個人情報を適正に管理します。</li>
<li>求人情報の正確性の確保に努め、虚偽の情報が掲載されないよう管理します。</li>
<li>労働条件等の明示が適正に行われるよう、求人掲載企業に対して指導を行います。</li>
</ul>

<h2>2. 職業安定法への参照</h2>
<p>職業安定法（昭和22年法律第141号）は、職業紹介、労働者の募集、労働者供給等について規定し、職業の安定を図ることを目的としています。当サービスは、同法の趣旨に従い、適正な求人情報の提供に努めます。</p>

<h2>3. 禁止行為</h2>
<p>当サービスにおいて、以下の行為を禁止します。</p>
<ul>
<li>虚偽の求人条件を掲載すること（職業安定法第65条第8号）。</li>
<li>実際の労働条件と異なる情報を提示して労働者を募集すること。</li>
<li>求職者から報酬を受けて職業紹介を行うこと（当サービスは職業紹介事業ではありません）。</li>
<li>労働者供給事業に該当する行為を行うこと（職業安定法第44条）。</li>
<li>求職者に対して、その意に反する求人への応募を強制すること。</li>
<li>年齢、性別、障害、国籍等を理由とした不当な差別的取扱いを行うこと。</li>
<li>法令に違反する労働条件での求人を掲載すること。</li>
</ul>

<h2>4. 求人掲載企業の義務</h2>
<ul>
<li>求人情報に記載する労働条件は、実際の条件と一致させてください。</li>
<li>労働基準法、最低賃金法その他の労働関係法令を遵守した条件で求人を掲載してください。</li>
<li>採用後に労働条件を変更する場合は、速やかに労働者に通知してください。</li>
</ul>

<h2>5. 当サービスの対応</h2>
<p>当サービスは、掲載された求人情報が法令に違反する疑いがある場合、以下の対応を行うことがあります。</p>
<ul>
<li>当該求人情報の掲載を停止または削除すること。</li>
<li>求人掲載企業に対して是正を求めること。</li>
<li>悪質な場合は、アカウントの停止および関係機関への通報を行うこと。</li>
</ul>

<h2>6. 相談窓口</h2>
<p>求人情報の内容に疑問がある場合や、法令違反の疑いがある求人を発見した場合は、当サービスのお問い合わせフォームまたは最寄りの公共職業安定所（ハローワーク）までご連絡ください。</p>
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
    AnalyticsService.logScreenView('legal');
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
