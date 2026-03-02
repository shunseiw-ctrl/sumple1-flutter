import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ja')];

  /// アプリ名
  ///
  /// In ja, this message translates to:
  /// **'ALBAWORK'**
  String get appName;

  /// BottomNavigation: ホーム
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get navHome;

  /// BottomNavigation: 仕事
  ///
  /// In ja, this message translates to:
  /// **'仕事'**
  String get navWork;

  /// BottomNavigation: メッセージ
  ///
  /// In ja, this message translates to:
  /// **'メッセージ'**
  String get navMessages;

  /// BottomNavigation: 売上
  ///
  /// In ja, this message translates to:
  /// **'売上'**
  String get navSales;

  /// BottomNavigation: プロフィール
  ///
  /// In ja, this message translates to:
  /// **'プロフィール'**
  String get navProfile;

  /// BottomNavigation: 検索
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get navSearch;

  /// BottomNavigation: マイページ
  ///
  /// In ja, this message translates to:
  /// **'マイページ'**
  String get navMyPage;

  /// 汎用キャンセルボタン
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// 汎用保存ボタン
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// 汎用削除ボタン
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// 汎用確認ボタン
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get confirm;

  /// 汎用閉じるボタン
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// 汎用送信ボタン
  ///
  /// In ja, this message translates to:
  /// **'送信'**
  String get send;

  /// 汎用編集ボタン
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get edit;

  /// 汎用更新ボタン
  ///
  /// In ja, this message translates to:
  /// **'更新'**
  String get update;

  /// 汎用戻るボタン
  ///
  /// In ja, this message translates to:
  /// **'戻る'**
  String get back;

  /// 汎用検索
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get search;

  /// 応募ボタン
  ///
  /// In ja, this message translates to:
  /// **'応募する'**
  String get apply;

  /// オンボーディング: スキップ
  ///
  /// In ja, this message translates to:
  /// **'スキップ'**
  String get skip;

  /// オンボーディング: 次へ
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get next;

  /// オンボーディング: 始める
  ///
  /// In ja, this message translates to:
  /// **'始める'**
  String get getStarted;

  /// エラー時のリトライボタン
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retry;

  /// ローディング表示
  ///
  /// In ja, this message translates to:
  /// **'読み込み中...'**
  String get loading;

  /// データなし表示
  ///
  /// In ja, this message translates to:
  /// **'データがありません'**
  String get noData;

  /// ログインボタン
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get login;

  /// ログアウトボタン
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get logout;

  /// 新規登録ボタン
  ///
  /// In ja, this message translates to:
  /// **'新規登録'**
  String get register;

  /// メールアドレスラベル
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get email;

  /// パスワードラベル
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get password;

  /// 表示名ラベル
  ///
  /// In ja, this message translates to:
  /// **'表示名'**
  String get displayName;

  /// Apple Sign In ボタン
  ///
  /// In ja, this message translates to:
  /// **'Appleでサインイン'**
  String get signInWithApple;

  /// LINE ログインボタン
  ///
  /// In ja, this message translates to:
  /// **'LINEでログイン'**
  String get signInWithLine;

  /// メールログインボタン
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスでログイン'**
  String get signInWithEmail;

  /// ゲストログインボタン
  ///
  /// In ja, this message translates to:
  /// **'ゲストとして始める'**
  String get startAsGuest;

  /// ゲストログイン成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'ゲストとしてログインしました'**
  String get guestLoginSuccess;

  /// Appleログイン成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'Appleでログインしました'**
  String get appleLoginSuccess;

  /// アプリのキャッチコピー
  ///
  /// In ja, this message translates to:
  /// **'建設業界の仕事マッチングアプリ'**
  String get appTagline;

  /// 特徴カード: 検索
  ///
  /// In ja, this message translates to:
  /// **'仕事を探す'**
  String get featureSearch;

  /// 特徴カード: 即収入
  ///
  /// In ja, this message translates to:
  /// **'すぐに稼げる'**
  String get featureQuickEarn;

  /// 特徴カード: 安全決済
  ///
  /// In ja, this message translates to:
  /// **'安心の支払い'**
  String get featureSecurePayment;

  /// 利用規約リンク
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get termsOfService;

  /// プライバシーポリシーリンク
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get privacyPolicy;

  /// ステータス: 応募済み
  ///
  /// In ja, this message translates to:
  /// **'応募中'**
  String get statusApplied;

  /// ステータス: 確定
  ///
  /// In ja, this message translates to:
  /// **'確定'**
  String get statusAssigned;

  /// ステータス: 完了
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get statusCompleted;

  /// ステータス: キャンセル
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get statusCancelled;

  /// ステータス: 審査中
  ///
  /// In ja, this message translates to:
  /// **'審査中'**
  String get statusPending;

  /// ステータス: 不採用
  ///
  /// In ja, this message translates to:
  /// **'不採用'**
  String get statusRejected;

  /// アカウント設定ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'アカウント設定'**
  String get accountSettings;

  /// アカウント削除ボタン
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除'**
  String get deleteAccount;

  /// データダウンロードボタン
  ///
  /// In ja, this message translates to:
  /// **'データをダウンロード'**
  String get downloadData;

  /// 利用規約同意チェック
  ///
  /// In ja, this message translates to:
  /// **'利用規約に同意する'**
  String get agreeToTerms;

  /// プライバシーポリシー同意チェック
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシーに同意する'**
  String get agreeToPrivacy;

  /// パスワード変更ボタン
  ///
  /// In ja, this message translates to:
  /// **'パスワードを変更'**
  String get changePassword;

  /// 汎用エラーメッセージ
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました'**
  String get errorGeneric;

  /// ネットワークエラーメッセージ
  ///
  /// In ja, this message translates to:
  /// **'ネットワークエラーが発生しました'**
  String get errorNetwork;

  /// ネットワークエラータイトル
  ///
  /// In ja, this message translates to:
  /// **'ネットワークエラー'**
  String get errorNetworkTitle;

  /// ネットワークエラー詳細メッセージ
  ///
  /// In ja, this message translates to:
  /// **'インターネット接続を確認して\nもう一度お試しください'**
  String get errorNetworkMessage;

  /// タイムアウトエラータイトル
  ///
  /// In ja, this message translates to:
  /// **'タイムアウト'**
  String get errorTimeout;

  /// タイムアウトエラー詳細メッセージ
  ///
  /// In ja, this message translates to:
  /// **'サーバーへの接続に時間がかかっています\nもう一度お試しください'**
  String get errorTimeoutMessage;

  /// 汎用エラー詳細メッセージ
  ///
  /// In ja, this message translates to:
  /// **'しばらく経ってからもう一度お試しください'**
  String get errorDefaultMessage;

  /// データ未検出タイトル
  ///
  /// In ja, this message translates to:
  /// **'データが見つかりません'**
  String get errorDataNotFound;

  /// 検索リトライメッセージ
  ///
  /// In ja, this message translates to:
  /// **'条件を変更して再検索してください'**
  String get errorSearchRetry;

  /// コンパクトエラーラベル
  ///
  /// In ja, this message translates to:
  /// **'エラー'**
  String get errorLabel;

  /// 管理者バッジ
  ///
  /// In ja, this message translates to:
  /// **'管理者'**
  String get adminBadge;

  /// お知らせタイトル
  ///
  /// In ja, this message translates to:
  /// **'お知らせ'**
  String get notifications;

  /// 案件投稿ボタン
  ///
  /// In ja, this message translates to:
  /// **'案件を投稿'**
  String get postJob;

  /// メール重複エラー
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは既に登録されています'**
  String get emailAlreadyInUse;

  /// パスワード不正エラー
  ///
  /// In ja, this message translates to:
  /// **'パスワードが正しくありません'**
  String get wrongPassword;

  /// アカウント未検出エラー
  ///
  /// In ja, this message translates to:
  /// **'アカウントが見つかりません'**
  String get userNotFound;

  /// メール形式エラー
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスの形式が正しくありません'**
  String get invalidEmail;

  /// アカウント無効エラー
  ///
  /// In ja, this message translates to:
  /// **'このアカウントは無効化されています'**
  String get userDisabled;

  /// リクエスト過多エラー
  ///
  /// In ja, this message translates to:
  /// **'リクエストが多すぎます。しばらくしてからお試しください'**
  String get tooManyRequests;

  /// 弱パスワードエラー
  ///
  /// In ja, this message translates to:
  /// **'パスワードが弱すぎます。6文字以上で設定してください'**
  String get weakPassword;

  /// ネットワーク確認メッセージ
  ///
  /// In ja, this message translates to:
  /// **'ネットワーク接続を確認してください'**
  String get networkCheckConnection;

  /// 認証エラー
  ///
  /// In ja, this message translates to:
  /// **'認証エラーが発生しました'**
  String get authError;

  /// ログイン成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'ログインしました'**
  String get loginSuccess;

  /// 登録成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'アカウントを作成しました'**
  String get registerSuccess;

  /// パスワードリセットメール送信
  ///
  /// In ja, this message translates to:
  /// **'パスワードリセットメールを送信しました'**
  String get passwordResetSent;

  /// パスワード忘れリンク
  ///
  /// In ja, this message translates to:
  /// **'パスワードを忘れた方'**
  String get forgotPassword;

  /// パスワードリセットタイトル
  ///
  /// In ja, this message translates to:
  /// **'パスワードリセット'**
  String get passwordResetTitle;

  /// パスワードリセット説明
  ///
  /// In ja, this message translates to:
  /// **'登録されたメールアドレスにリセットリンクを送信します'**
  String get passwordResetDescription;

  /// リセットリンク送信ボタン
  ///
  /// In ja, this message translates to:
  /// **'リセットリンクを送信'**
  String get sendResetLink;

  /// パスワード表示切替
  ///
  /// In ja, this message translates to:
  /// **'パスワードを表示'**
  String get showPassword;

  /// パスワード非表示切替
  ///
  /// In ja, this message translates to:
  /// **'パスワードを非表示'**
  String get hidePassword;

  /// 仕事一覧ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'仕事一覧'**
  String get jobListTitle;

  /// 案件詳細タイトル
  ///
  /// In ja, this message translates to:
  /// **'案件詳細'**
  String get jobDetail;

  /// 案件名ラベル
  ///
  /// In ja, this message translates to:
  /// **'案件名'**
  String get jobTitle;

  /// 勤務地ラベル
  ///
  /// In ja, this message translates to:
  /// **'勤務地'**
  String get jobLocation;

  /// 勤務日ラベル
  ///
  /// In ja, this message translates to:
  /// **'勤務日'**
  String get jobDate;

  /// 報酬ラベル
  ///
  /// In ja, this message translates to:
  /// **'報酬'**
  String get jobPrice;

  /// 仕事内容ラベル
  ///
  /// In ja, this message translates to:
  /// **'仕事内容'**
  String get jobDescription;

  /// 備考ラベル
  ///
  /// In ja, this message translates to:
  /// **'備考'**
  String get jobNotes;

  /// 概要ラベル
  ///
  /// In ja, this message translates to:
  /// **'概要'**
  String get jobOverview;

  /// 仕事なしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'条件に合う仕事が見つかりません'**
  String get noJobsFound;

  /// 仕事検索ヒント
  ///
  /// In ja, this message translates to:
  /// **'仕事を検索'**
  String get searchJobs;

  /// 都道府県フィルター
  ///
  /// In ja, this message translates to:
  /// **'都道府県で絞り込み'**
  String get filterByPrefecture;

  /// 全都道府県
  ///
  /// In ja, this message translates to:
  /// **'全国'**
  String get allPrefectures;

  /// 新着順ソート
  ///
  /// In ja, this message translates to:
  /// **'新着順'**
  String get sortByNewest;

  /// 報酬高い順ソート
  ///
  /// In ja, this message translates to:
  /// **'報酬が高い順'**
  String get sortByPriceHigh;

  /// 案件応募ボタン
  ///
  /// In ja, this message translates to:
  /// **'この案件に応募する'**
  String get applyForJob;

  /// 応募済み表示
  ///
  /// In ja, this message translates to:
  /// **'応募済み'**
  String get alreadyApplied;

  /// 応募成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'応募が完了しました'**
  String get applicationSuccess;

  /// 応募確認メッセージ
  ///
  /// In ja, this message translates to:
  /// **'この案件に応募しますか？'**
  String get applicationConfirm;

  /// ゲスト応募不可メッセージ
  ///
  /// In ja, this message translates to:
  /// **'ゲストは応募できません。ログインしてください'**
  String get guestCannotApply;

  /// はたらくページタイトル
  ///
  /// In ja, this message translates to:
  /// **'はたらく'**
  String get workTitle;

  /// 仕事詳細タイトル
  ///
  /// In ja, this message translates to:
  /// **'仕事詳細'**
  String get workDetail;

  /// 出勤ボタン
  ///
  /// In ja, this message translates to:
  /// **'出勤'**
  String get checkIn;

  /// 退勤ボタン
  ///
  /// In ja, this message translates to:
  /// **'退勤'**
  String get checkOut;

  /// 出勤済み表示
  ///
  /// In ja, this message translates to:
  /// **'出勤済み'**
  String get checkedIn;

  /// 退勤済み表示
  ///
  /// In ja, this message translates to:
  /// **'退勤済み'**
  String get checkedOut;

  /// 出勤成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'出勤しました'**
  String get checkInSuccess;

  /// 退勤成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'退勤しました'**
  String get checkOutSuccess;

  /// 仕事なしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'現在の仕事はありません'**
  String get noWork;

  /// 勤務状況ラベル
  ///
  /// In ja, this message translates to:
  /// **'勤務状況'**
  String get workStatus;

  /// プロジェクト名
  ///
  /// In ja, this message translates to:
  /// **'案件名'**
  String get projectName;

  /// マイページタイトル
  ///
  /// In ja, this message translates to:
  /// **'マイページ'**
  String get profileTitle;

  /// プロフィール編集
  ///
  /// In ja, this message translates to:
  /// **'プロフィール編集'**
  String get editProfile;

  /// マイプロフィール
  ///
  /// In ja, this message translates to:
  /// **'プロフィール'**
  String get myProfile;

  /// 氏名ラベル
  ///
  /// In ja, this message translates to:
  /// **'氏名'**
  String get name;

  /// 姓ラベル
  ///
  /// In ja, this message translates to:
  /// **'姓'**
  String get familyName;

  /// 名ラベル
  ///
  /// In ja, this message translates to:
  /// **'名'**
  String get givenName;

  /// 姓カナラベル
  ///
  /// In ja, this message translates to:
  /// **'姓（カナ）'**
  String get familyNameKana;

  /// 名カナラベル
  ///
  /// In ja, this message translates to:
  /// **'名（カナ）'**
  String get givenNameKana;

  /// 電話番号ラベル
  ///
  /// In ja, this message translates to:
  /// **'電話番号'**
  String get phone;

  /// 生年月日ラベル
  ///
  /// In ja, this message translates to:
  /// **'生年月日'**
  String get birthDate;

  /// 性別ラベル
  ///
  /// In ja, this message translates to:
  /// **'性別'**
  String get gender;

  /// 男性
  ///
  /// In ja, this message translates to:
  /// **'男性'**
  String get genderMale;

  /// 女性
  ///
  /// In ja, this message translates to:
  /// **'女性'**
  String get genderFemale;

  /// その他
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get genderOther;

  /// 郵便番号ラベル
  ///
  /// In ja, this message translates to:
  /// **'郵便番号'**
  String get postalCode;

  /// 住所ラベル
  ///
  /// In ja, this message translates to:
  /// **'住所'**
  String get address;

  /// 自己紹介ラベル
  ///
  /// In ja, this message translates to:
  /// **'自己紹介'**
  String get introduction;

  /// 経験年数ラベル
  ///
  /// In ja, this message translates to:
  /// **'経験年数'**
  String get experienceYears;

  /// 資格ラベル
  ///
  /// In ja, this message translates to:
  /// **'資格'**
  String get qualifications;

  /// プロフィール保存成功
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを保存しました'**
  String get profileSaved;

  /// プロフィール写真変更
  ///
  /// In ja, this message translates to:
  /// **'写真を変更'**
  String get profilePhotoChange;

  /// 管理者ログインタイトル
  ///
  /// In ja, this message translates to:
  /// **'管理者ログイン'**
  String get adminLogin;

  /// 管理者ログイン説明
  ///
  /// In ja, this message translates to:
  /// **'管理者パスワードを入力してください'**
  String get adminLoginDescription;

  /// 管理者パスワードラベル
  ///
  /// In ja, this message translates to:
  /// **'管理者パスワード'**
  String get adminPassword;

  /// 管理者ホームタイトル
  ///
  /// In ja, this message translates to:
  /// **'管理者ダッシュボード'**
  String get adminHome;

  /// 案件管理メニュー
  ///
  /// In ja, this message translates to:
  /// **'案件管理'**
  String get adminJobManagement;

  /// 応募管理メニュー
  ///
  /// In ja, this message translates to:
  /// **'応募管理'**
  String get adminApplications;

  /// 決済管理メニュー
  ///
  /// In ja, this message translates to:
  /// **'決済管理'**
  String get adminPayments;

  /// ユーザー管理メニュー
  ///
  /// In ja, this message translates to:
  /// **'ユーザー管理'**
  String get adminUsers;

  /// メッセージページタイトル
  ///
  /// In ja, this message translates to:
  /// **'メッセージ'**
  String get messagesTitle;

  /// メッセージなし
  ///
  /// In ja, this message translates to:
  /// **'メッセージはありません'**
  String get noMessages;

  /// メッセージ入力ヒント
  ///
  /// In ja, this message translates to:
  /// **'メッセージを入力'**
  String get typeMessage;

  /// 売上ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'売上'**
  String get salesTitle;

  /// 合計報酬ラベル
  ///
  /// In ja, this message translates to:
  /// **'合計報酬'**
  String get totalEarnings;

  /// 売上詳細タイトル
  ///
  /// In ja, this message translates to:
  /// **'売上詳細'**
  String get earningsDetail;

  /// 売上登録ボタン
  ///
  /// In ja, this message translates to:
  /// **'売上を登録'**
  String get createEarnings;

  /// 金額ラベル
  ///
  /// In ja, this message translates to:
  /// **'金額'**
  String get amount;

  /// 支払い日ラベル
  ///
  /// In ja, this message translates to:
  /// **'支払い日'**
  String get payoutDate;

  /// 売上なしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'売上データがありません'**
  String get noEarnings;

  /// 売上登録成功
  ///
  /// In ja, this message translates to:
  /// **'売上を登録しました'**
  String get earningsCreated;

  /// 通知なしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'お知らせはありません'**
  String get noNotifications;

  /// 既読マークボタン
  ///
  /// In ja, this message translates to:
  /// **'既読にする'**
  String get markAsRead;

  /// お問い合わせタイトル
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ'**
  String get contactTitle;

  /// 件名ラベル
  ///
  /// In ja, this message translates to:
  /// **'件名'**
  String get contactSubject;

  /// 問い合わせ内容ラベル
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ内容'**
  String get contactBody;

  /// カテゴリラベル
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ'**
  String get contactCategory;

  /// 問い合わせ送信成功
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせを送信しました'**
  String get contactSent;

  /// カテゴリ: 一般
  ///
  /// In ja, this message translates to:
  /// **'一般'**
  String get contactCategoryGeneral;

  /// カテゴリ: 不具合
  ///
  /// In ja, this message translates to:
  /// **'不具合報告'**
  String get contactCategoryBug;

  /// カテゴリ: 機能要望
  ///
  /// In ja, this message translates to:
  /// **'機能要望'**
  String get contactCategoryFeature;

  /// カテゴリ: 支払い
  ///
  /// In ja, this message translates to:
  /// **'お支払い'**
  String get contactCategoryPayment;

  /// カテゴリ: その他
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get contactCategoryOther;

  /// FAQタイトル
  ///
  /// In ja, this message translates to:
  /// **'よくある質問'**
  String get faqTitle;

  /// 決済詳細タイトル
  ///
  /// In ja, this message translates to:
  /// **'決済詳細'**
  String get paymentDetail;

  /// 決済状況ラベル
  ///
  /// In ja, this message translates to:
  /// **'決済状況'**
  String get paymentStatus;

  /// 決済成功
  ///
  /// In ja, this message translates to:
  /// **'決済完了'**
  String get paymentSucceeded;

  /// 決済失敗
  ///
  /// In ja, this message translates to:
  /// **'決済失敗'**
  String get paymentFailed;

  /// 決済待ち
  ///
  /// In ja, this message translates to:
  /// **'決済待ち'**
  String get paymentPending;

  /// 手数料ラベル
  ///
  /// In ja, this message translates to:
  /// **'プラットフォーム手数料'**
  String get platformFee;

  /// 振込金額ラベル
  ///
  /// In ja, this message translates to:
  /// **'振込金額'**
  String get netAmount;

  /// Stripe口座設定タイトル
  ///
  /// In ja, this message translates to:
  /// **'口座設定'**
  String get stripeOnboarding;

  /// Stripe設定説明
  ///
  /// In ja, this message translates to:
  /// **'報酬を受け取るために口座情報を設定してください'**
  String get stripeOnboardingDescription;

  /// 口座設定開始ボタン
  ///
  /// In ja, this message translates to:
  /// **'口座設定を開始'**
  String get startOnboarding;

  /// QR出勤タイトル
  ///
  /// In ja, this message translates to:
  /// **'QR出勤'**
  String get qrCheckIn;

  /// QRスキャン説明
  ///
  /// In ja, this message translates to:
  /// **'QRコードをスキャン'**
  String get scanQrCode;

  /// シフトQRタイトル
  ///
  /// In ja, this message translates to:
  /// **'シフトQR'**
  String get shiftQr;

  /// 本人確認タイトル
  ///
  /// In ja, this message translates to:
  /// **'本人確認'**
  String get identityVerification;

  /// 案件編集タイトル
  ///
  /// In ja, this message translates to:
  /// **'案件編集'**
  String get jobEditTitle;

  /// 案件作成タイトル
  ///
  /// In ja, this message translates to:
  /// **'案件作成'**
  String get jobCreateTitle;

  /// 案件保存成功
  ///
  /// In ja, this message translates to:
  /// **'案件を保存しました'**
  String get jobSaved;

  /// 案件削除成功
  ///
  /// In ja, this message translates to:
  /// **'案件を削除しました'**
  String get jobDeleted;

  /// 案件削除確認
  ///
  /// In ja, this message translates to:
  /// **'この案件を削除しますか？'**
  String get deleteJobConfirm;

  /// アカウント削除確認
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除しますか？この操作は取り消せません。'**
  String get deleteAccountConfirm;

  /// アカウント削除タイトル
  ///
  /// In ja, this message translates to:
  /// **'アカウント削除'**
  String get deleteAccountTitle;

  /// アカウント削除成功
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除しました'**
  String get deleteAccountSuccess;

  /// データエクスポート成功
  ///
  /// In ja, this message translates to:
  /// **'データをエクスポートしました'**
  String get dataExportSuccess;

  /// ログアウト確認
  ///
  /// In ja, this message translates to:
  /// **'ログアウトしますか？'**
  String get logoutConfirm;

  /// ログアウト成功
  ///
  /// In ja, this message translates to:
  /// **'ログアウトしました'**
  String get logoutSuccess;

  /// 現在のパスワードラベル
  ///
  /// In ja, this message translates to:
  /// **'現在のパスワード'**
  String get currentPassword;

  /// 新しいパスワードラベル
  ///
  /// In ja, this message translates to:
  /// **'新しいパスワード'**
  String get newPassword;

  /// パスワード確認ラベル
  ///
  /// In ja, this message translates to:
  /// **'パスワード確認'**
  String get confirmPassword;

  /// パスワード変更成功
  ///
  /// In ja, this message translates to:
  /// **'パスワードを変更しました'**
  String get passwordChanged;

  /// 名前変更ボタン
  ///
  /// In ja, this message translates to:
  /// **'名前を変更'**
  String get changeName;

  /// 名前変更成功
  ///
  /// In ja, this message translates to:
  /// **'名前を変更しました'**
  String get nameChanged;

  /// 都道府県ラベル
  ///
  /// In ja, this message translates to:
  /// **'都道府県'**
  String get prefecture;

  /// 日付選択
  ///
  /// In ja, this message translates to:
  /// **'日付を選択'**
  String get dateSelect;

  /// 必須ラベル
  ///
  /// In ja, this message translates to:
  /// **'必須'**
  String get required;

  /// 任意ラベル
  ///
  /// In ja, this message translates to:
  /// **'任意'**
  String get optional;

  /// 円
  ///
  /// In ja, this message translates to:
  /// **'円'**
  String get yen;

  /// 件数表示
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String itemCount(int count);

  /// 未読件数
  ///
  /// In ja, this message translates to:
  /// **'未読{count}件'**
  String unreadCount(int count);

  /// オンボーディング1タイトル
  ///
  /// In ja, this message translates to:
  /// **'仕事を見つけよう'**
  String get onboardingTitle1;

  /// オンボーディング1説明
  ///
  /// In ja, this message translates to:
  /// **'建設業界の仕事を簡単に検索・応募できます'**
  String get onboardingDesc1;

  /// オンボーディング2タイトル
  ///
  /// In ja, this message translates to:
  /// **'QRで出退勤'**
  String get onboardingTitle2;

  /// オンボーディング2説明
  ///
  /// In ja, this message translates to:
  /// **'QRコードをスキャンして簡単に出退勤管理'**
  String get onboardingDesc2;

  /// オンボーディング3タイトル
  ///
  /// In ja, this message translates to:
  /// **'安心の支払い'**
  String get onboardingTitle3;

  /// オンボーディング3説明
  ///
  /// In ja, this message translates to:
  /// **'Stripe決済で安全・確実に報酬を受け取れます'**
  String get onboardingDesc3;

  /// タブ選択中アクセシビリティ
  ///
  /// In ja, this message translates to:
  /// **'選択中'**
  String get tabSelected;

  /// カメラ許可要求
  ///
  /// In ja, this message translates to:
  /// **'カメラの許可が必要です'**
  String get cameraPermissionRequired;

  /// 位置情報許可要求
  ///
  /// In ja, this message translates to:
  /// **'位置情報の許可が必要です'**
  String get locationPermissionRequired;

  /// 設定を開くボタン
  ///
  /// In ja, this message translates to:
  /// **'設定を開く'**
  String get openSettings;

  /// 評価ラベル
  ///
  /// In ja, this message translates to:
  /// **'評価'**
  String get ratingLabel;

  /// 応募者ラベル
  ///
  /// In ja, this message translates to:
  /// **'応募者'**
  String get applicant;

  /// 雇用主ラベル
  ///
  /// In ja, this message translates to:
  /// **'雇用主'**
  String get employer;

  /// チャットタイトル
  ///
  /// In ja, this message translates to:
  /// **'チャット'**
  String get chatWith;

  /// メッセージ送信ボタン
  ///
  /// In ja, this message translates to:
  /// **'メッセージを送信'**
  String get sendMessage;

  /// 今日ラベル
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get today;

  /// 昨日ラベル
  ///
  /// In ja, this message translates to:
  /// **'昨日'**
  String get yesterday;

  /// 案件投稿ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'案件を投稿'**
  String get postJobTitle;

  /// 案件投稿成功
  ///
  /// In ja, this message translates to:
  /// **'案件を投稿しました'**
  String get postJobSuccess;

  /// もっと見るボタン
  ///
  /// In ja, this message translates to:
  /// **'もっと見る'**
  String get loadMore;

  /// 追加データなし
  ///
  /// In ja, this message translates to:
  /// **'これ以上データはありません'**
  String get noMoreData;

  /// リフレッシュ中
  ///
  /// In ja, this message translates to:
  /// **'更新中...'**
  String get refreshing;

  /// ワーカーラベル
  ///
  /// In ja, this message translates to:
  /// **'ワーカー'**
  String get workerLabel;

  /// 応募日ラベル
  ///
  /// In ja, this message translates to:
  /// **'応募日'**
  String get applicationDate;

  /// ゲストモード警告
  ///
  /// In ja, this message translates to:
  /// **'ゲストモードでは一部機能が制限されます'**
  String get guestModeWarning;

  /// 法的情報ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'法的情報'**
  String get legalIndex;

  /// 労災保険ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'労災保険について'**
  String get laborInsurance;

  /// 派遣法ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'労働者派遣法について'**
  String get dispatchLaw;

  /// 職業安定法ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'職業安定法について'**
  String get employmentSecurityLaw;

  /// 法的ドキュメントセクション
  ///
  /// In ja, this message translates to:
  /// **'法的ドキュメント'**
  String get legalDocuments;

  /// 法令遵守セクション
  ///
  /// In ja, this message translates to:
  /// **'法令遵守'**
  String get legalCompliance;

  /// 法的情報メニュー項目
  ///
  /// In ja, this message translates to:
  /// **'法的情報'**
  String get legalInfo;

  /// 法的情報サブタイトル
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー・利用規約・法令情報'**
  String get legalInfoSubtitle;

  /// 友達招待メニュー
  ///
  /// In ja, this message translates to:
  /// **'友達を招待'**
  String get inviteFriends;

  /// 友達招待サブタイトル
  ///
  /// In ja, this message translates to:
  /// **'紹介コードで友達を招待'**
  String get inviteFriendsSubtitle;

  /// 案件シェアボタン
  ///
  /// In ja, this message translates to:
  /// **'案件をシェア'**
  String get shareJob;

  /// 通知設定セクション
  ///
  /// In ja, this message translates to:
  /// **'通知設定'**
  String get notificationSettings;

  /// 通知設定トグル
  ///
  /// In ja, this message translates to:
  /// **'お知らせ通知を受け取る'**
  String get receiveNotifications;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
