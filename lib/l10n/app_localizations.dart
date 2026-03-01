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

  /// データなし表示
  ///
  /// In ja, this message translates to:
  /// **'データがありません'**
  String get noData;

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

  /// 表示名ラベル
  ///
  /// In ja, this message translates to:
  /// **'表示名'**
  String get displayName;

  /// パスワード変更ボタン
  ///
  /// In ja, this message translates to:
  /// **'パスワードを変更'**
  String get changePassword;
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
