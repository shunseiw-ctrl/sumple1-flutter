import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ja'),
    Locale('en'),
  ];

  /// アカウント設定ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'アカウント設定'**
  String get accountSettings;

  /// No description provided for @accountSettings_cancel.
  ///
  /// In ja, this message translates to:
  /// **'・チャット履歴\\n'**
  String get accountSettings_cancel;

  /// No description provided for @accountSettings_changePasswordButton.
  ///
  /// In ja, this message translates to:
  /// **'新しいパスワード（6文字以上）'**
  String get accountSettings_changePasswordButton;

  /// No description provided for @accountSettings_changePasswordLabel.
  ///
  /// In ja, this message translates to:
  /// **'名前を入力'**
  String get accountSettings_changePasswordLabel;

  /// No description provided for @accountSettings_confirm.
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get accountSettings_confirm;

  /// No description provided for @accountSettings_currentPasswordHint.
  ///
  /// In ja, this message translates to:
  /// **'現在のパスワード'**
  String get accountSettings_currentPasswordHint;

  /// No description provided for @accountSettings_delete.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除すると、全てのデータが完全に失われます。\\n\\n'**
  String get accountSettings_delete;

  /// No description provided for @accountSettings_deleteAccount.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除すると、全てのデータが完全に失われます。\\n\\n'**
  String get accountSettings_deleteAccount;

  /// No description provided for @accountSettings_deleteConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除すると、全てのデータが完全に失われます。\\n\\n'**
  String get accountSettings_deleteConfirmMessage;

  /// No description provided for @accountSettings_displayNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'表示名'**
  String get accountSettings_displayNameLabel;

  /// No description provided for @accountSettings_downloadData.
  ///
  /// In ja, this message translates to:
  /// **'データをダウンロード'**
  String get accountSettings_downloadData;

  /// No description provided for @accountSettings_emailLabel.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get accountSettings_emailLabel;

  /// No description provided for @accountSettings_languageLabel.
  ///
  /// In ja, this message translates to:
  /// **'言語設定'**
  String get accountSettings_languageLabel;

  /// No description provided for @accountSettings_loginRequired.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get accountSettings_loginRequired;

  /// No description provided for @accountSettings_nameHint.
  ///
  /// In ja, this message translates to:
  /// **'名前を入力'**
  String get accountSettings_nameHint;

  /// No description provided for @accountSettings_newPasswordHint.
  ///
  /// In ja, this message translates to:
  /// **'新しいパスワード（6文字以上）'**
  String get accountSettings_newPasswordHint;

  /// No description provided for @accountSettings_notSet.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get accountSettings_notSet;

  /// No description provided for @accountSettings_notificationSettings.
  ///
  /// In ja, this message translates to:
  /// **'通知設定'**
  String get accountSettings_notificationSettings;

  /// No description provided for @accountSettings_receiveNotifications.
  ///
  /// In ja, this message translates to:
  /// **'お知らせ通知を受け取る'**
  String get accountSettings_receiveNotifications;

  /// No description provided for @accountSettings_snackDataCopied.
  ///
  /// In ja, this message translates to:
  /// **'データをクリップボードにコピーしました'**
  String get accountSettings_snackDataCopied;

  /// No description provided for @accountSettings_snackDeleteFailed.
  ///
  /// In ja, this message translates to:
  /// **'アカウント削除に失敗しました: {error}'**
  String accountSettings_snackDeleteFailed(String error);

  /// No description provided for @accountSettings_snackDeleteFailedGeneric.
  ///
  /// In ja, this message translates to:
  /// **'アカウント削除に失敗しました: {error}'**
  String accountSettings_snackDeleteFailedGeneric(String error);

  /// No description provided for @accountSettings_snackEnterBothPasswords.
  ///
  /// In ja, this message translates to:
  /// **'現在のパスワードと新しいパスワードを入力してください'**
  String get accountSettings_snackEnterBothPasswords;

  /// No description provided for @accountSettings_snackError.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {error}'**
  String accountSettings_snackError(String error);

  /// No description provided for @accountSettings_snackExportFailed.
  ///
  /// In ja, this message translates to:
  /// **'データエクスポートに失敗しました: {error}'**
  String accountSettings_snackExportFailed(String error);

  /// No description provided for @accountSettings_snackNameUpdated.
  ///
  /// In ja, this message translates to:
  /// **'表示名を更新しました'**
  String get accountSettings_snackNameUpdated;

  /// No description provided for @accountSettings_snackPasswordChangeFailed.
  ///
  /// In ja, this message translates to:
  /// **'パスワード変更に失敗しました: {error}'**
  String accountSettings_snackPasswordChangeFailed(String error);

  /// No description provided for @accountSettings_snackPasswordChanged.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを変更しました'**
  String get accountSettings_snackPasswordChanged;

  /// No description provided for @accountSettings_snackPasswordMinLength.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは6文字以上にしてください'**
  String get accountSettings_snackPasswordMinLength;

  /// No description provided for @accountSettings_snackUpdateFailed.
  ///
  /// In ja, this message translates to:
  /// **'更新に失敗しました: {error}'**
  String accountSettings_snackUpdateFailed(String error);

  /// No description provided for @accountSettings_snackWrongPassword.
  ///
  /// In ja, this message translates to:
  /// **'現在のパスワードが正しくありません'**
  String get accountSettings_snackWrongPassword;

  /// No description provided for @accountSettings_title.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get accountSettings_title;

  /// 住所ラベル
  ///
  /// In ja, this message translates to:
  /// **'住所'**
  String get address;

  /// No description provided for @adminApplicants_bulkApproveButton.
  ///
  /// In ja, this message translates to:
  /// **'一括承認する'**
  String get adminApplicants_bulkApproveButton;

  /// No description provided for @adminApplicants_bulkApproveConfirm.
  ///
  /// In ja, this message translates to:
  /// **'応募中の{count}件をすべて「アサイン済み」に変更しますか？'**
  String adminApplicants_bulkApproveConfirm(String count);

  /// No description provided for @adminApplicants_bulkApproveCount.
  ///
  /// In ja, this message translates to:
  /// **'一括承認 ({count}件)'**
  String adminApplicants_bulkApproveCount(String count);

  /// No description provided for @adminApplicants_bulkApproveFailed.
  ///
  /// In ja, this message translates to:
  /// **'一括承認に失敗しました: {error}'**
  String adminApplicants_bulkApproveFailed(String error);

  /// No description provided for @adminApplicants_bulkApproveTitle.
  ///
  /// In ja, this message translates to:
  /// **'一括承認'**
  String get adminApplicants_bulkApproveTitle;

  /// No description provided for @adminApplicants_bulkApproved.
  ///
  /// In ja, this message translates to:
  /// **'{count}件を承認しました'**
  String adminApplicants_bulkApproved(String count);

  /// No description provided for @adminApplicants_changeButton.
  ///
  /// In ja, this message translates to:
  /// **'変更する'**
  String get adminApplicants_changeButton;

  /// No description provided for @adminApplicants_changeFailed.
  ///
  /// In ja, this message translates to:
  /// **'変更に失敗しました: {error}'**
  String adminApplicants_changeFailed(String error);

  /// No description provided for @adminApplicants_changeStatusConfirm.
  ///
  /// In ja, this message translates to:
  /// **'「{jobTitle}」のステータスを「{statusLabel}」に変更しますか？'**
  String adminApplicants_changeStatusConfirm(
    String jobTitle,
    String statusLabel,
  );

  /// No description provided for @adminApplicants_changeStatusTitle.
  ///
  /// In ja, this message translates to:
  /// **'ステータス変更'**
  String get adminApplicants_changeStatusTitle;

  /// No description provided for @adminApplicants_filterAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get adminApplicants_filterAll;

  /// No description provided for @adminApplicants_filterApplied.
  ///
  /// In ja, this message translates to:
  /// **'応募中'**
  String get adminApplicants_filterApplied;

  /// No description provided for @adminApplicants_filterAssigned.
  ///
  /// In ja, this message translates to:
  /// **'アサイン済み'**
  String get adminApplicants_filterAssigned;

  /// No description provided for @adminApplicants_filterDone.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get adminApplicants_filterDone;

  /// No description provided for @adminApplicants_filterInProgress.
  ///
  /// In ja, this message translates to:
  /// **'作業中'**
  String get adminApplicants_filterInProgress;

  /// No description provided for @adminApplicants_noApplicantsForStatus.
  ///
  /// In ja, this message translates to:
  /// **'「{statusLabel}」の応募者はいません'**
  String adminApplicants_noApplicantsForStatus(String statusLabel);

  /// No description provided for @adminApplicants_noApplicantsYet.
  ///
  /// In ja, this message translates to:
  /// **'応募者はまだいません'**
  String get adminApplicants_noApplicantsYet;

  /// No description provided for @adminApplicants_qualityScore.
  ///
  /// In ja, this message translates to:
  /// **'品質: {score}'**
  String adminApplicants_qualityScore(String score);

  /// No description provided for @adminApplicants_searchHint.
  ///
  /// In ja, this message translates to:
  /// **'名前で検索…'**
  String get adminApplicants_searchHint;

  /// No description provided for @adminApplicants_startWork.
  ///
  /// In ja, this message translates to:
  /// **'作業開始'**
  String get adminApplicants_startWork;

  /// No description provided for @adminApplicants_statusChanged.
  ///
  /// In ja, this message translates to:
  /// **'「{jobTitle}」→「{statusLabel}」に変更しました'**
  String adminApplicants_statusChanged(String jobTitle, String statusLabel);

  /// No description provided for @adminApplicants_statusUpdateNotifBody.
  ///
  /// In ja, this message translates to:
  /// **'「{jobTitle}」のステータスが「{statusLabel}」に変更されました'**
  String adminApplicants_statusUpdateNotifBody(
    String jobTitle,
    String statusLabel,
  );

  /// No description provided for @adminApplicants_statusUpdateNotifTitle.
  ///
  /// In ja, this message translates to:
  /// **'ステータスが更新されました'**
  String get adminApplicants_statusUpdateNotifTitle;

  /// No description provided for @adminApplicants_workCompleted.
  ///
  /// In ja, this message translates to:
  /// **'作業完了'**
  String get adminApplicants_workCompleted;

  /// 応募管理メニュー
  ///
  /// In ja, this message translates to:
  /// **'応募管理'**
  String get adminApplications;

  /// 管理者バッジ
  ///
  /// In ja, this message translates to:
  /// **'管理者'**
  String get adminBadge;

  /// No description provided for @adminDashboard_activeJobs.
  ///
  /// In ja, this message translates to:
  /// **'掲載中の案件'**
  String get adminDashboard_activeJobs;

  /// No description provided for @adminDashboard_alertCount.
  ///
  /// In ja, this message translates to:
  /// **'{label} {count}件'**
  String adminDashboard_alertCount(String label, String count);

  /// No description provided for @adminDashboard_applicationCount.
  ///
  /// In ja, this message translates to:
  /// **'応募数'**
  String get adminDashboard_applicationCount;

  /// No description provided for @adminDashboard_checkSales.
  ///
  /// In ja, this message translates to:
  /// **'売上を確認'**
  String get adminDashboard_checkSales;

  /// No description provided for @adminDashboard_earlyPaymentApproval.
  ///
  /// In ja, this message translates to:
  /// **'即金承認'**
  String get adminDashboard_earlyPaymentApproval;

  /// No description provided for @adminDashboard_identityVerification.
  ///
  /// In ja, this message translates to:
  /// **'本人確認'**
  String get adminDashboard_identityVerification;

  /// No description provided for @adminDashboard_noApplications.
  ///
  /// In ja, this message translates to:
  /// **'まだ応募はありません'**
  String get adminDashboard_noApplications;

  /// No description provided for @adminDashboard_noJobTitle.
  ///
  /// In ja, this message translates to:
  /// **'案件名なし'**
  String get adminDashboard_noJobTitle;

  /// No description provided for @adminDashboard_pendingAlerts.
  ///
  /// In ja, this message translates to:
  /// **'未処理アラート'**
  String get adminDashboard_pendingAlerts;

  /// No description provided for @adminDashboard_pendingApplications.
  ///
  /// In ja, this message translates to:
  /// **'未対応の応募'**
  String get adminDashboard_pendingApplications;

  /// No description provided for @adminDashboard_pendingApproval.
  ///
  /// In ja, this message translates to:
  /// **'承認待ちの応募'**
  String get adminDashboard_pendingApproval;

  /// No description provided for @adminDashboard_pendingEarlyPayments.
  ///
  /// In ja, this message translates to:
  /// **'即金申請待ち'**
  String get adminDashboard_pendingEarlyPayments;

  /// No description provided for @adminDashboard_pendingQualifications.
  ///
  /// In ja, this message translates to:
  /// **'資格承認待ち'**
  String get adminDashboard_pendingQualifications;

  /// No description provided for @adminDashboard_pendingVerifications.
  ///
  /// In ja, this message translates to:
  /// **'本人確認待ち'**
  String get adminDashboard_pendingVerifications;

  /// No description provided for @adminDashboard_postJob.
  ///
  /// In ja, this message translates to:
  /// **'案件を投稿'**
  String get adminDashboard_postJob;

  /// No description provided for @adminDashboard_qualificationApproval.
  ///
  /// In ja, this message translates to:
  /// **'資格承認'**
  String get adminDashboard_qualificationApproval;

  /// No description provided for @adminDashboard_quickActions.
  ///
  /// In ja, this message translates to:
  /// **'クイックアクション'**
  String get adminDashboard_quickActions;

  /// No description provided for @adminDashboard_recentApplications.
  ///
  /// In ja, this message translates to:
  /// **'最近の応募'**
  String get adminDashboard_recentApplications;

  /// No description provided for @adminDashboard_registeredUsers.
  ///
  /// In ja, this message translates to:
  /// **'登録ユーザー'**
  String get adminDashboard_registeredUsers;

  /// No description provided for @adminDashboard_title.
  ///
  /// In ja, this message translates to:
  /// **'管理者ダッシュボード'**
  String get adminDashboard_title;

  /// No description provided for @adminEarlyPayments_approveLabel.
  ///
  /// In ja, this message translates to:
  /// **'承認'**
  String get adminEarlyPayments_approveLabel;

  /// No description provided for @adminEarlyPayments_cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get adminEarlyPayments_cancel;

  /// No description provided for @adminEarlyPayments_emptyDescription.
  ///
  /// In ja, this message translates to:
  /// **'ワーカーが即金申請を行うと、ここに表示されます。'**
  String get adminEarlyPayments_emptyDescription;

  /// No description provided for @adminEarlyPayments_emptyTitle.
  ///
  /// In ja, this message translates to:
  /// **'承認待ちの即金申請はありません'**
  String get adminEarlyPayments_emptyTitle;

  /// No description provided for @adminEarlyPayments_fee.
  ///
  /// In ja, this message translates to:
  /// **'手数料 (10%)'**
  String get adminEarlyPayments_fee;

  /// No description provided for @adminEarlyPayments_loadError.
  ///
  /// In ja, this message translates to:
  /// **'読み込みエラー: {error}'**
  String adminEarlyPayments_loadError(String error);

  /// No description provided for @adminEarlyPayments_loading.
  ///
  /// In ja, this message translates to:
  /// **'読み込み中...'**
  String get adminEarlyPayments_loading;

  /// No description provided for @adminEarlyPayments_nameNotSet.
  ///
  /// In ja, this message translates to:
  /// **'名前未設定'**
  String get adminEarlyPayments_nameNotSet;

  /// No description provided for @adminEarlyPayments_notifyApprovedBody.
  ///
  /// In ja, this message translates to:
  /// **'即金申請が承認されました。まもなく振り込まれます。'**
  String get adminEarlyPayments_notifyApprovedBody;

  /// No description provided for @adminEarlyPayments_notifyApprovedTitle.
  ///
  /// In ja, this message translates to:
  /// **'即金申請が承認されました'**
  String get adminEarlyPayments_notifyApprovedTitle;

  /// No description provided for @adminEarlyPayments_notifyRejectedBody.
  ///
  /// In ja, this message translates to:
  /// **'即金申請が却下されました。理由: {reason}'**
  String adminEarlyPayments_notifyRejectedBody(String reason);

  /// No description provided for @adminEarlyPayments_notifyRejectedTitle.
  ///
  /// In ja, this message translates to:
  /// **'即金申請が却下されました'**
  String get adminEarlyPayments_notifyRejectedTitle;

  /// No description provided for @adminEarlyPayments_payoutAmount.
  ///
  /// In ja, this message translates to:
  /// **'支払額'**
  String get adminEarlyPayments_payoutAmount;

  /// No description provided for @adminEarlyPayments_rejectButton.
  ///
  /// In ja, this message translates to:
  /// **'却下する'**
  String get adminEarlyPayments_rejectButton;

  /// No description provided for @adminEarlyPayments_rejectLabel.
  ///
  /// In ja, this message translates to:
  /// **'却下'**
  String get adminEarlyPayments_rejectLabel;

  /// No description provided for @adminEarlyPayments_rejectReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'却下の理由を入力してください'**
  String get adminEarlyPayments_rejectReasonHint;

  /// No description provided for @adminEarlyPayments_rejectReasonRequired.
  ///
  /// In ja, this message translates to:
  /// **'却下理由を入力してください'**
  String get adminEarlyPayments_rejectReasonRequired;

  /// No description provided for @adminEarlyPayments_rejectReasonTitle.
  ///
  /// In ja, this message translates to:
  /// **'却下理由'**
  String get adminEarlyPayments_rejectReasonTitle;

  /// No description provided for @adminEarlyPayments_requestDate.
  ///
  /// In ja, this message translates to:
  /// **'申請日時: {date}'**
  String adminEarlyPayments_requestDate(String date);

  /// No description provided for @adminEarlyPayments_requestedAmount.
  ///
  /// In ja, this message translates to:
  /// **'申請額'**
  String get adminEarlyPayments_requestedAmount;

  /// No description provided for @adminEarlyPayments_snackApproveFailed.
  ///
  /// In ja, this message translates to:
  /// **'承認に失敗しました'**
  String get adminEarlyPayments_snackApproveFailed;

  /// No description provided for @adminEarlyPayments_snackApproved.
  ///
  /// In ja, this message translates to:
  /// **'即金申請を承認しました'**
  String get adminEarlyPayments_snackApproved;

  /// No description provided for @adminEarlyPayments_snackRejectFailed.
  ///
  /// In ja, this message translates to:
  /// **'却下に失敗しました'**
  String get adminEarlyPayments_snackRejectFailed;

  /// No description provided for @adminEarlyPayments_snackRejected.
  ///
  /// In ja, this message translates to:
  /// **'即金申請を却下しました'**
  String get adminEarlyPayments_snackRejected;

  /// No description provided for @adminEarlyPayments_statusRequested.
  ///
  /// In ja, this message translates to:
  /// **'申請中'**
  String get adminEarlyPayments_statusRequested;

  /// No description provided for @adminEarlyPayments_targetMonth.
  ///
  /// In ja, this message translates to:
  /// **'対象月'**
  String get adminEarlyPayments_targetMonth;

  /// No description provided for @adminEarlyPayments_title.
  ///
  /// In ja, this message translates to:
  /// **'即金申請一覧'**
  String get adminEarlyPayments_title;

  /// No description provided for @adminEarlyPayments_yenFormat.
  ///
  /// In ja, this message translates to:
  /// **'{amount}円'**
  String adminEarlyPayments_yenFormat(String amount);

  /// 管理者ホームタイトル
  ///
  /// In ja, this message translates to:
  /// **'管理者ダッシュボード'**
  String get adminHome;

  /// No description provided for @adminHome_admin.
  ///
  /// In ja, this message translates to:
  /// **'管理者'**
  String get adminHome_admin;

  /// No description provided for @adminHome_applicants.
  ///
  /// In ja, this message translates to:
  /// **'応募者'**
  String get adminHome_applicants;

  /// No description provided for @adminHome_dashboard.
  ///
  /// In ja, this message translates to:
  /// **'ダッシュボード'**
  String get adminHome_dashboard;

  /// No description provided for @adminHome_jobManagement.
  ///
  /// In ja, this message translates to:
  /// **'案件管理'**
  String get adminHome_jobManagement;

  /// No description provided for @adminHome_notifications.
  ///
  /// In ja, this message translates to:
  /// **'お知らせ'**
  String get adminHome_notifications;

  /// No description provided for @adminHome_salesManagement.
  ///
  /// In ja, this message translates to:
  /// **'売上管理'**
  String get adminHome_salesManagement;

  /// No description provided for @adminHome_settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get adminHome_settings;

  /// No description provided for @adminIdentityVerification_approveButton.
  ///
  /// In ja, this message translates to:
  /// **'承認する'**
  String get adminIdentityVerification_approveButton;

  /// No description provided for @adminIdentityVerification_approveConfirm.
  ///
  /// In ja, this message translates to:
  /// **'この本人確認を承認しますか？'**
  String get adminIdentityVerification_approveConfirm;

  /// No description provided for @adminIdentityVerification_approveFailed.
  ///
  /// In ja, this message translates to:
  /// **'承認に失敗しました: {error}'**
  String adminIdentityVerification_approveFailed(String error);

  /// No description provided for @adminIdentityVerification_approveTitle.
  ///
  /// In ja, this message translates to:
  /// **'承認確認'**
  String get adminIdentityVerification_approveTitle;

  /// No description provided for @adminIdentityVerification_approved.
  ///
  /// In ja, this message translates to:
  /// **'承認しました'**
  String get adminIdentityVerification_approved;

  /// No description provided for @adminIdentityVerification_enterRejectReason.
  ///
  /// In ja, this message translates to:
  /// **'却下理由を入力してください'**
  String get adminIdentityVerification_enterRejectReason;

  /// No description provided for @adminIdentityVerification_idDocumentPhoto.
  ///
  /// In ja, this message translates to:
  /// **'身分証明書'**
  String get adminIdentityVerification_idDocumentPhoto;

  /// No description provided for @adminIdentityVerification_noPendingRequests.
  ///
  /// In ja, this message translates to:
  /// **'審査待ちの申請はありません'**
  String get adminIdentityVerification_noPendingRequests;

  /// No description provided for @adminIdentityVerification_rejectButton.
  ///
  /// In ja, this message translates to:
  /// **'却下する'**
  String get adminIdentityVerification_rejectButton;

  /// No description provided for @adminIdentityVerification_rejectFailed.
  ///
  /// In ja, this message translates to:
  /// **'却下に失敗しました: {error}'**
  String adminIdentityVerification_rejectFailed(String error);

  /// No description provided for @adminIdentityVerification_rejectReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 写真が不鮮明です'**
  String get adminIdentityVerification_rejectReasonHint;

  /// No description provided for @adminIdentityVerification_rejectTitle.
  ///
  /// In ja, this message translates to:
  /// **'却下確認'**
  String get adminIdentityVerification_rejectTitle;

  /// No description provided for @adminIdentityVerification_rejected.
  ///
  /// In ja, this message translates to:
  /// **'却下しました'**
  String get adminIdentityVerification_rejected;

  /// No description provided for @adminIdentityVerification_selfiePhoto.
  ///
  /// In ja, this message translates to:
  /// **'自撮り写真'**
  String get adminIdentityVerification_selfiePhoto;

  /// No description provided for @adminIdentityVerification_title.
  ///
  /// In ja, this message translates to:
  /// **'本人確認管理'**
  String get adminIdentityVerification_title;

  /// 案件管理メニュー
  ///
  /// In ja, this message translates to:
  /// **'案件管理'**
  String get adminJobManagement;

  /// No description provided for @adminJobManagement_applicantCount.
  ///
  /// In ja, this message translates to:
  /// **'応募者 {count}'**
  String adminJobManagement_applicantCount(String count);

  /// No description provided for @adminJobManagement_checkNetwork.
  ///
  /// In ja, this message translates to:
  /// **'権限がありません'**
  String get adminJobManagement_checkNetwork;

  /// No description provided for @adminJobManagement_dateTbd.
  ///
  /// In ja, this message translates to:
  /// **'未定'**
  String get adminJobManagement_dateTbd;

  /// No description provided for @adminJobManagement_filterActive.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get adminJobManagement_filterActive;

  /// No description provided for @adminJobManagement_filterAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get adminJobManagement_filterAll;

  /// No description provided for @adminJobManagement_filterCompleted.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get adminJobManagement_filterCompleted;

  /// No description provided for @adminJobManagement_filterDraft.
  ///
  /// In ja, this message translates to:
  /// **'公開中'**
  String get adminJobManagement_filterDraft;

  /// No description provided for @adminJobManagement_loadFailed.
  ///
  /// In ja, this message translates to:
  /// **'データの読み込みに失敗しました'**
  String get adminJobManagement_loadFailed;

  /// No description provided for @adminJobManagement_locationNotSet.
  ///
  /// In ja, this message translates to:
  /// **'場所未設定'**
  String get adminJobManagement_locationNotSet;

  /// No description provided for @adminJobManagement_noJobs.
  ///
  /// In ja, this message translates to:
  /// **'案件がまだありません'**
  String get adminJobManagement_noJobs;

  /// No description provided for @adminJobManagement_noPermission.
  ///
  /// In ja, this message translates to:
  /// **'権限がありません'**
  String get adminJobManagement_noPermission;

  /// No description provided for @adminJobManagement_noTitle.
  ///
  /// In ja, this message translates to:
  /// **'タイトルなし'**
  String get adminJobManagement_noTitle;

  /// No description provided for @adminJobManagement_postHint.
  ///
  /// In ja, this message translates to:
  /// **'案件がまだありません'**
  String get adminJobManagement_postHint;

  /// No description provided for @adminJobManagement_postJob.
  ///
  /// In ja, this message translates to:
  /// **'案件を投稿'**
  String get adminJobManagement_postJob;

  /// No description provided for @adminJobManagement_searchHint.
  ///
  /// In ja, this message translates to:
  /// **'タイトル・場所で検索'**
  String get adminJobManagement_searchHint;

  /// No description provided for @adminJobManagement_showMore.
  ///
  /// In ja, this message translates to:
  /// **'もっと見る'**
  String get adminJobManagement_showMore;

  /// No description provided for @adminJob_viewJobs.
  ///
  /// In ja, this message translates to:
  /// **'案件一覧'**
  String get adminJob_viewJobs;

  /// No description provided for @adminJob_viewApplications.
  ///
  /// In ja, this message translates to:
  /// **'全応募ステータス'**
  String get adminJob_viewApplications;

  /// No description provided for @adminJob_summaryTotal.
  ///
  /// In ja, this message translates to:
  /// **'全{count}件'**
  String adminJob_summaryTotal(String count);

  /// No description provided for @adminJob_summaryActive.
  ///
  /// In ja, this message translates to:
  /// **'募集中{count}件'**
  String adminJob_summaryActive(String count);

  /// No description provided for @adminJob_summaryCompleted.
  ///
  /// In ja, this message translates to:
  /// **'完了{count}件'**
  String adminJob_summaryCompleted(String count);

  /// No description provided for @adminApplicants_summaryPending.
  ///
  /// In ja, this message translates to:
  /// **'要対応{count}件'**
  String adminApplicants_summaryPending(String count);

  /// No description provided for @adminApplicants_summaryAssigned.
  ///
  /// In ja, this message translates to:
  /// **'確定済{count}件'**
  String adminApplicants_summaryAssigned(String count);

  /// No description provided for @adminApplicants_summaryInProgress.
  ///
  /// In ja, this message translates to:
  /// **'進行中{count}件'**
  String adminApplicants_summaryInProgress(String count);

  /// No description provided for @adminApplicants_summaryDone.
  ///
  /// In ja, this message translates to:
  /// **'完了{count}件'**
  String adminApplicants_summaryDone(String count);

  /// No description provided for @adminWorker_title.
  ///
  /// In ja, this message translates to:
  /// **'職人詳細'**
  String get adminWorker_title;

  /// No description provided for @adminWorker_applicationHistory.
  ///
  /// In ja, this message translates to:
  /// **'応募履歴'**
  String get adminWorker_applicationHistory;

  /// No description provided for @adminWorker_qualifications.
  ///
  /// In ja, this message translates to:
  /// **'資格情報'**
  String get adminWorker_qualifications;

  /// No description provided for @adminWorker_unknownWorker.
  ///
  /// In ja, this message translates to:
  /// **'不明な職人'**
  String get adminWorker_unknownWorker;

  /// No description provided for @adminWorker_noApplications.
  ///
  /// In ja, this message translates to:
  /// **'応募履歴はありません'**
  String get adminWorker_noApplications;

  /// No description provided for @adminWorker_noQualifications.
  ///
  /// In ja, this message translates to:
  /// **'資格情報はありません'**
  String get adminWorker_noQualifications;

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

  /// No description provided for @adminLogin_email.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get adminLogin_email;

  /// No description provided for @adminLogin_emailInvalid.
  ///
  /// In ja, this message translates to:
  /// **'有効なメールアドレスを入力してください'**
  String get adminLogin_emailInvalid;

  /// No description provided for @adminLogin_emailRequired.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスを入力してください'**
  String get adminLogin_emailRequired;

  /// No description provided for @adminLogin_lockoutMessage.
  ///
  /// In ja, this message translates to:
  /// **'ログイン試行回数の上限に達しました。{minutes}分{seconds}秒後にお試しください'**
  String adminLogin_lockoutMessage(String minutes, String seconds);

  /// No description provided for @adminLogin_login.
  ///
  /// In ja, this message translates to:
  /// **'ログインしました'**
  String get adminLogin_login;

  /// No description provided for @adminLogin_loginSuccess.
  ///
  /// In ja, this message translates to:
  /// **'ログインしました'**
  String get adminLogin_loginSuccess;

  /// No description provided for @adminLogin_password.
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get adminLogin_password;

  /// No description provided for @adminLogin_passwordMinLength.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは6文字以上で入力してください'**
  String get adminLogin_passwordMinLength;

  /// No description provided for @adminLogin_passwordRequired.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを入力してください'**
  String get adminLogin_passwordRequired;

  /// No description provided for @adminLogin_title.
  ///
  /// In ja, this message translates to:
  /// **'管理者ログイン'**
  String get adminLogin_title;

  /// 管理者パスワードラベル
  ///
  /// In ja, this message translates to:
  /// **'管理者パスワード'**
  String get adminPassword;

  /// 決済管理メニュー
  ///
  /// In ja, this message translates to:
  /// **'決済管理'**
  String get adminPayments;

  /// No description provided for @adminQualifications_approve.
  ///
  /// In ja, this message translates to:
  /// **'承認'**
  String get adminQualifications_approve;

  /// No description provided for @adminQualifications_approveError.
  ///
  /// In ja, this message translates to:
  /// **'承認に失敗しました'**
  String get adminQualifications_approveError;

  /// No description provided for @adminQualifications_approveSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{name}を承認しました'**
  String adminQualifications_approveSuccess(String name);

  /// No description provided for @adminQualifications_category.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ: {category}'**
  String adminQualifications_category(String category);

  /// No description provided for @adminQualifications_emptyDescription.
  ///
  /// In ja, this message translates to:
  /// **'承認待ちの資格はありません'**
  String get adminQualifications_emptyDescription;

  /// No description provided for @adminQualifications_emptyTitle.
  ///
  /// In ja, this message translates to:
  /// **'承認待ちの資格はありません'**
  String get adminQualifications_emptyTitle;

  /// No description provided for @adminQualifications_imageLoadError.
  ///
  /// In ja, this message translates to:
  /// **'画像を読み込めませんでした'**
  String get adminQualifications_imageLoadError;

  /// No description provided for @adminQualifications_loadError.
  ///
  /// In ja, this message translates to:
  /// **'読み込みに失敗しました'**
  String get adminQualifications_loadError;

  /// No description provided for @adminQualifications_noName.
  ///
  /// In ja, this message translates to:
  /// **'名前なし'**
  String get adminQualifications_noName;

  /// No description provided for @adminQualifications_pendingApproval.
  ///
  /// In ja, this message translates to:
  /// **'承認待ち'**
  String get adminQualifications_pendingApproval;

  /// No description provided for @adminQualifications_reject.
  ///
  /// In ja, this message translates to:
  /// **'却下'**
  String get adminQualifications_reject;

  /// No description provided for @adminQualifications_rejectButton.
  ///
  /// In ja, this message translates to:
  /// **'却下する'**
  String get adminQualifications_rejectButton;

  /// No description provided for @adminQualifications_rejectError.
  ///
  /// In ja, this message translates to:
  /// **'却下に失敗しました'**
  String get adminQualifications_rejectError;

  /// No description provided for @adminQualifications_rejectReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'却下の理由を入力してください'**
  String get adminQualifications_rejectReasonHint;

  /// No description provided for @adminQualifications_rejectReasonRequired.
  ///
  /// In ja, this message translates to:
  /// **'却下理由を入力してください'**
  String get adminQualifications_rejectReasonRequired;

  /// No description provided for @adminQualifications_rejectReasonTitle.
  ///
  /// In ja, this message translates to:
  /// **'却下理由'**
  String get adminQualifications_rejectReasonTitle;

  /// No description provided for @adminQualifications_rejectSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{name}を却下しました'**
  String adminQualifications_rejectSuccess(String name);

  /// No description provided for @adminQualifications_title.
  ///
  /// In ja, this message translates to:
  /// **'資格承認'**
  String get adminQualifications_title;

  /// No description provided for @adminSearch_hint.
  ///
  /// In ja, this message translates to:
  /// **'検索…'**
  String get adminSearch_hint;

  /// ユーザー管理メニュー
  ///
  /// In ja, this message translates to:
  /// **'ユーザー管理'**
  String get adminUsers;

  /// プライバシーポリシー同意チェック
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシーに同意する'**
  String get agreeToPrivacy;

  /// 利用規約同意チェック
  ///
  /// In ja, this message translates to:
  /// **'利用規約に同意する'**
  String get agreeToTerms;

  /// 全都道府県
  ///
  /// In ja, this message translates to:
  /// **'全国'**
  String get allPrefectures;

  /// 応募済み表示
  ///
  /// In ja, this message translates to:
  /// **'応募済み'**
  String get alreadyApplied;

  /// 金額ラベル
  ///
  /// In ja, this message translates to:
  /// **'金額'**
  String get amount;

  /// アプリ名
  ///
  /// In ja, this message translates to:
  /// **'ALBAWORK'**
  String get appName;

  /// アプリのキャッチコピー
  ///
  /// In ja, this message translates to:
  /// **'建設業界の仕事マッチングアプリ'**
  String get appTagline;

  /// Appleログイン成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'Appleでログインしました'**
  String get appleLoginSuccess;

  /// 応募者ラベル
  ///
  /// In ja, this message translates to:
  /// **'応募者'**
  String get applicant;

  /// 応募確認メッセージ
  ///
  /// In ja, this message translates to:
  /// **'この案件に応募しますか？'**
  String get applicationConfirm;

  /// 応募日ラベル
  ///
  /// In ja, this message translates to:
  /// **'応募日'**
  String get applicationDate;

  /// 応募成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'応募が完了しました'**
  String get applicationSuccess;

  /// 応募ボタン
  ///
  /// In ja, this message translates to:
  /// **'応募する'**
  String get apply;

  /// 案件応募ボタン
  ///
  /// In ja, this message translates to:
  /// **'この案件に応募する'**
  String get applyForJob;

  /// No description provided for @asyncValue_errorOccurred.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました'**
  String get asyncValue_errorOccurred;

  /// No description provided for @asyncValue_loadFailed.
  ///
  /// In ja, this message translates to:
  /// **'ネットワークエラーが発生しました'**
  String get asyncValue_loadFailed;

  /// No description provided for @asyncValue_networkError.
  ///
  /// In ja, this message translates to:
  /// **'権限がありません'**
  String get asyncValue_networkError;

  /// No description provided for @asyncValue_permissionDenied.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました'**
  String get asyncValue_permissionDenied;

  /// 認証エラー
  ///
  /// In ja, this message translates to:
  /// **'認証エラーが発生しました'**
  String get authError;

  /// No description provided for @authGate_authError.
  ///
  /// In ja, this message translates to:
  /// **'認証処理中にエラーが発生しました\nもう一度お試しください'**
  String get authGate_authError;

  /// No description provided for @authGate_roleError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報の取得に失敗しました'**
  String get authGate_roleError;

  /// 汎用戻るボタン
  ///
  /// In ja, this message translates to:
  /// **'戻る'**
  String get back;

  /// 生年月日ラベル
  ///
  /// In ja, this message translates to:
  /// **'生年月日'**
  String get birthDate;

  /// カメラ許可要求
  ///
  /// In ja, this message translates to:
  /// **'カメラの許可が必要です'**
  String get cameraPermissionRequired;

  /// 汎用キャンセルボタン
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// 名前変更ボタン
  ///
  /// In ja, this message translates to:
  /// **'名前を変更'**
  String get changeName;

  /// パスワード変更ボタン
  ///
  /// In ja, this message translates to:
  /// **'パスワードを変更'**
  String get changePassword;

  /// No description provided for @chatRoom_attachImage.
  ///
  /// In ja, this message translates to:
  /// **'画像を添付'**
  String get chatRoom_attachImage;

  /// No description provided for @chatRoom_imageSendFailed.
  ///
  /// In ja, this message translates to:
  /// **'画像の送信に失敗しました'**
  String get chatRoom_imageSendFailed;

  /// No description provided for @chatRoom_inputHint.
  ///
  /// In ja, this message translates to:
  /// **'メッセージを入力'**
  String get chatRoom_inputHint;

  /// No description provided for @chatRoom_loadError.
  ///
  /// In ja, this message translates to:
  /// **'読み込みエラー'**
  String get chatRoom_loadError;

  /// No description provided for @chatRoom_loginRequired.
  ///
  /// In ja, this message translates to:
  /// **'チャットの準備ができていません'**
  String get chatRoom_loginRequired;

  /// No description provided for @chatRoom_notReady.
  ///
  /// In ja, this message translates to:
  /// **'チャットの準備ができていません'**
  String get chatRoom_notReady;

  /// No description provided for @chatRoom_pickFromGallery.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選択'**
  String get chatRoom_pickFromGallery;

  /// No description provided for @chatRoom_read.
  ///
  /// In ja, this message translates to:
  /// **'既読'**
  String get chatRoom_read;

  /// No description provided for @chatRoom_retry.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get chatRoom_retry;

  /// No description provided for @chatRoom_sendFailed.
  ///
  /// In ja, this message translates to:
  /// **'メッセージの送信に失敗しました'**
  String get chatRoom_sendFailed;

  /// No description provided for @chatRoom_startConversation.
  ///
  /// In ja, this message translates to:
  /// **'メッセージを始めましょう'**
  String get chatRoom_startConversation;

  /// No description provided for @chatRoom_takePhoto.
  ///
  /// In ja, this message translates to:
  /// **'カメラで撮影'**
  String get chatRoom_takePhoto;

  /// No description provided for @chatRoom_title.
  ///
  /// In ja, this message translates to:
  /// **'チャット'**
  String get chatRoom_title;

  /// No description provided for @chatRoom_today.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get chatRoom_today;

  /// No description provided for @chatRoom_uploadFailed.
  ///
  /// In ja, this message translates to:
  /// **'画像のアップロードに失敗しました'**
  String get chatRoom_uploadFailed;

  /// No description provided for @chatRoom_yesterday.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get chatRoom_yesterday;

  /// チャットタイトル
  ///
  /// In ja, this message translates to:
  /// **'チャット'**
  String get chatWith;

  /// 出勤ボタン
  ///
  /// In ja, this message translates to:
  /// **'出勤'**
  String get checkIn;

  /// 出勤成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'出勤しました'**
  String get checkInSuccess;

  /// 退勤ボタン
  ///
  /// In ja, this message translates to:
  /// **'退勤'**
  String get checkOut;

  /// 退勤成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'退勤しました'**
  String get checkOutSuccess;

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

  /// 汎用閉じるボタン
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// No description provided for @common_adminOnlyView.
  ///
  /// In ja, this message translates to:
  /// **'管理者のみ閲覧できます'**
  String get common_adminOnlyView;

  /// No description provided for @common_all.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get common_all;

  /// No description provided for @common_approve.
  ///
  /// In ja, this message translates to:
  /// **'承認'**
  String get common_approve;

  /// No description provided for @common_cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get common_cancel;

  /// No description provided for @common_completed.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get common_completed;

  /// No description provided for @common_confirmed.
  ///
  /// In ja, this message translates to:
  /// **'確定済み'**
  String get common_confirmed;

  /// No description provided for @common_dataLoadError.
  ///
  /// In ja, this message translates to:
  /// **'データの読み込みに失敗しました'**
  String get common_dataLoadError;

  /// No description provided for @common_delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get common_delete;

  /// No description provided for @common_deleted.
  ///
  /// In ja, this message translates to:
  /// **'削除しました'**
  String get common_deleted;

  /// No description provided for @common_edit.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get common_edit;

  /// No description provided for @common_itemsCount.
  ///
  /// In ja, this message translates to:
  /// **'件'**
  String get common_itemsCount;

  /// No description provided for @common_job.
  ///
  /// In ja, this message translates to:
  /// **'案件'**
  String get common_job;

  /// No description provided for @common_loadError.
  ///
  /// In ja, this message translates to:
  /// **'読み込みエラー: {error}'**
  String common_loadError(String error);

  /// No description provided for @common_noTitle.
  ///
  /// In ja, this message translates to:
  /// **'タイトルなし'**
  String get common_noTitle;

  /// No description provided for @common_notSet.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get common_notSet;

  /// No description provided for @common_ok.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_pleaseLogin.
  ///
  /// In ja, this message translates to:
  /// **'ログインしてください'**
  String get common_pleaseLogin;

  /// No description provided for @common_registerToSaveFavorites.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りを保存するには会員登録が必要です'**
  String get common_registerToSaveFavorites;

  /// No description provided for @common_registerToStart.
  ///
  /// In ja, this message translates to:
  /// **'登録して始める'**
  String get common_registerToStart;

  /// No description provided for @common_registering.
  ///
  /// In ja, this message translates to:
  /// **'登録中…'**
  String get common_registering;

  /// No description provided for @common_reject.
  ///
  /// In ja, this message translates to:
  /// **'却下'**
  String get common_reject;

  /// No description provided for @common_save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get common_save;

  /// No description provided for @common_select.
  ///
  /// In ja, this message translates to:
  /// **'選択'**
  String get common_select;

  /// No description provided for @common_selected.
  ///
  /// In ja, this message translates to:
  /// **'（選択中）'**
  String get common_selected;

  /// No description provided for @common_transferred.
  ///
  /// In ja, this message translates to:
  /// **'振込済み'**
  String get common_transferred;

  /// No description provided for @common_undecided.
  ///
  /// In ja, this message translates to:
  /// **'未定'**
  String get common_undecided;

  /// No description provided for @common_unknown.
  ///
  /// In ja, this message translates to:
  /// **'不明'**
  String get common_unknown;

  /// 汎用確認ボタン
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get confirm;

  /// パスワード確認ラベル
  ///
  /// In ja, this message translates to:
  /// **'パスワード確認'**
  String get confirmPassword;

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

  /// カテゴリ: 一般
  ///
  /// In ja, this message translates to:
  /// **'一般'**
  String get contactCategoryGeneral;

  /// カテゴリ: その他
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get contactCategoryOther;

  /// カテゴリ: 支払い
  ///
  /// In ja, this message translates to:
  /// **'お支払い'**
  String get contactCategoryPayment;

  /// 問い合わせ送信成功
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせを送信しました'**
  String get contactSent;

  /// 件名ラベル
  ///
  /// In ja, this message translates to:
  /// **'件名'**
  String get contactSubject;

  /// お問い合わせタイトル
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ'**
  String get contactTitle;

  /// No description provided for @contact_bodyHint.
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ内容を入力してください'**
  String get contact_bodyHint;

  /// No description provided for @contact_bodyLabel.
  ///
  /// In ja, this message translates to:
  /// **'送信する'**
  String get contact_bodyLabel;

  /// No description provided for @contact_categoryAccount.
  ///
  /// In ja, this message translates to:
  /// **'アカウントについて'**
  String get contact_categoryAccount;

  /// No description provided for @contact_categoryBug.
  ///
  /// In ja, this message translates to:
  /// **'不具合・バグ報告'**
  String get contact_categoryBug;

  /// No description provided for @contact_categoryGeneral.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get contact_categoryGeneral;

  /// No description provided for @contact_categoryJobs.
  ///
  /// In ja, this message translates to:
  /// **'案件について'**
  String get contact_categoryJobs;

  /// No description provided for @contact_categoryLabel.
  ///
  /// In ja, this message translates to:
  /// **'件名を入力'**
  String get contact_categoryLabel;

  /// No description provided for @contact_categoryOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get contact_categoryOther;

  /// No description provided for @contact_categoryPayment.
  ///
  /// In ja, this message translates to:
  /// **'報酬・支払いについて'**
  String get contact_categoryPayment;

  /// No description provided for @contact_sendError.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ'**
  String get contact_sendError;

  /// No description provided for @contact_sendSuccess.
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ'**
  String get contact_sendSuccess;

  /// No description provided for @contact_subjectHint.
  ///
  /// In ja, this message translates to:
  /// **'送信する'**
  String get contact_subjectHint;

  /// No description provided for @contact_subjectLabel.
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ内容を入力してください'**
  String get contact_subjectLabel;

  /// No description provided for @contact_submitButton.
  ///
  /// In ja, this message translates to:
  /// **'送信する'**
  String get contact_submitButton;

  /// No description provided for @contact_title.
  ///
  /// In ja, this message translates to:
  /// **'件名'**
  String get contact_title;

  /// No description provided for @contact_validationError.
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせを送信しました。ご回答までお待ちください。'**
  String get contact_validationError;

  /// 売上登録ボタン
  ///
  /// In ja, this message translates to:
  /// **'売上を登録'**
  String get createEarnings;

  /// 現在のパスワードラベル
  ///
  /// In ja, this message translates to:
  /// **'現在のパスワード'**
  String get currentPassword;

  /// データエクスポート成功
  ///
  /// In ja, this message translates to:
  /// **'データをエクスポートしました'**
  String get dataExportSuccess;

  /// 日付選択
  ///
  /// In ja, this message translates to:
  /// **'日付を選択'**
  String get dateSelect;

  /// 汎用削除ボタン
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// アカウント削除ボタン
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除'**
  String get deleteAccount;

  /// アカウント削除確認
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除しますか？この操作は取り消せません。'**
  String get deleteAccountConfirm;

  /// アカウント削除成功
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除しました'**
  String get deleteAccountSuccess;

  /// アカウント削除タイトル
  ///
  /// In ja, this message translates to:
  /// **'アカウント削除'**
  String get deleteAccountTitle;

  /// 案件削除確認
  ///
  /// In ja, this message translates to:
  /// **'この案件を削除しますか？'**
  String get deleteJobConfirm;

  /// 派遣法ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'労働者派遣法について'**
  String get dispatchLaw;

  /// 表示名ラベル
  ///
  /// In ja, this message translates to:
  /// **'表示名'**
  String get displayName;

  /// データダウンロードボタン
  ///
  /// In ja, this message translates to:
  /// **'データをダウンロード'**
  String get downloadData;

  /// No description provided for @earningsCreate_adminOnly.
  ///
  /// In ja, this message translates to:
  /// **'Stripe決済は管理者のみ利用できます'**
  String get earningsCreate_adminOnly;

  /// No description provided for @earningsCreate_amountHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 15000'**
  String get earningsCreate_amountHint;

  /// No description provided for @earningsCreate_amountLabel.
  ///
  /// In ja, this message translates to:
  /// **'金額（税込）'**
  String get earningsCreate_amountLabel;

  /// No description provided for @earningsCreate_applicantUidEmpty.
  ///
  /// In ja, this message translates to:
  /// **'応募者UIDが空です'**
  String get earningsCreate_applicantUidEmpty;

  /// No description provided for @earningsCreate_earningRegistered.
  ///
  /// In ja, this message translates to:
  /// **'売上を登録しました'**
  String get earningsCreate_earningRegistered;

  /// No description provided for @earningsCreate_earningsNote.
  ///
  /// In ja, this message translates to:
  /// **'※ 売上は管理者が確認後に反映されます'**
  String get earningsCreate_earningsNote;

  /// No description provided for @earningsCreate_enterAmount.
  ///
  /// In ja, this message translates to:
  /// **'金額を入力してください'**
  String get earningsCreate_enterAmount;

  /// No description provided for @earningsCreate_enterAmountExample.
  ///
  /// In ja, this message translates to:
  /// **'金額を入力してください（例: 15000）'**
  String get earningsCreate_enterAmountExample;

  /// No description provided for @earningsCreate_noAssignedJobs.
  ///
  /// In ja, this message translates to:
  /// **'担当案件がありません'**
  String get earningsCreate_noAssignedJobs;

  /// No description provided for @earningsCreate_paymentDateLabel.
  ///
  /// In ja, this message translates to:
  /// **'支払日'**
  String get earningsCreate_paymentDateLabel;

  /// No description provided for @earningsCreate_registerButton.
  ///
  /// In ja, this message translates to:
  /// **'売上を登録'**
  String get earningsCreate_registerButton;

  /// No description provided for @earningsCreate_registerFailed.
  ///
  /// In ja, this message translates to:
  /// **'登録に失敗しました: {error}'**
  String earningsCreate_registerFailed(String error);

  /// No description provided for @earningsCreate_searchHint.
  ///
  /// In ja, this message translates to:
  /// **'案件を検索…'**
  String get earningsCreate_searchHint;

  /// No description provided for @earningsCreate_selectFromList.
  ///
  /// In ja, this message translates to:
  /// **'上のリストから案件を選んでください'**
  String get earningsCreate_selectFromList;

  /// No description provided for @earningsCreate_selectJob.
  ///
  /// In ja, this message translates to:
  /// **'先に案件を選んでください'**
  String get earningsCreate_selectJob;

  /// No description provided for @earningsCreate_selectPaymentDate.
  ///
  /// In ja, this message translates to:
  /// **'支払日を選択してください'**
  String get earningsCreate_selectPaymentDate;

  /// No description provided for @earningsCreate_stripeCreated.
  ///
  /// In ja, this message translates to:
  /// **'Stripe決済を作成しました (ID: {paymentId})'**
  String earningsCreate_stripeCreated(String paymentId);

  /// No description provided for @earningsCreate_stripeFailed.
  ///
  /// In ja, this message translates to:
  /// **'Stripe決済に失敗: {error}'**
  String earningsCreate_stripeFailed(String error);

  /// No description provided for @earningsCreate_stripePayButton.
  ///
  /// In ja, this message translates to:
  /// **'Stripe決済を作成'**
  String get earningsCreate_stripePayButton;

  /// No description provided for @earningsCreate_title.
  ///
  /// In ja, this message translates to:
  /// **'売上登録'**
  String get earningsCreate_title;

  /// 売上登録成功
  ///
  /// In ja, this message translates to:
  /// **'売上を登録しました'**
  String get earningsCreated;

  /// 売上詳細タイトル
  ///
  /// In ja, this message translates to:
  /// **'売上詳細'**
  String get earningsDetail;

  /// 汎用編集ボタン
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get edit;

  /// プロフィール編集
  ///
  /// In ja, this message translates to:
  /// **'プロフィール編集'**
  String get editProfile;

  /// 承認確認ダイアログ
  ///
  /// In ja, this message translates to:
  /// **'この本人確認を承認しますか？'**
  String get ekycApproveConfirm;

  /// 承認通知
  ///
  /// In ja, this message translates to:
  /// **'本人確認が承認されました'**
  String get ekycApproved;

  /// 身分証タイプ選択
  ///
  /// In ja, this message translates to:
  /// **'身分証の種類'**
  String get ekycDocumentType;

  /// 運転免許証
  ///
  /// In ja, this message translates to:
  /// **'運転免許証'**
  String get ekycDriversLicense;

  /// マイナンバーカード
  ///
  /// In ja, this message translates to:
  /// **'マイナンバーカード'**
  String get ekycMyNumber;

  /// パスポート
  ///
  /// In ja, this message translates to:
  /// **'パスポート'**
  String get ekycPassport;

  /// 管理者向け申請通知
  ///
  /// In ja, this message translates to:
  /// **'本人確認申請'**
  String get ekycPendingReview;

  /// 却下確認ダイアログ
  ///
  /// In ja, this message translates to:
  /// **'この本人確認を却下しますか？'**
  String get ekycRejectConfirm;

  /// 却下通知
  ///
  /// In ja, this message translates to:
  /// **'本人確認が却下されました'**
  String get ekycRejected;

  /// 却下理由ラベル
  ///
  /// In ja, this message translates to:
  /// **'却下理由'**
  String get ekycRejectionReason;

  /// 在留カード
  ///
  /// In ja, this message translates to:
  /// **'在留カード'**
  String get ekycResidenceCard;

  /// 再申請ボタン
  ///
  /// In ja, this message translates to:
  /// **'再申請する'**
  String get ekycResubmit;

  /// 本人確認タイトル
  ///
  /// In ja, this message translates to:
  /// **'本人確認'**
  String get ekycTitle;

  /// メールアドレスラベル
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get email;

  /// メール重複エラー
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは既に登録されています'**
  String get emailAlreadyInUse;

  /// No description provided for @emailAuthDialog_authError.
  ///
  /// In ja, this message translates to:
  /// **'認証エラー: {code}'**
  String emailAuthDialog_authError(String code);

  /// No description provided for @emailAuthDialog_emailAlreadyInUse.
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは既に使用されています'**
  String get emailAuthDialog_emailAlreadyInUse;

  /// No description provided for @emailAuthDialog_emailLabel.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get emailAuthDialog_emailLabel;

  /// No description provided for @emailAuthDialog_enterEmailAndPassword.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスとパスワードを入力してください'**
  String get emailAuthDialog_enterEmailAndPassword;

  /// No description provided for @emailAuthDialog_hidePassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを非表示'**
  String get emailAuthDialog_hidePassword;

  /// No description provided for @emailAuthDialog_invalidEmail.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスの形式が正しくありません'**
  String get emailAuthDialog_invalidEmail;

  /// No description provided for @emailAuthDialog_loginButton.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get emailAuthDialog_loginButton;

  /// No description provided for @emailAuthDialog_loginFailed.
  ///
  /// In ja, this message translates to:
  /// **'ログインに失敗しました'**
  String get emailAuthDialog_loginFailed;

  /// No description provided for @emailAuthDialog_loginLocked.
  ///
  /// In ja, this message translates to:
  /// **'ログイン試行回数が上限に達しました。しばらくお待ちください'**
  String get emailAuthDialog_loginLocked;

  /// No description provided for @emailAuthDialog_loginSuccess.
  ///
  /// In ja, this message translates to:
  /// **'ログインしました'**
  String get emailAuthDialog_loginSuccess;

  /// No description provided for @emailAuthDialog_operationNotAllowed.
  ///
  /// In ja, this message translates to:
  /// **'この認証方法は現在利用できません'**
  String get emailAuthDialog_operationNotAllowed;

  /// No description provided for @emailAuthDialog_passwordLabel.
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get emailAuthDialog_passwordLabel;

  /// No description provided for @emailAuthDialog_passwordMinLength.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは6文字以上にしてください'**
  String get emailAuthDialog_passwordMinLength;

  /// No description provided for @emailAuthDialog_showPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを表示'**
  String get emailAuthDialog_showPassword;

  /// No description provided for @emailAuthDialog_signUpButton.
  ///
  /// In ja, this message translates to:
  /// **'新規登録'**
  String get emailAuthDialog_signUpButton;

  /// No description provided for @emailAuthDialog_signUpFailed.
  ///
  /// In ja, this message translates to:
  /// **'アカウント作成に失敗しました'**
  String get emailAuthDialog_signUpFailed;

  /// No description provided for @emailAuthDialog_signUpHint.
  ///
  /// In ja, this message translates to:
  /// **'アカウントをお持ちでない場合は「新規登録」を押してください'**
  String get emailAuthDialog_signUpHint;

  /// No description provided for @emailAuthDialog_signUpSuccess.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを作成しました'**
  String get emailAuthDialog_signUpSuccess;

  /// No description provided for @emailAuthDialog_title.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスでログイン'**
  String get emailAuthDialog_title;

  /// No description provided for @emailAuthDialog_weakPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードが弱すぎます。6文字以上にしてください'**
  String get emailAuthDialog_weakPassword;

  /// No description provided for @emailAuthDialog_wrongCredentials.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスまたはパスワードが正しくありません'**
  String get emailAuthDialog_wrongCredentials;

  /// No description provided for @emailAuth_cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get emailAuth_cancel;

  /// No description provided for @emailAuth_emailInvalid.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスの形式が正しくありません'**
  String get emailAuth_emailInvalid;

  /// No description provided for @emailAuth_emailLabel.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get emailAuth_emailLabel;

  /// No description provided for @emailAuth_emailRequired.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスを入力してください'**
  String get emailAuth_emailRequired;

  /// No description provided for @emailAuth_errorEmailInUse.
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは既に登録されています'**
  String get emailAuth_errorEmailInUse;

  /// No description provided for @emailAuth_errorGeneric.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました（{code}）'**
  String emailAuth_errorGeneric(String code);

  /// No description provided for @emailAuth_errorInvalidEmail.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスの形式が正しくありません'**
  String get emailAuth_errorInvalidEmail;

  /// No description provided for @emailAuth_errorNetwork.
  ///
  /// In ja, this message translates to:
  /// **'ネットワーク接続を確認してください'**
  String get emailAuth_errorNetwork;

  /// No description provided for @emailAuth_errorTooManyRequests.
  ///
  /// In ja, this message translates to:
  /// **'リクエストが多すぎます。しばらくしてからお試しください'**
  String get emailAuth_errorTooManyRequests;

  /// No description provided for @emailAuth_errorUserDisabled.
  ///
  /// In ja, this message translates to:
  /// **'このアカウントは無効化されています'**
  String get emailAuth_errorUserDisabled;

  /// No description provided for @emailAuth_errorUserNotFound.
  ///
  /// In ja, this message translates to:
  /// **'アカウントが見つかりません'**
  String get emailAuth_errorUserNotFound;

  /// No description provided for @emailAuth_errorWeakPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードが弱すぎます。6文字以上で設定してください'**
  String get emailAuth_errorWeakPassword;

  /// No description provided for @emailAuth_errorWrongPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードが正しくありません'**
  String get emailAuth_errorWrongPassword;

  /// No description provided for @emailAuth_forgotPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを忘れた方'**
  String get emailAuth_forgotPassword;

  /// No description provided for @emailAuth_loginButton.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get emailAuth_loginButton;

  /// No description provided for @emailAuth_passwordConfirmLabel.
  ///
  /// In ja, this message translates to:
  /// **'パスワード（確認）'**
  String get emailAuth_passwordConfirmLabel;

  /// No description provided for @emailAuth_passwordConfirmRequired.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを再入力してください'**
  String get emailAuth_passwordConfirmRequired;

  /// No description provided for @emailAuth_passwordLabel.
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get emailAuth_passwordLabel;

  /// No description provided for @emailAuth_passwordMinLength.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは6文字以上で入力してください'**
  String get emailAuth_passwordMinLength;

  /// No description provided for @emailAuth_passwordMismatch.
  ///
  /// In ja, this message translates to:
  /// **'パスワードが一致しません'**
  String get emailAuth_passwordMismatch;

  /// No description provided for @emailAuth_passwordRequired.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを入力してください'**
  String get emailAuth_passwordRequired;

  /// No description provided for @emailAuth_passwordResetTitle.
  ///
  /// In ja, this message translates to:
  /// **'パスワードリセット'**
  String get emailAuth_passwordResetTitle;

  /// No description provided for @emailAuth_passwordWithMinLength.
  ///
  /// In ja, this message translates to:
  /// **'パスワード（6文字以上）'**
  String get emailAuth_passwordWithMinLength;

  /// No description provided for @emailAuth_registerButton.
  ///
  /// In ja, this message translates to:
  /// **'新規登録'**
  String get emailAuth_registerButton;

  /// No description provided for @emailAuth_sendButton.
  ///
  /// In ja, this message translates to:
  /// **'送信'**
  String get emailAuth_sendButton;

  /// No description provided for @emailAuth_snackLoginFailed.
  ///
  /// In ja, this message translates to:
  /// **'ログインに失敗しました'**
  String get emailAuth_snackLoginFailed;

  /// No description provided for @emailAuth_snackRegisterFailed.
  ///
  /// In ja, this message translates to:
  /// **'登録に失敗しました'**
  String get emailAuth_snackRegisterFailed;

  /// No description provided for @emailAuth_snackResetSent.
  ///
  /// In ja, this message translates to:
  /// **'パスワードリセットメールを送信しました'**
  String get emailAuth_snackResetSent;

  /// No description provided for @emailAuth_snackSendFailed.
  ///
  /// In ja, this message translates to:
  /// **'送信に失敗しました'**
  String get emailAuth_snackSendFailed;

  /// No description provided for @emailAuth_tabLogin.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get emailAuth_tabLogin;

  /// No description provided for @emailAuth_tabRegister.
  ///
  /// In ja, this message translates to:
  /// **'新規登録'**
  String get emailAuth_tabRegister;

  /// No description provided for @emailAuth_title.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスで続ける'**
  String get emailAuth_title;

  /// 雇用主ラベル
  ///
  /// In ja, this message translates to:
  /// **'雇用主'**
  String get employer;

  /// 職業安定法ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'職業安定法について'**
  String get employmentSecurityLaw;

  /// データ未検出タイトル
  ///
  /// In ja, this message translates to:
  /// **'データが見つかりません'**
  String get errorDataNotFound;

  /// 汎用エラー詳細メッセージ
  ///
  /// In ja, this message translates to:
  /// **'しばらく経ってからもう一度お試しください'**
  String get errorDefaultMessage;

  /// 汎用エラーメッセージ
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました'**
  String get errorGeneric;

  /// コンパクトエラーラベル
  ///
  /// In ja, this message translates to:
  /// **'エラー'**
  String get errorLabel;

  /// ネットワークエラーメッセージ
  ///
  /// In ja, this message translates to:
  /// **'ネットワークエラーが発生しました'**
  String get errorNetwork;

  /// ネットワークエラー詳細メッセージ
  ///
  /// In ja, this message translates to:
  /// **'インターネット接続を確認して\nもう一度お試しください'**
  String get errorNetworkMessage;

  /// ネットワークエラータイトル
  ///
  /// In ja, this message translates to:
  /// **'ネットワークエラー'**
  String get errorNetworkTitle;

  /// No description provided for @errorRetry_emptyMessage.
  ///
  /// In ja, this message translates to:
  /// **'条件を変更して再検索してください'**
  String get errorRetry_emptyMessage;

  /// No description provided for @errorRetry_emptyTitle.
  ///
  /// In ja, this message translates to:
  /// **'データが見つかりません'**
  String get errorRetry_emptyTitle;

  /// No description provided for @errorRetry_generalMessage.
  ///
  /// In ja, this message translates to:
  /// **'予期しないエラーが発生しました'**
  String get errorRetry_generalMessage;

  /// No description provided for @errorRetry_generalTitle.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました'**
  String get errorRetry_generalTitle;

  /// No description provided for @errorRetry_networkErrorMessage.
  ///
  /// In ja, this message translates to:
  /// **'インターネット接続を確認してください'**
  String get errorRetry_networkErrorMessage;

  /// No description provided for @errorRetry_networkErrorTitle.
  ///
  /// In ja, this message translates to:
  /// **'ネットワークエラー'**
  String get errorRetry_networkErrorTitle;

  /// No description provided for @errorRetry_timeoutMessage.
  ///
  /// In ja, this message translates to:
  /// **'通信がタイムアウトしました。再試行してください'**
  String get errorRetry_timeoutMessage;

  /// No description provided for @errorRetry_timeoutTitle.
  ///
  /// In ja, this message translates to:
  /// **'タイムアウト'**
  String get errorRetry_timeoutTitle;

  /// 検索リトライメッセージ
  ///
  /// In ja, this message translates to:
  /// **'条件を変更して再検索してください'**
  String get errorSearchRetry;

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

  /// 経験年数ラベル
  ///
  /// In ja, this message translates to:
  /// **'経験年数'**
  String get experienceYears;

  /// 姓ラベル
  ///
  /// In ja, this message translates to:
  /// **'姓'**
  String get familyName;

  /// 姓カナラベル
  ///
  /// In ja, this message translates to:
  /// **'姓（カナ）'**
  String get familyNameKana;

  /// FAQタイトル
  ///
  /// In ja, this message translates to:
  /// **'よくある質問'**
  String get faqTitle;

  /// No description provided for @faq_a1.
  ///
  /// In ja, this message translates to:
  /// **'ALBAWORKとは何ですか？'**
  String get faq_a1;

  /// No description provided for @faq_a2.
  ///
  /// In ja, this message translates to:
  /// **'ALBAWORKとは何ですか？'**
  String get faq_a2;

  /// No description provided for @faq_a3.
  ///
  /// In ja, this message translates to:
  /// **'利用料金はかかりますか？'**
  String get faq_a3;

  /// No description provided for @faq_a4.
  ///
  /// In ja, this message translates to:
  /// **'応募するにはどうすればいいですか？'**
  String get faq_a4;

  /// No description provided for @faq_a5.
  ///
  /// In ja, this message translates to:
  /// **'出退勤はどのように記録しますか？'**
  String get faq_a5;

  /// No description provided for @faq_a6.
  ///
  /// In ja, this message translates to:
  /// **'報酬はどのように受け取れますか？'**
  String get faq_a6;

  /// No description provided for @faq_a7.
  ///
  /// In ja, this message translates to:
  /// **'本人確認は必要ですか？'**
  String get faq_a7;

  /// No description provided for @faq_a8.
  ///
  /// In ja, this message translates to:
  /// **'退会するにはどうすればいいですか？'**
  String get faq_a8;

  /// No description provided for @faq_q1.
  ///
  /// In ja, this message translates to:
  /// **'ALBAWORKとは何ですか？'**
  String get faq_q1;

  /// No description provided for @faq_q2.
  ///
  /// In ja, this message translates to:
  /// **'ALBAWORKとは何ですか？'**
  String get faq_q2;

  /// No description provided for @faq_q3.
  ///
  /// In ja, this message translates to:
  /// **'利用料金はかかりますか？'**
  String get faq_q3;

  /// No description provided for @faq_q4.
  ///
  /// In ja, this message translates to:
  /// **'応募するにはどうすればいいですか？'**
  String get faq_q4;

  /// No description provided for @faq_q5.
  ///
  /// In ja, this message translates to:
  /// **'出退勤はどのように記録しますか？'**
  String get faq_q5;

  /// No description provided for @faq_q6.
  ///
  /// In ja, this message translates to:
  /// **'報酬はどのように受け取れますか？'**
  String get faq_q6;

  /// No description provided for @faq_q7.
  ///
  /// In ja, this message translates to:
  /// **'本人確認は必要ですか？'**
  String get faq_q7;

  /// No description provided for @faq_q8.
  ///
  /// In ja, this message translates to:
  /// **'退会するにはどうすればいいですか？'**
  String get faq_q8;

  /// No description provided for @faq_title.
  ///
  /// In ja, this message translates to:
  /// **'よくある質問'**
  String get faq_title;

  /// No description provided for @favorites_empty.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りはまだありません'**
  String get favorites_empty;

  /// No description provided for @favorites_emptyDescription.
  ///
  /// In ja, this message translates to:
  /// **'気になる案件をお気に入りに追加してみましょう'**
  String get favorites_emptyDescription;

  /// No description provided for @favorites_loginRequired.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get favorites_loginRequired;

  /// No description provided for @favorites_noTitle.
  ///
  /// In ja, this message translates to:
  /// **'タイトルなし'**
  String get favorites_noTitle;

  /// No description provided for @favorites_title.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り案件'**
  String get favorites_title;

  /// 特徴カード: 即収入
  ///
  /// In ja, this message translates to:
  /// **'すぐに稼げる'**
  String get featureQuickEarn;

  /// 特徴カード: 検索
  ///
  /// In ja, this message translates to:
  /// **'仕事を探す'**
  String get featureSearch;

  /// 特徴カード: 安全決済
  ///
  /// In ja, this message translates to:
  /// **'安心の支払い'**
  String get featureSecurePayment;

  /// 都道府県フィルター
  ///
  /// In ja, this message translates to:
  /// **'都道府県で絞り込み'**
  String get filterByPrefecture;

  /// No description provided for @forceUpdate_available.
  ///
  /// In ja, this message translates to:
  /// **'アップデートが必要です'**
  String get forceUpdate_available;

  /// No description provided for @forceUpdate_availableMessage.
  ///
  /// In ja, this message translates to:
  /// **'最新バージョンにアップデートしてください。'**
  String get forceUpdate_availableMessage;

  /// No description provided for @forceUpdate_later.
  ///
  /// In ja, this message translates to:
  /// **'あとで'**
  String get forceUpdate_later;

  /// No description provided for @forceUpdate_required.
  ///
  /// In ja, this message translates to:
  /// **'アップデートが必要です'**
  String get forceUpdate_required;

  /// No description provided for @forceUpdate_requiredMessage.
  ///
  /// In ja, this message translates to:
  /// **'最新バージョンにアップデートしてください。'**
  String get forceUpdate_requiredMessage;

  /// No description provided for @forceUpdate_update.
  ///
  /// In ja, this message translates to:
  /// **'アップデート'**
  String get forceUpdate_update;

  /// パスワード忘れリンク
  ///
  /// In ja, this message translates to:
  /// **'パスワードを忘れた方'**
  String get forgotPassword;

  /// 性別ラベル
  ///
  /// In ja, this message translates to:
  /// **'性別'**
  String get gender;

  /// 女性
  ///
  /// In ja, this message translates to:
  /// **'女性'**
  String get genderFemale;

  /// 男性
  ///
  /// In ja, this message translates to:
  /// **'男性'**
  String get genderMale;

  /// その他
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get genderOther;

  /// オンボーディング: 始める
  ///
  /// In ja, this message translates to:
  /// **'始める'**
  String get getStarted;

  /// 名ラベル
  ///
  /// In ja, this message translates to:
  /// **'名'**
  String get givenName;

  /// 名カナラベル
  ///
  /// In ja, this message translates to:
  /// **'名（カナ）'**
  String get givenNameKana;

  /// ゲスト応募不可メッセージ
  ///
  /// In ja, this message translates to:
  /// **'ゲストは応募できません。ログインしてください'**
  String get guestCannotApply;

  /// No description provided for @guestHome_agreeByLogin.
  ///
  /// In ja, this message translates to:
  /// **'ログインすることで利用規約・プライバシーポリシーに同意したものとみなします'**
  String get guestHome_agreeByLogin;

  /// No description provided for @guestHome_appleLoginSuccess.
  ///
  /// In ja, this message translates to:
  /// **'Appleでログインしました'**
  String get guestHome_appleLoginSuccess;

  /// No description provided for @guestHome_emailLogin.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスでログイン'**
  String get guestHome_emailLogin;

  /// No description provided for @guestHome_featureEarn.
  ///
  /// In ja, this message translates to:
  /// **'すぐに稼げる'**
  String get guestHome_featureEarn;

  /// No description provided for @guestHome_featurePayment.
  ///
  /// In ja, this message translates to:
  /// **'安心の支払い'**
  String get guestHome_featurePayment;

  /// No description provided for @guestHome_featureSearch.
  ///
  /// In ja, this message translates to:
  /// **'仕事を探す'**
  String get guestHome_featureSearch;

  /// No description provided for @guestHome_guestLoginSuccess.
  ///
  /// In ja, this message translates to:
  /// **'ゲストとしてログインしました'**
  String get guestHome_guestLoginSuccess;

  /// No description provided for @guestHome_lineLogin.
  ///
  /// In ja, this message translates to:
  /// **'LINEでログイン'**
  String get guestHome_lineLogin;

  /// No description provided for @guestHome_phoneLogin.
  ///
  /// In ja, this message translates to:
  /// **'電話番号でログイン'**
  String get guestHome_phoneLogin;

  /// No description provided for @guestHome_privacyPolicy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get guestHome_privacyPolicy;

  /// No description provided for @guestHome_startAsGuest.
  ///
  /// In ja, this message translates to:
  /// **'ゲストとして始める'**
  String get guestHome_startAsGuest;

  /// No description provided for @guestHome_subtitle.
  ///
  /// In ja, this message translates to:
  /// **'建設業界の仕事マッチングアプリ'**
  String get guestHome_subtitle;

  /// No description provided for @guestHome_termsOfService.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get guestHome_termsOfService;

  /// ゲストログイン成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'ゲストとしてログインしました'**
  String get guestLoginSuccess;

  /// ゲストモード警告
  ///
  /// In ja, this message translates to:
  /// **'ゲストモードでは一部機能が制限されます'**
  String get guestModeWarning;

  /// パスワード非表示切替
  ///
  /// In ja, this message translates to:
  /// **'パスワードを非表示'**
  String get hidePassword;

  /// No description provided for @home_admin.
  ///
  /// In ja, this message translates to:
  /// **'管理者'**
  String get home_admin;

  /// No description provided for @home_greetingAfternoon.
  ///
  /// In ja, this message translates to:
  /// **'こんにちは'**
  String get home_greetingAfternoon;

  /// No description provided for @home_greetingEvening.
  ///
  /// In ja, this message translates to:
  /// **'こんばんは'**
  String get home_greetingEvening;

  /// No description provided for @home_greetingMorning.
  ///
  /// In ja, this message translates to:
  /// **'おはようございます'**
  String get home_greetingMorning;

  /// No description provided for @home_navMessages.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ'**
  String get home_navMessages;

  /// No description provided for @home_navProfile.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール'**
  String get home_navProfile;

  /// No description provided for @home_navSales.
  ///
  /// In ja, this message translates to:
  /// **'収入'**
  String get home_navSales;

  /// No description provided for @home_navSearch.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get home_navSearch;

  /// No description provided for @home_navSelected.
  ///
  /// In ja, this message translates to:
  /// **'、選択中'**
  String get home_navSelected;

  /// No description provided for @home_navTabLabel.
  ///
  /// In ja, this message translates to:
  /// **'{label}タブ{suffix}'**
  String home_navTabLabel(String label, String suffix);

  /// No description provided for @home_navWork.
  ///
  /// In ja, this message translates to:
  /// **'はたらく'**
  String get home_navWork;

  /// No description provided for @home_notifications.
  ///
  /// In ja, this message translates to:
  /// **'お知らせ、未読{count}件'**
  String home_notifications(String count);

  /// No description provided for @home_notificationsUnread.
  ///
  /// In ja, this message translates to:
  /// **'お知らせ、未読{count}件'**
  String home_notificationsUnread(String count);

  /// No description provided for @home_postJob.
  ///
  /// In ja, this message translates to:
  /// **'案件を投稿'**
  String get home_postJob;

  /// No description provided for @home_statusAdmin.
  ///
  /// In ja, this message translates to:
  /// **'ステータス: 管理者'**
  String get home_statusAdmin;

  /// 本人確認タイトル
  ///
  /// In ja, this message translates to:
  /// **'本人確認'**
  String get identityVerification;

  /// No description provided for @identityVerification_documentTypeLabel.
  ///
  /// In ja, this message translates to:
  /// **'書類の種類'**
  String get identityVerification_documentTypeLabel;

  /// No description provided for @identityVerification_ekycBanner.
  ///
  /// In ja, this message translates to:
  /// **'提出された書類はeKYC（オンライン本人確認）に基づき、管理者が審査します。'**
  String get identityVerification_ekycBanner;

  /// No description provided for @identityVerification_idDocumentSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'運転免許証・マイナンバーカード等'**
  String get identityVerification_idDocumentSubtitle;

  /// No description provided for @identityVerification_idDocumentTitle.
  ///
  /// In ja, this message translates to:
  /// **'身分証明書'**
  String get identityVerification_idDocumentTitle;

  /// No description provided for @identityVerification_instructions.
  ///
  /// In ja, this message translates to:
  /// **'本人確認のため、身分証明書の写真と自撮り写真をアップロードしてください。'**
  String get identityVerification_instructions;

  /// No description provided for @identityVerification_loadStatusFailed.
  ///
  /// In ja, this message translates to:
  /// **'本人確認ステータスの読み込みに失敗しました'**
  String get identityVerification_loadStatusFailed;

  /// No description provided for @identityVerification_rejectionReason.
  ///
  /// In ja, this message translates to:
  /// **'理由: {reason}'**
  String identityVerification_rejectionReason(String reason);

  /// No description provided for @identityVerification_resubmitButton.
  ///
  /// In ja, this message translates to:
  /// **'再申請する'**
  String get identityVerification_resubmitButton;

  /// No description provided for @identityVerification_selfieSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'顔全体が写るように撮影してください'**
  String get identityVerification_selfieSubtitle;

  /// No description provided for @identityVerification_selfieTitle.
  ///
  /// In ja, this message translates to:
  /// **'自撮り写真'**
  String get identityVerification_selfieTitle;

  /// No description provided for @identityVerification_statusApproved.
  ///
  /// In ja, this message translates to:
  /// **'本人確認が完了しました'**
  String get identityVerification_statusApproved;

  /// No description provided for @identityVerification_statusPending.
  ///
  /// In ja, this message translates to:
  /// **'審査中です。しばらくお待ちください'**
  String get identityVerification_statusPending;

  /// No description provided for @identityVerification_statusRejected.
  ///
  /// In ja, this message translates to:
  /// **'本人確認が却下されました'**
  String get identityVerification_statusRejected;

  /// No description provided for @identityVerification_stepSelfie.
  ///
  /// In ja, this message translates to:
  /// **'自撮り'**
  String get identityVerification_stepSelfie;

  /// No description provided for @identityVerification_stepSubmit.
  ///
  /// In ja, this message translates to:
  /// **'申請'**
  String get identityVerification_stepSubmit;

  /// No description provided for @identityVerification_stepUploadId.
  ///
  /// In ja, this message translates to:
  /// **'身分証'**
  String get identityVerification_stepUploadId;

  /// No description provided for @identityVerification_submitButton.
  ///
  /// In ja, this message translates to:
  /// **'本人確認を申請する'**
  String get identityVerification_submitButton;

  /// No description provided for @identityVerification_submitFailed.
  ///
  /// In ja, this message translates to:
  /// **'申請に失敗しました: {error}'**
  String identityVerification_submitFailed(String error);

  /// No description provided for @identityVerification_submitted.
  ///
  /// In ja, this message translates to:
  /// **'本人確認を申請しました。審査をお待ちください'**
  String get identityVerification_submitted;

  /// No description provided for @identityVerification_tapToSelect.
  ///
  /// In ja, this message translates to:
  /// **'タップして選択'**
  String get identityVerification_tapToSelect;

  /// No description provided for @identityVerification_title.
  ///
  /// In ja, this message translates to:
  /// **'本人確認'**
  String get identityVerification_title;

  /// No description provided for @identityVerification_uploadBoth.
  ///
  /// In ja, this message translates to:
  /// **'身分証明書と自撮り写真の両方をアップロードしてください'**
  String get identityVerification_uploadBoth;

  /// No description provided for @imagePicker_camera.
  ///
  /// In ja, this message translates to:
  /// **'カメラで撮影'**
  String get imagePicker_camera;

  /// No description provided for @imagePicker_cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get imagePicker_cancel;

  /// No description provided for @imagePicker_error.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました'**
  String get imagePicker_error;

  /// No description provided for @imagePicker_gallery.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選択（複数可）'**
  String get imagePicker_gallery;

  /// No description provided for @imagePicker_galleryMultiple.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選択（複数可）'**
  String get imagePicker_galleryMultiple;

  /// No description provided for @imagePicker_noImageSelected.
  ///
  /// In ja, this message translates to:
  /// **'画像が選択されませんでした'**
  String get imagePicker_noImageSelected;

  /// No description provided for @imagePicker_selectImage.
  ///
  /// In ja, this message translates to:
  /// **'画像を選択'**
  String get imagePicker_selectImage;

  /// No description provided for @imagePicker_uploadPartial.
  ///
  /// In ja, this message translates to:
  /// **'{successCount}枚成功、{failedCount}枚失敗しました'**
  String imagePicker_uploadPartial(String successCount, String failedCount);

  /// No description provided for @imagePicker_uploadSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{count}枚の画像をアップロードしました'**
  String imagePicker_uploadSuccess(String count);

  /// No description provided for @imagePicker_uploaded.
  ///
  /// In ja, this message translates to:
  /// **'画像をアップロードしました'**
  String get imagePicker_uploaded;

  /// No description provided for @inspection_checklist.
  ///
  /// In ja, this message translates to:
  /// **'チェックリスト'**
  String get inspection_checklist;

  /// No description provided for @inspection_completedLog.
  ///
  /// In ja, this message translates to:
  /// **'検査完了: {result}'**
  String inspection_completedLog(String result);

  /// No description provided for @inspection_fail.
  ///
  /// In ja, this message translates to:
  /// **'検査合格 → 完了'**
  String get inspection_fail;

  /// No description provided for @inspection_failedFixRequest.
  ///
  /// In ja, this message translates to:
  /// **'検査合格 → 完了'**
  String get inspection_failedFixRequest;

  /// No description provided for @inspection_needsFix.
  ///
  /// In ja, this message translates to:
  /// **'要是正'**
  String get inspection_needsFix;

  /// No description provided for @inspection_overallComment.
  ///
  /// In ja, this message translates to:
  /// **'総合コメント'**
  String get inspection_overallComment;

  /// No description provided for @inspection_pass.
  ///
  /// In ja, this message translates to:
  /// **'合格'**
  String get inspection_pass;

  /// No description provided for @inspection_passed.
  ///
  /// In ja, this message translates to:
  /// **'合格'**
  String get inspection_passed;

  /// No description provided for @inspection_passedComplete.
  ///
  /// In ja, this message translates to:
  /// **'検査合格 → 完了'**
  String get inspection_passedComplete;

  /// No description provided for @inspection_submitFailed.
  ///
  /// In ja, this message translates to:
  /// **'検査提出に失敗: {error}'**
  String inspection_submitFailed(String error);

  /// No description provided for @inspection_submitResult.
  ///
  /// In ja, this message translates to:
  /// **'検査結果を提出'**
  String get inspection_submitResult;

  /// No description provided for @inspection_title.
  ///
  /// In ja, this message translates to:
  /// **'施工検査'**
  String get inspection_title;

  /// 自己紹介ラベル
  ///
  /// In ja, this message translates to:
  /// **'自己紹介'**
  String get introduction;

  /// メール形式エラー
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスの形式が正しくありません'**
  String get invalidEmail;

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

  /// No description provided for @itemCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String itemCount(String count);

  /// No description provided for @jobCard_actions.
  ///
  /// In ja, this message translates to:
  /// **'操作'**
  String get jobCard_actions;

  /// No description provided for @jobCard_addFavorite.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りから削除'**
  String get jobCard_addFavorite;

  /// No description provided for @jobCard_delete.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get jobCard_delete;

  /// No description provided for @jobCard_edit.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get jobCard_edit;

  /// No description provided for @jobCard_noOwnerId.
  ///
  /// In ja, this message translates to:
  /// **'ownerIdなし'**
  String get jobCard_noOwnerId;

  /// No description provided for @jobCard_perDay.
  ///
  /// In ja, this message translates to:
  /// **' /日'**
  String get jobCard_perDay;

  /// No description provided for @jobCard_quickStart.
  ///
  /// In ja, this message translates to:
  /// **'即日勤務OK'**
  String get jobCard_quickStart;

  /// No description provided for @jobCard_remainingSlots.
  ///
  /// In ja, this message translates to:
  /// **'残り{count}枠'**
  String jobCard_remainingSlots(String count);

  /// No description provided for @jobCard_removeFavorite.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りから削除'**
  String get jobCard_removeFavorite;

  /// No description provided for @jobCard_semanticsLabel.
  ///
  /// In ja, this message translates to:
  /// **'{title}、場所: {location}、日程: {date}、報酬: {price}'**
  String jobCard_semanticsLabel(
    String title,
    String location,
    String date,
    String price,
  );

  /// 案件作成タイトル
  ///
  /// In ja, this message translates to:
  /// **'案件作成'**
  String get jobCreateTitle;

  /// 勤務日ラベル
  ///
  /// In ja, this message translates to:
  /// **'勤務日'**
  String get jobDate;

  /// 案件削除成功
  ///
  /// In ja, this message translates to:
  /// **'案件を削除しました'**
  String get jobDeleted;

  /// 仕事内容ラベル
  ///
  /// In ja, this message translates to:
  /// **'仕事内容'**
  String get jobDescription;

  /// 案件詳細タイトル
  ///
  /// In ja, this message translates to:
  /// **'案件詳細'**
  String get jobDetail;

  /// No description provided for @jobDetail_addToFavorites.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りに追加'**
  String get jobDetail_addToFavorites;

  /// No description provided for @jobDetail_applicationReceived.
  ///
  /// In ja, this message translates to:
  /// **'{projectName}に応募がありました'**
  String jobDetail_applicationReceived(String projectName);

  /// No description provided for @jobDetail_applied.
  ///
  /// In ja, this message translates to:
  /// **'応募済み'**
  String get jobDetail_applied;

  /// No description provided for @jobDetail_applyButton.
  ///
  /// In ja, this message translates to:
  /// **'応募する'**
  String get jobDetail_applyButton;

  /// No description provided for @jobDetail_applyError.
  ///
  /// In ja, this message translates to:
  /// **'応募に失敗しました'**
  String get jobDetail_applyError;

  /// No description provided for @jobDetail_applyToJob.
  ///
  /// In ja, this message translates to:
  /// **'案件応募'**
  String get jobDetail_applyToJob;

  /// No description provided for @jobDetail_applyToThisJob.
  ///
  /// In ja, this message translates to:
  /// **'この案件に応募する'**
  String get jobDetail_applyToThisJob;

  /// No description provided for @jobDetail_category.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ'**
  String get jobDetail_category;

  /// No description provided for @jobDetail_checking.
  ///
  /// In ja, this message translates to:
  /// **'確認中...'**
  String get jobDetail_checking;

  /// No description provided for @jobDetail_checkingStatus.
  ///
  /// In ja, this message translates to:
  /// **'確認中...'**
  String get jobDetail_checkingStatus;

  /// No description provided for @jobDetail_defaultDescription.
  ///
  /// In ja, this message translates to:
  /// **'詳細情報はまだ登録されていません。'**
  String get jobDetail_defaultDescription;

  /// No description provided for @jobDetail_defaultNotes.
  ///
  /// In ja, this message translates to:
  /// **'特記事項はありません。'**
  String get jobDetail_defaultNotes;

  /// No description provided for @jobDetail_deleteConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'この案件を削除してよろしいですか？この操作は取り消せません。'**
  String get jobDetail_deleteConfirmMessage;

  /// No description provided for @jobDetail_deleteConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'案件を削除'**
  String get jobDetail_deleteConfirmTitle;

  /// No description provided for @jobDetail_deleteError.
  ///
  /// In ja, this message translates to:
  /// **'削除に失敗しました'**
  String get jobDetail_deleteError;

  /// No description provided for @jobDetail_deleteThisJob.
  ///
  /// In ja, this message translates to:
  /// **'この案件を削除'**
  String get jobDetail_deleteThisJob;

  /// No description provided for @jobDetail_favorite.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り'**
  String get jobDetail_favorite;

  /// No description provided for @jobDetail_jobDescription.
  ///
  /// In ja, this message translates to:
  /// **'仕事内容'**
  String get jobDetail_jobDescription;

  /// No description provided for @jobDetail_legacyData.
  ///
  /// In ja, this message translates to:
  /// **'旧データ'**
  String get jobDetail_legacyData;

  /// No description provided for @jobDetail_locationLabel.
  ///
  /// In ja, this message translates to:
  /// **'場所'**
  String get jobDetail_locationLabel;

  /// No description provided for @jobDetail_mayBeDeleted.
  ///
  /// In ja, this message translates to:
  /// **'この案件は削除された可能性があります'**
  String get jobDetail_mayBeDeleted;

  /// No description provided for @jobDetail_newApplication.
  ///
  /// In ja, this message translates to:
  /// **'新しい応募'**
  String get jobDetail_newApplication;

  /// No description provided for @jobDetail_notes.
  ///
  /// In ja, this message translates to:
  /// **'備考・注意事項'**
  String get jobDetail_notes;

  /// No description provided for @jobDetail_paymentLabel.
  ///
  /// In ja, this message translates to:
  /// **'報酬'**
  String get jobDetail_paymentLabel;

  /// No description provided for @jobDetail_removeFromFavorites.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りから削除'**
  String get jobDetail_removeFromFavorites;

  /// No description provided for @jobDetail_scheduleLabel.
  ///
  /// In ja, this message translates to:
  /// **'日程'**
  String get jobDetail_scheduleLabel;

  /// No description provided for @jobDetail_share.
  ///
  /// In ja, this message translates to:
  /// **'共有'**
  String get jobDetail_share;

  /// No description provided for @jobDetail_snackApplied.
  ///
  /// In ja, this message translates to:
  /// **'応募が完了しました'**
  String get jobDetail_snackApplied;

  /// No description provided for @jobDetail_status.
  ///
  /// In ja, this message translates to:
  /// **'ステータス'**
  String get jobDetail_status;

  /// No description provided for @jobDetail_title.
  ///
  /// In ja, this message translates to:
  /// **'案件詳細'**
  String get jobDetail_title;

  /// 案件編集タイトル
  ///
  /// In ja, this message translates to:
  /// **'案件編集'**
  String get jobEditTitle;

  /// No description provided for @jobEdit_dateHint.
  ///
  /// In ja, this message translates to:
  /// **'タップして日付を選択'**
  String get jobEdit_dateHint;

  /// No description provided for @jobEdit_dateLabel.
  ///
  /// In ja, this message translates to:
  /// **'日程'**
  String get jobEdit_dateLabel;

  /// No description provided for @jobEdit_datePickerCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get jobEdit_datePickerCancel;

  /// No description provided for @jobEdit_datePickerConfirm.
  ///
  /// In ja, this message translates to:
  /// **'決定'**
  String get jobEdit_datePickerConfirm;

  /// No description provided for @jobEdit_datePickerHelp.
  ///
  /// In ja, this message translates to:
  /// **'日程を選択'**
  String get jobEdit_datePickerHelp;

  /// No description provided for @jobEdit_descriptionHint.
  ///
  /// In ja, this message translates to:
  /// **'例）現場作業の補助、清掃、資材運搬など'**
  String get jobEdit_descriptionHint;

  /// No description provided for @jobEdit_descriptionLabel.
  ///
  /// In ja, this message translates to:
  /// **'仕事内容'**
  String get jobEdit_descriptionLabel;

  /// No description provided for @jobEdit_hintBody.
  ///
  /// In ja, this message translates to:
  /// **'更新後は一覧に戻ります。日程はカレンダーから選択できます。緯度・経度を設定するとQR出退勤時のGPS検証が有効になります。'**
  String get jobEdit_hintBody;

  /// No description provided for @jobEdit_hintTitle.
  ///
  /// In ja, this message translates to:
  /// **'ヒント'**
  String get jobEdit_hintTitle;

  /// No description provided for @jobEdit_latitudeHint.
  ///
  /// In ja, this message translates to:
  /// **'例）35.6812'**
  String get jobEdit_latitudeHint;

  /// No description provided for @jobEdit_latitudeLabel.
  ///
  /// In ja, this message translates to:
  /// **'緯度（任意）'**
  String get jobEdit_latitudeLabel;

  /// No description provided for @jobEdit_locationHint.
  ///
  /// In ja, this message translates to:
  /// **'例）千葉県千葉市花見川区'**
  String get jobEdit_locationHint;

  /// No description provided for @jobEdit_locationLabel.
  ///
  /// In ja, this message translates to:
  /// **'場所'**
  String get jobEdit_locationLabel;

  /// No description provided for @jobEdit_longitudeHint.
  ///
  /// In ja, this message translates to:
  /// **'例）139.7671'**
  String get jobEdit_longitudeHint;

  /// No description provided for @jobEdit_longitudeLabel.
  ///
  /// In ja, this message translates to:
  /// **'経度（任意）'**
  String get jobEdit_longitudeLabel;

  /// No description provided for @jobEdit_notesHint.
  ///
  /// In ja, this message translates to:
  /// **'例）遅刻厳禁、安全第一、詳細はチャットで確認など'**
  String get jobEdit_notesHint;

  /// No description provided for @jobEdit_notesLabel.
  ///
  /// In ja, this message translates to:
  /// **'注意事項'**
  String get jobEdit_notesLabel;

  /// No description provided for @jobEdit_priceHint.
  ///
  /// In ja, this message translates to:
  /// **'例）30000'**
  String get jobEdit_priceHint;

  /// No description provided for @jobEdit_priceLabel.
  ///
  /// In ja, this message translates to:
  /// **'報酬（円）'**
  String get jobEdit_priceLabel;

  /// No description provided for @jobEdit_sectionSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'案件の情報を更新してください'**
  String get jobEdit_sectionSubtitle;

  /// No description provided for @jobEdit_sectionTitle.
  ///
  /// In ja, this message translates to:
  /// **'編集内容'**
  String get jobEdit_sectionTitle;

  /// No description provided for @jobEdit_snackEmptyFields.
  ///
  /// In ja, this message translates to:
  /// **'未入力の項目があります'**
  String get jobEdit_snackEmptyFields;

  /// No description provided for @jobEdit_snackPriceNumeric.
  ///
  /// In ja, this message translates to:
  /// **'金額は数字で入力してください'**
  String get jobEdit_snackPriceNumeric;

  /// No description provided for @jobEdit_snackSelectDateFromCalendar.
  ///
  /// In ja, this message translates to:
  /// **'日程はカレンダーから選択してください'**
  String get jobEdit_snackSelectDateFromCalendar;

  /// No description provided for @jobEdit_snackUpdateFailed.
  ///
  /// In ja, this message translates to:
  /// **'更新に失敗しました: {error}'**
  String jobEdit_snackUpdateFailed(String error);

  /// No description provided for @jobEdit_title.
  ///
  /// In ja, this message translates to:
  /// **'案件を編集'**
  String get jobEdit_title;

  /// No description provided for @jobEdit_titleHint.
  ///
  /// In ja, this message translates to:
  /// **'例）クロス張替え（1LDK）'**
  String get jobEdit_titleHint;

  /// No description provided for @jobEdit_titleLabel.
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get jobEdit_titleLabel;

  /// No description provided for @jobEdit_updateButton.
  ///
  /// In ja, this message translates to:
  /// **'更新する'**
  String get jobEdit_updateButton;

  /// No description provided for @jobFilter_areaHint.
  ///
  /// In ja, this message translates to:
  /// **'エリアを選択'**
  String get jobFilter_areaHint;

  /// No description provided for @jobFilter_areaLabel.
  ///
  /// In ja, this message translates to:
  /// **'エリア'**
  String get jobFilter_areaLabel;

  /// No description provided for @jobFilter_dateRange.
  ///
  /// In ja, this message translates to:
  /// **'日程'**
  String get jobFilter_dateRange;

  /// No description provided for @jobFilter_dateSeparator.
  ///
  /// In ja, this message translates to:
  /// **'〜'**
  String get jobFilter_dateSeparator;

  /// No description provided for @jobFilter_endDate.
  ///
  /// In ja, this message translates to:
  /// **'終了日'**
  String get jobFilter_endDate;

  /// No description provided for @jobFilter_priceRange.
  ///
  /// In ja, this message translates to:
  /// **'報酬範囲'**
  String get jobFilter_priceRange;

  /// No description provided for @jobFilter_qualBuildingManagement.
  ///
  /// In ja, this message translates to:
  /// **'建築施工管理技士'**
  String get jobFilter_qualBuildingManagement;

  /// No description provided for @jobFilter_qualCivilEngineering.
  ///
  /// In ja, this message translates to:
  /// **'土木施工管理技士'**
  String get jobFilter_qualCivilEngineering;

  /// No description provided for @jobFilter_qualElectrician.
  ///
  /// In ja, this message translates to:
  /// **'電気工事士'**
  String get jobFilter_qualElectrician;

  /// No description provided for @jobFilter_qualForklift.
  ///
  /// In ja, this message translates to:
  /// **'フォークリフト運転者'**
  String get jobFilter_qualForklift;

  /// No description provided for @jobFilter_qualHazmat.
  ///
  /// In ja, this message translates to:
  /// **'危険物取扱者'**
  String get jobFilter_qualHazmat;

  /// No description provided for @jobFilter_qualScaffolding.
  ///
  /// In ja, this message translates to:
  /// **'建築施工管理'**
  String get jobFilter_qualScaffolding;

  /// No description provided for @jobFilter_qualSlinging.
  ///
  /// In ja, this message translates to:
  /// **'玉掛け技能者'**
  String get jobFilter_qualSlinging;

  /// No description provided for @jobFilter_qualWelding.
  ///
  /// In ja, this message translates to:
  /// **'溶接技能者'**
  String get jobFilter_qualWelding;

  /// No description provided for @jobFilter_requiredQualifications.
  ///
  /// In ja, this message translates to:
  /// **'必要資格'**
  String get jobFilter_requiredQualifications;

  /// No description provided for @jobFilter_reset.
  ///
  /// In ja, this message translates to:
  /// **'リセット'**
  String get jobFilter_reset;

  /// No description provided for @jobFilter_searchButton.
  ///
  /// In ja, this message translates to:
  /// **'検索する'**
  String get jobFilter_searchButton;

  /// No description provided for @jobFilter_startDate.
  ///
  /// In ja, this message translates to:
  /// **'開始日'**
  String get jobFilter_startDate;

  /// No description provided for @jobFilter_title.
  ///
  /// In ja, this message translates to:
  /// **'絞り込み検索'**
  String get jobFilter_title;

  /// 仕事一覧ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'仕事一覧'**
  String get jobListTitle;

  /// No description provided for @jobList_dataLoadError.
  ///
  /// In ja, this message translates to:
  /// **'データの読み込みに失敗しました'**
  String get jobList_dataLoadError;

  /// No description provided for @jobList_deleteConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'この案件を削除してよろしいですか？この操作は取り消せません。'**
  String get jobList_deleteConfirmMessage;

  /// No description provided for @jobList_deleteConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'案件を削除'**
  String get jobList_deleteConfirmTitle;

  /// No description provided for @jobList_deleteError.
  ///
  /// In ja, this message translates to:
  /// **'削除に失敗しました'**
  String get jobList_deleteError;

  /// No description provided for @jobList_fetchJobsError.
  ///
  /// In ja, this message translates to:
  /// **'案件情報の取得に失敗しました'**
  String get jobList_fetchJobsError;

  /// No description provided for @jobList_filter.
  ///
  /// In ja, this message translates to:
  /// **'フィルタ'**
  String get jobList_filter;

  /// No description provided for @jobList_filterActiveLabel.
  ///
  /// In ja, this message translates to:
  /// **'フィルタ適用中'**
  String get jobList_filterActiveLabel;

  /// No description provided for @jobList_locationError.
  ///
  /// In ja, this message translates to:
  /// **'位置情報の取得に失敗しました'**
  String get jobList_locationError;

  /// No description provided for @jobList_monthLabel.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get jobList_monthLabel;

  /// No description provided for @jobList_nextMonth.
  ///
  /// In ja, this message translates to:
  /// **'来月'**
  String get jobList_nextMonth;

  /// No description provided for @jobList_noJobs.
  ///
  /// In ja, this message translates to:
  /// **'案件がありません'**
  String get jobList_noJobs;

  /// No description provided for @jobList_noJobsDescription.
  ///
  /// In ja, this message translates to:
  /// **'現在、この条件に該当する案件はありません。'**
  String get jobList_noJobsDescription;

  /// No description provided for @jobList_noMatchingJobs.
  ///
  /// In ja, this message translates to:
  /// **'該当する案件がありません'**
  String get jobList_noMatchingJobs;

  /// No description provided for @jobList_noMatchingJobsDescription.
  ///
  /// In ja, this message translates to:
  /// **'条件を変更して再度検索してください。'**
  String get jobList_noMatchingJobsDescription;

  /// No description provided for @jobList_openSearchFilter.
  ///
  /// In ja, this message translates to:
  /// **'検索フィルタを開く'**
  String get jobList_openSearchFilter;

  /// No description provided for @jobList_prefChiba.
  ///
  /// In ja, this message translates to:
  /// **'千葉県'**
  String get jobList_prefChiba;

  /// No description provided for @jobList_prefKanagawa.
  ///
  /// In ja, this message translates to:
  /// **'神奈川県'**
  String get jobList_prefKanagawa;

  /// No description provided for @jobList_prefOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get jobList_prefOther;

  /// No description provided for @jobList_prefTokyo.
  ///
  /// In ja, this message translates to:
  /// **'東京都'**
  String get jobList_prefTokyo;

  /// No description provided for @jobList_searchByAreaCondition.
  ///
  /// In ja, this message translates to:
  /// **'エリア・条件で検索'**
  String get jobList_searchByAreaCondition;

  /// No description provided for @jobList_sortDistance.
  ///
  /// In ja, this message translates to:
  /// **'距離順'**
  String get jobList_sortDistance;

  /// No description provided for @jobList_sortHighestPay.
  ///
  /// In ja, this message translates to:
  /// **'金額が高い順'**
  String get jobList_sortHighestPay;

  /// No description provided for @jobList_sortNewest.
  ///
  /// In ja, this message translates to:
  /// **'新着順'**
  String get jobList_sortNewest;

  /// No description provided for @jobList_sortTooltip.
  ///
  /// In ja, this message translates to:
  /// **'並べ替え'**
  String get jobList_sortTooltip;

  /// No description provided for @jobList_thisMonth.
  ///
  /// In ja, this message translates to:
  /// **'今月'**
  String get jobList_thisMonth;

  /// No description provided for @jobList_viewOnMap.
  ///
  /// In ja, this message translates to:
  /// **'マップで見る'**
  String get jobList_viewOnMap;

  /// No description provided for @jobList_viewGrid.
  ///
  /// In ja, this message translates to:
  /// **'グリッド表示に切替'**
  String get jobList_viewGrid;

  /// No description provided for @jobList_viewList.
  ///
  /// In ja, this message translates to:
  /// **'リスト表示に切替'**
  String get jobList_viewList;

  /// No description provided for @jobList_viewOnMapAccessibility.
  ///
  /// In ja, this message translates to:
  /// **'地図で案件を見る'**
  String get jobList_viewOnMapAccessibility;

  /// 勤務地ラベル
  ///
  /// In ja, this message translates to:
  /// **'勤務地'**
  String get jobLocation;

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

  /// 報酬ラベル
  ///
  /// In ja, this message translates to:
  /// **'報酬'**
  String get jobPrice;

  /// 案件保存成功
  ///
  /// In ja, this message translates to:
  /// **'案件を保存しました'**
  String get jobSaved;

  /// 案件名ラベル
  ///
  /// In ja, this message translates to:
  /// **'案件名'**
  String get jobTitle;

  /// 労災保険ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'労災保険について'**
  String get laborInsurance;

  /// 法令遵守セクション
  ///
  /// In ja, this message translates to:
  /// **'法令遵守'**
  String get legalCompliance;

  /// 法的ドキュメントセクション
  ///
  /// In ja, this message translates to:
  /// **'法的ドキュメント'**
  String get legalDocuments;

  /// 法的情報ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'法的情報'**
  String get legalIndex;

  /// No description provided for @legalIndex_compliance.
  ///
  /// In ja, this message translates to:
  /// **'法令遵守'**
  String get legalIndex_compliance;

  /// No description provided for @legalIndex_dispatchLaw.
  ///
  /// In ja, this message translates to:
  /// **'労働者派遣法について'**
  String get legalIndex_dispatchLaw;

  /// No description provided for @legalIndex_employmentSecurityLaw.
  ///
  /// In ja, this message translates to:
  /// **'職業安定法について'**
  String get legalIndex_employmentSecurityLaw;

  /// No description provided for @legalIndex_laborInsurance.
  ///
  /// In ja, this message translates to:
  /// **'労災保険について'**
  String get legalIndex_laborInsurance;

  /// No description provided for @legalIndex_legalDocuments.
  ///
  /// In ja, this message translates to:
  /// **'法的ドキュメント'**
  String get legalIndex_legalDocuments;

  /// No description provided for @legalIndex_privacyPolicy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get legalIndex_privacyPolicy;

  /// No description provided for @legalIndex_termsOfService.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get legalIndex_termsOfService;

  /// No description provided for @legalIndex_title.
  ///
  /// In ja, this message translates to:
  /// **'法的情報'**
  String get legalIndex_title;

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

  /// もっと見るボタン
  ///
  /// In ja, this message translates to:
  /// **'もっと見る'**
  String get loadMore;

  /// No description provided for @loadMore_showMore.
  ///
  /// In ja, this message translates to:
  /// **'もっと表示'**
  String get loadMore_showMore;

  /// ローディング表示
  ///
  /// In ja, this message translates to:
  /// **'読み込み中...'**
  String get loading;

  /// 位置情報許可要求
  ///
  /// In ja, this message translates to:
  /// **'位置情報の許可が必要です'**
  String get locationPermissionRequired;

  /// ログインボタン
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get login;

  /// ログイン成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'ログインしました'**
  String get loginSuccess;

  /// ログアウトボタン
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get logout;

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

  /// No description provided for @mapSearch_details.
  ///
  /// In ja, this message translates to:
  /// **'詳細'**
  String get mapSearch_details;

  /// No description provided for @mapSearch_noJobs.
  ///
  /// In ja, this message translates to:
  /// **'地図に表示できる案件がありません'**
  String get mapSearch_noJobs;

  /// No description provided for @mapSearch_noTitle.
  ///
  /// In ja, this message translates to:
  /// **'タイトルなし'**
  String get mapSearch_noTitle;

  /// No description provided for @mapSearch_notSet.
  ///
  /// In ja, this message translates to:
  /// **'タイトルなし'**
  String get mapSearch_notSet;

  /// No description provided for @mapSearch_pricePerDay.
  ///
  /// In ja, this message translates to:
  /// **'¥{price} /日'**
  String mapSearch_pricePerDay(String price);

  /// No description provided for @mapSearch_title.
  ///
  /// In ja, this message translates to:
  /// **'地図で探す'**
  String get mapSearch_title;

  /// 既読マークボタン
  ///
  /// In ja, this message translates to:
  /// **'既読にする'**
  String get markAsRead;

  /// メッセージページタイトル
  ///
  /// In ja, this message translates to:
  /// **'メッセージ'**
  String get messagesTitle;

  /// No description provided for @messages_emptyAdmin.
  ///
  /// In ja, this message translates to:
  /// **'チャットルームはまだありません'**
  String get messages_emptyAdmin;

  /// No description provided for @messages_emptyDescription.
  ///
  /// In ja, this message translates to:
  /// **'案件に応募するとチャットが開始されます'**
  String get messages_emptyDescription;

  /// No description provided for @messages_emptyUser.
  ///
  /// In ja, this message translates to:
  /// **'メッセージはまだありません'**
  String get messages_emptyUser;

  /// No description provided for @messages_featureName.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ'**
  String get messages_featureName;

  /// No description provided for @messages_noSearchResults.
  ///
  /// In ja, this message translates to:
  /// **'検索結果なし'**
  String get messages_noSearchResults;

  /// No description provided for @messages_registrationRequiredDescription.
  ///
  /// In ja, this message translates to:
  /// **'会員登録をして、メッセージ機能をご利用ください。'**
  String get messages_registrationRequiredDescription;

  /// No description provided for @messages_registrationRequiredTitle.
  ///
  /// In ja, this message translates to:
  /// **'メッセージを利用するには会員登録が必要です'**
  String get messages_registrationRequiredTitle;

  /// No description provided for @messages_searchHint.
  ///
  /// In ja, this message translates to:
  /// **'メッセージを検索…'**
  String get messages_searchHint;

  /// No description provided for @messages_statusLabel.
  ///
  /// In ja, this message translates to:
  /// **'ステータス: {status}'**
  String messages_statusLabel(String status);

  /// No description provided for @messages_title.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ'**
  String get messages_title;

  /// No description provided for @messages_titleAdmin.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ（管理者）'**
  String get messages_titleAdmin;

  /// No description provided for @messages_tryDifferentKeyword.
  ///
  /// In ja, this message translates to:
  /// **'別のキーワードで検索してください'**
  String get messages_tryDifferentKeyword;

  /// マイプロフィール
  ///
  /// In ja, this message translates to:
  /// **'プロフィール'**
  String get myProfile;

  /// No description provided for @myProfile_addQualification.
  ///
  /// In ja, this message translates to:
  /// **'資格を追加'**
  String get myProfile_addQualification;

  /// No description provided for @myProfile_addressHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 東京都渋谷区...'**
  String get myProfile_addressHint;

  /// No description provided for @myProfile_addressLabel.
  ///
  /// In ja, this message translates to:
  /// **'住所'**
  String get myProfile_addressLabel;

  /// No description provided for @myProfile_addressSection.
  ///
  /// In ja, this message translates to:
  /// **'住所'**
  String get myProfile_addressSection;

  /// No description provided for @myProfile_adminRating.
  ///
  /// In ja, this message translates to:
  /// **'管理者からの評価'**
  String get myProfile_adminRating;

  /// No description provided for @myProfile_avatarUpdated.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール写真を更新しました'**
  String get myProfile_avatarUpdated;

  /// No description provided for @myProfile_avatarUploadError.
  ///
  /// In ja, this message translates to:
  /// **'写真のアップロードに失敗しました'**
  String get myProfile_avatarUploadError;

  /// No description provided for @myProfile_basicInfo.
  ///
  /// In ja, this message translates to:
  /// **'基本情報'**
  String get myProfile_basicInfo;

  /// No description provided for @myProfile_birthDate.
  ///
  /// In ja, this message translates to:
  /// **'生年月日'**
  String get myProfile_birthDate;

  /// No description provided for @myProfile_birthDateLabel.
  ///
  /// In ja, this message translates to:
  /// **'生年月日'**
  String get myProfile_birthDateLabel;

  /// No description provided for @myProfile_completionRate.
  ///
  /// In ja, this message translates to:
  /// **'完了率'**
  String get myProfile_completionRate;

  /// No description provided for @myProfile_experienceSkills.
  ///
  /// In ja, this message translates to:
  /// **'経験・スキル'**
  String get myProfile_experienceSkills;

  /// No description provided for @myProfile_experienceYearsHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 5'**
  String get myProfile_experienceYearsHint;

  /// No description provided for @myProfile_experienceYearsLabel.
  ///
  /// In ja, this message translates to:
  /// **'経験年数'**
  String get myProfile_experienceYearsLabel;

  /// No description provided for @myProfile_familyName.
  ///
  /// In ja, this message translates to:
  /// **'姓'**
  String get myProfile_familyName;

  /// No description provided for @myProfile_familyNameKana.
  ///
  /// In ja, this message translates to:
  /// **'セイ'**
  String get myProfile_familyNameKana;

  /// No description provided for @myProfile_familyNameKanaLabel.
  ///
  /// In ja, this message translates to:
  /// **'セイ（カナ）'**
  String get myProfile_familyNameKanaLabel;

  /// No description provided for @myProfile_familyNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'姓'**
  String get myProfile_familyNameLabel;

  /// No description provided for @myProfile_genderFemale.
  ///
  /// In ja, this message translates to:
  /// **'女性'**
  String get myProfile_genderFemale;

  /// No description provided for @myProfile_genderLabel.
  ///
  /// In ja, this message translates to:
  /// **'性別'**
  String get myProfile_genderLabel;

  /// No description provided for @myProfile_genderMale.
  ///
  /// In ja, this message translates to:
  /// **'男性'**
  String get myProfile_genderMale;

  /// No description provided for @myProfile_genderNotAnswered.
  ///
  /// In ja, this message translates to:
  /// **'未回答'**
  String get myProfile_genderNotAnswered;

  /// No description provided for @myProfile_genderOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get myProfile_genderOther;

  /// No description provided for @myProfile_genderRequired.
  ///
  /// In ja, this message translates to:
  /// **'性別を選択してください'**
  String get myProfile_genderRequired;

  /// No description provided for @myProfile_givenName.
  ///
  /// In ja, this message translates to:
  /// **'名'**
  String get myProfile_givenName;

  /// No description provided for @myProfile_givenNameKana.
  ///
  /// In ja, this message translates to:
  /// **'メイ'**
  String get myProfile_givenNameKana;

  /// No description provided for @myProfile_givenNameKanaLabel.
  ///
  /// In ja, this message translates to:
  /// **'メイ（カナ）'**
  String get myProfile_givenNameKanaLabel;

  /// No description provided for @myProfile_givenNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'名'**
  String get myProfile_givenNameLabel;

  /// No description provided for @myProfile_identityVerified.
  ///
  /// In ja, this message translates to:
  /// **'本人確認済み'**
  String get myProfile_identityVerified;

  /// No description provided for @myProfile_introHint.
  ///
  /// In ja, this message translates to:
  /// **'得意な作業や経験をアピールしましょう'**
  String get myProfile_introHint;

  /// No description provided for @myProfile_introLabel.
  ///
  /// In ja, this message translates to:
  /// **'自己紹介'**
  String get myProfile_introLabel;

  /// No description provided for @myProfile_loadError.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールの読み込みに失敗しました'**
  String get myProfile_loadError;

  /// No description provided for @myProfile_loginRequired.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get myProfile_loginRequired;

  /// No description provided for @myProfile_loginRequiredMessage.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール編集にはログインが必要です。設定画面からログインしてください。'**
  String get myProfile_loginRequiredMessage;

  /// No description provided for @myProfile_loginRequiredTitle.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get myProfile_loginRequiredTitle;

  /// No description provided for @myProfile_photoSetByVerification.
  ///
  /// In ja, this message translates to:
  /// **'本人確認後に写真が設定されます'**
  String get myProfile_photoSetByVerification;

  /// No description provided for @myProfile_pickFromGallery.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選択'**
  String get myProfile_pickFromGallery;

  /// No description provided for @myProfile_postalCodeHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 123-4567'**
  String get myProfile_postalCodeHint;

  /// No description provided for @myProfile_postalCodeInvalid.
  ///
  /// In ja, this message translates to:
  /// **'郵便番号の形式が正しくありません'**
  String get myProfile_postalCodeInvalid;

  /// No description provided for @myProfile_postalCodeLabel.
  ///
  /// In ja, this message translates to:
  /// **'郵便番号'**
  String get myProfile_postalCodeLabel;

  /// No description provided for @myProfile_profilePhoto.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール写真'**
  String get myProfile_profilePhoto;

  /// No description provided for @myProfile_qualificationHint.
  ///
  /// In ja, this message translates to:
  /// **'資格名を入力'**
  String get myProfile_qualificationHint;

  /// No description provided for @myProfile_qualifications.
  ///
  /// In ja, this message translates to:
  /// **'資格'**
  String get myProfile_qualifications;

  /// No description provided for @myProfile_qualityScore.
  ///
  /// In ja, this message translates to:
  /// **'品質スコア'**
  String get myProfile_qualityScore;

  /// No description provided for @myProfile_ratingAverage.
  ///
  /// In ja, this message translates to:
  /// **'評価平均'**
  String get myProfile_ratingAverage;

  /// No description provided for @myProfile_requiredField.
  ///
  /// In ja, this message translates to:
  /// **'{label}は必須です'**
  String myProfile_requiredField(String label);

  /// No description provided for @myProfile_saveButton.
  ///
  /// In ja, this message translates to:
  /// **'保存する'**
  String get myProfile_saveButton;

  /// No description provided for @myProfile_saveError.
  ///
  /// In ja, this message translates to:
  /// **'保存に失敗しました'**
  String get myProfile_saveError;

  /// No description provided for @myProfile_saveSuccess.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを保存しました'**
  String get myProfile_saveSuccess;

  /// No description provided for @myProfile_selectBirthDate.
  ///
  /// In ja, this message translates to:
  /// **'生年月日を選択'**
  String get myProfile_selectBirthDate;

  /// No description provided for @myProfile_selectGender.
  ///
  /// In ja, this message translates to:
  /// **'性別を選択してください'**
  String get myProfile_selectGender;

  /// No description provided for @myProfile_stripeActive.
  ///
  /// In ja, this message translates to:
  /// **'Stripe連携済み — 報酬の受け取りが可能です'**
  String get myProfile_stripeActive;

  /// No description provided for @myProfile_stripeIntegration.
  ///
  /// In ja, this message translates to:
  /// **'Stripe連携'**
  String get myProfile_stripeIntegration;

  /// No description provided for @myProfile_stripeNotConfigured.
  ///
  /// In ja, this message translates to:
  /// **'Stripe未設定 — 報酬の受け取りにはStripe連携が必要です'**
  String get myProfile_stripeNotConfigured;

  /// No description provided for @myProfile_stripePending.
  ///
  /// In ja, this message translates to:
  /// **'Stripe審査中 — 確認が完了するまでお待ちください'**
  String get myProfile_stripePending;

  /// No description provided for @myProfile_takePhoto.
  ///
  /// In ja, this message translates to:
  /// **'写真を撮る'**
  String get myProfile_takePhoto;

  /// No description provided for @myProfile_tapToChangePhoto.
  ///
  /// In ja, this message translates to:
  /// **'タップして写真を変更'**
  String get myProfile_tapToChangePhoto;

  /// No description provided for @myProfile_title.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール編集'**
  String get myProfile_title;

  /// No description provided for @myProfile_verifiedQualifications.
  ///
  /// In ja, this message translates to:
  /// **'認定資格'**
  String get myProfile_verifiedQualifications;

  /// No description provided for @myProfile_yearsSuffix.
  ///
  /// In ja, this message translates to:
  /// **'年'**
  String get myProfile_yearsSuffix;

  /// No description provided for @myProfile_yourRating.
  ///
  /// In ja, this message translates to:
  /// **'あなたの評価'**
  String get myProfile_yourRating;

  /// 氏名ラベル
  ///
  /// In ja, this message translates to:
  /// **'氏名'**
  String get name;

  /// 名前変更成功
  ///
  /// In ja, this message translates to:
  /// **'名前を変更しました'**
  String get nameChanged;

  /// BottomNavigation: ホーム
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get navHome;

  /// BottomNavigation: メッセージ
  ///
  /// In ja, this message translates to:
  /// **'メッセージ'**
  String get navMessages;

  /// BottomNavigation: マイページ
  ///
  /// In ja, this message translates to:
  /// **'マイページ'**
  String get navMyPage;

  /// BottomNavigation: プロフィール
  ///
  /// In ja, this message translates to:
  /// **'プロフィール'**
  String get navProfile;

  /// BottomNavigation: 売上
  ///
  /// In ja, this message translates to:
  /// **'売上'**
  String get navSales;

  /// BottomNavigation: 検索
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get navSearch;

  /// BottomNavigation: 仕事
  ///
  /// In ja, this message translates to:
  /// **'仕事'**
  String get navWork;

  /// 振込金額ラベル
  ///
  /// In ja, this message translates to:
  /// **'振込金額'**
  String get netAmount;

  /// ネットワーク確認メッセージ
  ///
  /// In ja, this message translates to:
  /// **'ネットワーク接続を確認してください'**
  String get networkCheckConnection;

  /// 新しいパスワードラベル
  ///
  /// In ja, this message translates to:
  /// **'新しいパスワード'**
  String get newPassword;

  /// オンボーディング: 次へ
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get next;

  /// データなし表示
  ///
  /// In ja, this message translates to:
  /// **'データがありません'**
  String get noData;

  /// 売上なしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'売上データがありません'**
  String get noEarnings;

  /// 仕事なしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'条件に合う仕事が見つかりません'**
  String get noJobsFound;

  /// メッセージなし
  ///
  /// In ja, this message translates to:
  /// **'メッセージはありません'**
  String get noMessages;

  /// 追加データなし
  ///
  /// In ja, this message translates to:
  /// **'これ以上データはありません'**
  String get noMoreData;

  /// 通知なしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'お知らせはありません'**
  String get noNotifications;

  /// 仕事なしメッセージ
  ///
  /// In ja, this message translates to:
  /// **'現在の仕事はありません'**
  String get noWork;

  /// 通知設定セクション
  ///
  /// In ja, this message translates to:
  /// **'通知設定'**
  String get notificationSettings;

  /// お知らせタイトル
  ///
  /// In ja, this message translates to:
  /// **'お知らせ'**
  String get notifications;

  /// No description provided for @notifications_allRead.
  ///
  /// In ja, this message translates to:
  /// **'すべて既読にしました'**
  String get notifications_allRead;

  /// No description provided for @notifications_empty.
  ///
  /// In ja, this message translates to:
  /// **'お知らせはまだありません'**
  String get notifications_empty;

  /// No description provided for @notifications_emptyDescription.
  ///
  /// In ja, this message translates to:
  /// **'お知らせはまだありません'**
  String get notifications_emptyDescription;

  /// No description provided for @notifications_error.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {error}'**
  String notifications_error(String error);

  /// No description provided for @notifications_loginDescription.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get notifications_loginDescription;

  /// No description provided for @notifications_loginRequired.
  ///
  /// In ja, this message translates to:
  /// **'お知らせ'**
  String get notifications_loginRequired;

  /// No description provided for @notifications_markAllRead.
  ///
  /// In ja, this message translates to:
  /// **'すべて既読にしました'**
  String get notifications_markAllRead;

  /// No description provided for @notifications_title.
  ///
  /// In ja, this message translates to:
  /// **'お知らせ'**
  String get notifications_title;

  /// No description provided for @offlineBanner_connectionRestored.
  ///
  /// In ja, this message translates to:
  /// **'接続が復旧しました'**
  String get offlineBanner_connectionRestored;

  /// No description provided for @offlineBanner_offlineMode.
  ///
  /// In ja, this message translates to:
  /// **'オフラインモード — キャッシュデータを表示中'**
  String get offlineBanner_offlineMode;

  /// No description provided for @offlineBanner_retry.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get offlineBanner_retry;

  /// オンボーディング1説明
  ///
  /// In ja, this message translates to:
  /// **'建設業界の仕事を簡単に検索・応募できます'**
  String get onboardingDesc1;

  /// オンボーディング2説明
  ///
  /// In ja, this message translates to:
  /// **'QRコードをスキャンして簡単に出退勤管理'**
  String get onboardingDesc2;

  /// オンボーディング3説明
  ///
  /// In ja, this message translates to:
  /// **'Stripe決済で安全・確実に報酬を受け取れます'**
  String get onboardingDesc3;

  /// オンボーディング1タイトル
  ///
  /// In ja, this message translates to:
  /// **'仕事を見つけよう'**
  String get onboardingTitle1;

  /// オンボーディング2タイトル
  ///
  /// In ja, this message translates to:
  /// **'QRで出退勤'**
  String get onboardingTitle2;

  /// オンボーディング3タイトル
  ///
  /// In ja, this message translates to:
  /// **'安心の支払い'**
  String get onboardingTitle3;

  /// No description provided for @onboarding_agreed.
  ///
  /// In ja, this message translates to:
  /// **'、同意済み'**
  String get onboarding_agreed;

  /// No description provided for @onboarding_getStarted.
  ///
  /// In ja, this message translates to:
  /// **'アプリを始める'**
  String get onboarding_getStarted;

  /// No description provided for @onboarding_nextPage.
  ///
  /// In ja, this message translates to:
  /// **'アプリを始める'**
  String get onboarding_nextPage;

  /// No description provided for @onboarding_pageIndicator.
  ///
  /// In ja, this message translates to:
  /// **'ページ{current} / {total}'**
  String onboarding_pageIndicator(String current, String total);

  /// No description provided for @onboarding_privacyPolicy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get onboarding_privacyPolicy;

  /// No description provided for @onboarding_skip.
  ///
  /// In ja, this message translates to:
  /// **'オンボーディングをスキップ'**
  String get onboarding_skip;

  /// No description provided for @onboarding_termsOfService.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get onboarding_termsOfService;

  /// 設定を開くボタン
  ///
  /// In ja, this message translates to:
  /// **'設定を開く'**
  String get openSettings;

  /// 任意ラベル
  ///
  /// In ja, this message translates to:
  /// **'任意'**
  String get optional;

  /// パスワードラベル
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get password;

  /// パスワード変更成功
  ///
  /// In ja, this message translates to:
  /// **'パスワードを変更しました'**
  String get passwordChanged;

  /// パスワードリセット説明
  ///
  /// In ja, this message translates to:
  /// **'登録されたメールアドレスにリセットリンクを送信します'**
  String get passwordResetDescription;

  /// パスワードリセットメール送信
  ///
  /// In ja, this message translates to:
  /// **'パスワードリセットメールを送信しました'**
  String get passwordResetSent;

  /// パスワードリセットタイトル
  ///
  /// In ja, this message translates to:
  /// **'パスワードリセット'**
  String get passwordResetTitle;

  /// 決済詳細タイトル
  ///
  /// In ja, this message translates to:
  /// **'決済詳細'**
  String get paymentDetail;

  /// No description provided for @paymentDetail_createdAt.
  ///
  /// In ja, this message translates to:
  /// **'作成日時'**
  String get paymentDetail_createdAt;

  /// No description provided for @paymentDetail_netAmount.
  ///
  /// In ja, this message translates to:
  /// **'支払い金額'**
  String get paymentDetail_netAmount;

  /// No description provided for @paymentDetail_notFound.
  ///
  /// In ja, this message translates to:
  /// **'支払い情報が見つかりません'**
  String get paymentDetail_notFound;

  /// No description provided for @paymentDetail_paymentAmount.
  ///
  /// In ja, this message translates to:
  /// **'案件名'**
  String get paymentDetail_paymentAmount;

  /// No description provided for @paymentDetail_paymentStatus.
  ///
  /// In ja, this message translates to:
  /// **'受取金額'**
  String get paymentDetail_paymentStatus;

  /// No description provided for @paymentDetail_payoutStatus.
  ///
  /// In ja, this message translates to:
  /// **'決済ステータス'**
  String get paymentDetail_payoutStatus;

  /// No description provided for @paymentDetail_platformFee.
  ///
  /// In ja, this message translates to:
  /// **'支払い金額'**
  String get paymentDetail_platformFee;

  /// No description provided for @paymentDetail_projectName.
  ///
  /// In ja, this message translates to:
  /// **'案件名'**
  String get paymentDetail_projectName;

  /// No description provided for @paymentDetail_title.
  ///
  /// In ja, this message translates to:
  /// **'支払い詳細'**
  String get paymentDetail_title;

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

  /// 支払い日ラベル
  ///
  /// In ja, this message translates to:
  /// **'支払い日'**
  String get payoutDate;

  /// 電話番号ラベル
  ///
  /// In ja, this message translates to:
  /// **'電話番号'**
  String get phone;

  /// No description provided for @phoneAuth_changePhoneNumber.
  ///
  /// In ja, this message translates to:
  /// **'電話番号を変更する'**
  String get phoneAuth_changePhoneNumber;

  /// No description provided for @phoneAuth_codeSentTo.
  ///
  /// In ja, this message translates to:
  /// **'{phone} に送信された6桁のコードを入力してください'**
  String phoneAuth_codeSentTo(String phone);

  /// No description provided for @phoneAuth_enterCode.
  ///
  /// In ja, this message translates to:
  /// **'認証コードを入力'**
  String get phoneAuth_enterCode;

  /// No description provided for @phoneAuth_enterJapaneseNumber.
  ///
  /// In ja, this message translates to:
  /// **'日本の電話番号を入力してください'**
  String get phoneAuth_enterJapaneseNumber;

  /// No description provided for @phoneAuth_enterSixDigitCode.
  ///
  /// In ja, this message translates to:
  /// **'6桁のコードを入力してください'**
  String get phoneAuth_enterSixDigitCode;

  /// No description provided for @phoneAuth_invalidPhoneNumber.
  ///
  /// In ja, this message translates to:
  /// **'有効な電話番号を入力してください（10〜11桁）'**
  String get phoneAuth_invalidPhoneNumber;

  /// No description provided for @phoneAuth_login.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get phoneAuth_login;

  /// No description provided for @phoneAuth_loginSuccess.
  ///
  /// In ja, this message translates to:
  /// **'ログインしました'**
  String get phoneAuth_loginSuccess;

  /// No description provided for @phoneAuth_phoneNumberLabel.
  ///
  /// In ja, this message translates to:
  /// **'電話番号'**
  String get phoneAuth_phoneNumberLabel;

  /// No description provided for @phoneAuth_resendCode.
  ///
  /// In ja, this message translates to:
  /// **'コードを再送信'**
  String get phoneAuth_resendCode;

  /// No description provided for @phoneAuth_resendCountdown.
  ///
  /// In ja, this message translates to:
  /// **'再送信まで {seconds}秒'**
  String phoneAuth_resendCountdown(String seconds);

  /// No description provided for @phoneAuth_restartVerification.
  ///
  /// In ja, this message translates to:
  /// **'認証コードの送信からやり直してください'**
  String get phoneAuth_restartVerification;

  /// No description provided for @phoneAuth_sendCode.
  ///
  /// In ja, this message translates to:
  /// **'認証コードを送信'**
  String get phoneAuth_sendCode;

  /// No description provided for @phoneAuth_smsDescription.
  ///
  /// In ja, this message translates to:
  /// **'SMSで認証コードを送信します'**
  String get phoneAuth_smsDescription;

  /// No description provided for @phoneAuth_title.
  ///
  /// In ja, this message translates to:
  /// **'電話番号でログイン'**
  String get phoneAuth_title;

  /// No description provided for @phoneAuth_verificationCodeLabel.
  ///
  /// In ja, this message translates to:
  /// **'認証コード'**
  String get phoneAuth_verificationCodeLabel;

  /// 手数料ラベル
  ///
  /// In ja, this message translates to:
  /// **'プラットフォーム手数料'**
  String get platformFee;

  /// 案件投稿ボタン
  ///
  /// In ja, this message translates to:
  /// **'案件を投稿'**
  String get postJob;

  /// 案件投稿成功
  ///
  /// In ja, this message translates to:
  /// **'案件を投稿しました'**
  String get postJobSuccess;

  /// 案件投稿ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'案件を投稿'**
  String get postJobTitle;

  /// No description provided for @post_dateHint.
  ///
  /// In ja, this message translates to:
  /// **'タップして日付を選択'**
  String get post_dateHint;

  /// No description provided for @post_dateLabel.
  ///
  /// In ja, this message translates to:
  /// **'日程'**
  String get post_dateLabel;

  /// No description provided for @post_datePickerCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get post_datePickerCancel;

  /// No description provided for @post_datePickerConfirm.
  ///
  /// In ja, this message translates to:
  /// **'決定'**
  String get post_datePickerConfirm;

  /// No description provided for @post_datePickerHelp.
  ///
  /// In ja, this message translates to:
  /// **'日程を選択'**
  String get post_datePickerHelp;

  /// No description provided for @post_hintBody.
  ///
  /// In ja, this message translates to:
  /// **'日程はカレンダーから選択できます。緯度・経度を入力するとQR出退勤時にGPS検証が有効になります。'**
  String get post_hintBody;

  /// No description provided for @post_hintTitle.
  ///
  /// In ja, this message translates to:
  /// **'ヒント'**
  String get post_hintTitle;

  /// No description provided for @post_latitudeHint.
  ///
  /// In ja, this message translates to:
  /// **'例）35.6812'**
  String get post_latitudeHint;

  /// No description provided for @post_latitudeLabel.
  ///
  /// In ja, this message translates to:
  /// **'緯度（任意）'**
  String get post_latitudeLabel;

  /// No description provided for @post_locationHint.
  ///
  /// In ja, this message translates to:
  /// **'例）千葉県千葉市花見川区'**
  String get post_locationHint;

  /// No description provided for @post_locationLabel.
  ///
  /// In ja, this message translates to:
  /// **'場所'**
  String get post_locationLabel;

  /// No description provided for @post_longitudeHint.
  ///
  /// In ja, this message translates to:
  /// **'例）139.7671'**
  String get post_longitudeHint;

  /// No description provided for @post_longitudeLabel.
  ///
  /// In ja, this message translates to:
  /// **'経度（任意）'**
  String get post_longitudeLabel;

  /// No description provided for @post_noPermissionMessage.
  ///
  /// In ja, this message translates to:
  /// **'この画面は管理者のみ利用できます。'**
  String get post_noPermissionMessage;

  /// No description provided for @post_noPermissionTitle.
  ///
  /// In ja, this message translates to:
  /// **'権限がありません'**
  String get post_noPermissionTitle;

  /// No description provided for @post_priceHint.
  ///
  /// In ja, this message translates to:
  /// **'例）30000'**
  String get post_priceHint;

  /// No description provided for @post_priceLabel.
  ///
  /// In ja, this message translates to:
  /// **'報酬（円）'**
  String get post_priceLabel;

  /// No description provided for @post_sectionBasicInfo.
  ///
  /// In ja, this message translates to:
  /// **'基本情報'**
  String get post_sectionBasicInfo;

  /// No description provided for @post_sectionBasicInfoSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'案件の内容を入力してください'**
  String get post_sectionBasicInfoSubtitle;

  /// No description provided for @post_snackAdminOnly.
  ///
  /// In ja, this message translates to:
  /// **'管理者のみ投稿できます'**
  String get post_snackAdminOnly;

  /// No description provided for @post_snackCheckingPermission.
  ///
  /// In ja, this message translates to:
  /// **'権限確認中です。少し待ってください。'**
  String get post_snackCheckingPermission;

  /// No description provided for @post_snackEmptyFields.
  ///
  /// In ja, this message translates to:
  /// **'未入力の項目があります'**
  String get post_snackEmptyFields;

  /// No description provided for @post_snackLoginRequired.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get post_snackLoginRequired;

  /// No description provided for @post_snackPostFailed.
  ///
  /// In ja, this message translates to:
  /// **'投稿失敗: {error}'**
  String post_snackPostFailed(String error);

  /// No description provided for @post_snackPriceNumeric.
  ///
  /// In ja, this message translates to:
  /// **'金額は数字で入力してください'**
  String get post_snackPriceNumeric;

  /// No description provided for @post_snackSelectDateFromCalendar.
  ///
  /// In ja, this message translates to:
  /// **'日程はカレンダーから選択してください'**
  String get post_snackSelectDateFromCalendar;

  /// No description provided for @post_submitButton.
  ///
  /// In ja, this message translates to:
  /// **'投稿する'**
  String get post_submitButton;

  /// No description provided for @post_title.
  ///
  /// In ja, this message translates to:
  /// **'案件を投稿'**
  String get post_title;

  /// No description provided for @post_titleHint.
  ///
  /// In ja, this message translates to:
  /// **'例）クロス張替え（1LDK）'**
  String get post_titleHint;

  /// No description provided for @post_titleLabel.
  ///
  /// In ja, this message translates to:
  /// **'タイトル'**
  String get post_titleLabel;

  /// 郵便番号ラベル
  ///
  /// In ja, this message translates to:
  /// **'郵便番号'**
  String get postalCode;

  /// 都道府県ラベル
  ///
  /// In ja, this message translates to:
  /// **'都道府県'**
  String get prefecture;

  /// プライバシーポリシーリンク
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get privacyPolicy;

  /// プロフィール写真変更
  ///
  /// In ja, this message translates to:
  /// **'写真を変更'**
  String get profilePhotoChange;

  /// プロフィール保存成功
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを保存しました'**
  String get profileSaved;

  /// マイページタイトル
  ///
  /// In ja, this message translates to:
  /// **'マイページ'**
  String get profileTitle;

  /// No description provided for @profileWidgets_guest.
  ///
  /// In ja, this message translates to:
  /// **'Guest'**
  String get profileWidgets_guest;

  /// No description provided for @profileWidgets_loggedIn.
  ///
  /// In ja, this message translates to:
  /// **'Logged in'**
  String get profileWidgets_loggedIn;

  /// No description provided for @profileWidgets_status.
  ///
  /// In ja, this message translates to:
  /// **'Status'**
  String get profileWidgets_status;

  /// No description provided for @profile_accountSettings.
  ///
  /// In ja, this message translates to:
  /// **'アカウント設定'**
  String get profile_accountSettings;

  /// No description provided for @profile_adminLogin.
  ///
  /// In ja, this message translates to:
  /// **'管理者ログイン'**
  String get profile_adminLogin;

  /// No description provided for @profile_adminLoginSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'案件の投稿・編集ができます'**
  String get profile_adminLoginSubtitle;

  /// No description provided for @profile_adminLogout.
  ///
  /// In ja, this message translates to:
  /// **'管理者ログアウト'**
  String get profile_adminLogout;

  /// No description provided for @profile_adminLogoutSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'現在ログインしていません'**
  String get profile_adminLogoutSubtitle;

  /// No description provided for @profile_contact.
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ'**
  String get profile_contact;

  /// No description provided for @profile_darkMode.
  ///
  /// In ja, this message translates to:
  /// **'ダークモード'**
  String get profile_darkMode;

  /// No description provided for @profile_darkModeDescription.
  ///
  /// In ja, this message translates to:
  /// **'ダークモードはお使いの端末のシステム設定に連動しています。\\n\\n'**
  String get profile_darkModeDescription;

  /// No description provided for @profile_darkModeSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'システム設定に従う'**
  String get profile_darkModeSubtitle;

  /// No description provided for @profile_darkModeLight.
  ///
  /// In ja, this message translates to:
  /// **'ライト'**
  String get profile_darkModeLight;

  /// No description provided for @profile_darkModeDark.
  ///
  /// In ja, this message translates to:
  /// **'ダーク'**
  String get profile_darkModeDark;

  /// No description provided for @profile_darkModeSystem.
  ///
  /// In ja, this message translates to:
  /// **'システム設定に従う'**
  String get profile_darkModeSystem;

  /// No description provided for @profile_faq.
  ///
  /// In ja, this message translates to:
  /// **'よくある質問'**
  String get profile_faq;

  /// No description provided for @profile_favoriteJobs.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り案件'**
  String get profile_favoriteJobs;

  /// No description provided for @profile_favoriteJobsSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'保存した案件を確認'**
  String get profile_favoriteJobsSubtitle;

  /// No description provided for @profile_guest.
  ///
  /// In ja, this message translates to:
  /// **'ゲスト'**
  String get profile_guest;

  /// No description provided for @profile_identityVerification.
  ///
  /// In ja, this message translates to:
  /// **'本人確認'**
  String get profile_identityVerification;

  /// No description provided for @profile_identityVerificationSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'身分証明書と顔写真を提出'**
  String get profile_identityVerificationSubtitle;

  /// No description provided for @profile_inviteFriends.
  ///
  /// In ja, this message translates to:
  /// **'友達を招待'**
  String get profile_inviteFriends;

  /// No description provided for @profile_inviteFriendsSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'紹介コードで友達を招待'**
  String get profile_inviteFriendsSubtitle;

  /// No description provided for @profile_legalInfo.
  ///
  /// In ja, this message translates to:
  /// **'法的情報'**
  String get profile_legalInfo;

  /// No description provided for @profile_legalInfoSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー・利用規約・法令情報'**
  String get profile_legalInfoSubtitle;

  /// No description provided for @profile_lineLoginButton.
  ///
  /// In ja, this message translates to:
  /// **'LINEでログイン'**
  String get profile_lineLoginButton;

  /// No description provided for @profile_lineLoginSemanticsLabel.
  ///
  /// In ja, this message translates to:
  /// **'LINEアカウントでログインする'**
  String get profile_lineLoginSemanticsLabel;

  /// No description provided for @profile_loggedIn.
  ///
  /// In ja, this message translates to:
  /// **'ログインすると応募・チャットが使えます'**
  String get profile_loggedIn;

  /// No description provided for @profile_loggedInUser.
  ///
  /// In ja, this message translates to:
  /// **'ログインユーザー'**
  String get profile_loggedInUser;

  /// No description provided for @profile_loginButton.
  ///
  /// In ja, this message translates to:
  /// **'ログインする'**
  String get profile_loginButton;

  /// No description provided for @profile_loginPromptSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'ログインすると応募・チャットが使えます'**
  String get profile_loginPromptSubtitle;

  /// No description provided for @profile_loginRequired.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get profile_loginRequired;

  /// No description provided for @profile_loginRequiredMessage.
  ///
  /// In ja, this message translates to:
  /// **'応募・チャットなど一部機能を利用するにはログインが必要です。'**
  String get profile_loginRequiredMessage;

  /// No description provided for @profile_notLoggedIn.
  ///
  /// In ja, this message translates to:
  /// **'現在ログインしていません'**
  String get profile_notLoggedIn;

  /// No description provided for @profile_qualifications.
  ///
  /// In ja, this message translates to:
  /// **'資格管理'**
  String get profile_qualifications;

  /// No description provided for @profile_qualificationsSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'保有資格の登録・確認'**
  String get profile_qualificationsSubtitle;

  /// No description provided for @profile_sectionAccount.
  ///
  /// In ja, this message translates to:
  /// **'アカウント'**
  String get profile_sectionAccount;

  /// No description provided for @profile_sectionAdmin.
  ///
  /// In ja, this message translates to:
  /// **'管理者'**
  String get profile_sectionAdmin;

  /// No description provided for @profile_sectionOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get profile_sectionOther;

  /// No description provided for @profile_sectionSupport.
  ///
  /// In ja, this message translates to:
  /// **'サポート'**
  String get profile_sectionSupport;

  /// No description provided for @profile_snackLoggedOut.
  ///
  /// In ja, this message translates to:
  /// **'ログアウトしました（ゲストに戻りました）'**
  String get profile_snackLoggedOut;

  /// No description provided for @profile_stripeAccount.
  ///
  /// In ja, this message translates to:
  /// **'Stripe口座設定'**
  String get profile_stripeAccount;

  /// No description provided for @profile_stripeAccountSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'報酬の受取口座を設定'**
  String get profile_stripeAccountSubtitle;

  /// No description provided for @profile_yourProfile.
  ///
  /// In ja, this message translates to:
  /// **'あなたのプロフィール'**
  String get profile_yourProfile;

  /// プロジェクト名
  ///
  /// In ja, this message translates to:
  /// **'案件名'**
  String get projectName;

  /// QR出勤タイトル
  ///
  /// In ja, this message translates to:
  /// **'QR出勤'**
  String get qrCheckIn;

  /// No description provided for @qrCheckin_clockIn.
  ///
  /// In ja, this message translates to:
  /// **'退勤'**
  String get qrCheckin_clockIn;

  /// No description provided for @qrCheckin_clockOut.
  ///
  /// In ja, this message translates to:
  /// **'退勤'**
  String get qrCheckin_clockOut;

  /// No description provided for @qrCheckin_error.
  ///
  /// In ja, this message translates to:
  /// **'エラー'**
  String get qrCheckin_error;

  /// No description provided for @qrCheckin_errorOccurred.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました: {error}'**
  String qrCheckin_errorOccurred(String error);

  /// No description provided for @qrCheckin_gpsVerification.
  ///
  /// In ja, this message translates to:
  /// **'GPS検証: 現場から100m以内で{action}できます'**
  String qrCheckin_gpsVerification(String action);

  /// No description provided for @qrCheckin_scanAdminQr.
  ///
  /// In ja, this message translates to:
  /// **'管理者のQRコードをスキャンしてください'**
  String get qrCheckin_scanAdminQr;

  /// No description provided for @qrCheckin_title.
  ///
  /// In ja, this message translates to:
  /// **'QRスキャン（{action}）'**
  String qrCheckin_title(String action);

  /// No description provided for @qualificationAdd_categoryLabel.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ *'**
  String get qualificationAdd_categoryLabel;

  /// No description provided for @qualificationAdd_expiryDate.
  ///
  /// In ja, this message translates to:
  /// **'有効期限'**
  String get qualificationAdd_expiryDate;

  /// No description provided for @qualificationAdd_nameHint.
  ///
  /// In ja, this message translates to:
  /// **'資格名 *'**
  String get qualificationAdd_nameHint;

  /// No description provided for @qualificationAdd_nameLabel.
  ///
  /// In ja, this message translates to:
  /// **'資格名 *'**
  String get qualificationAdd_nameLabel;

  /// No description provided for @qualificationAdd_nameRequired.
  ///
  /// In ja, this message translates to:
  /// **'資格名を入力してください'**
  String get qualificationAdd_nameRequired;

  /// No description provided for @qualificationAdd_noExpiry.
  ///
  /// In ja, this message translates to:
  /// **'有効期限'**
  String get qualificationAdd_noExpiry;

  /// No description provided for @qualificationAdd_register.
  ///
  /// In ja, this message translates to:
  /// **'資格を登録しました（審査待ち）'**
  String get qualificationAdd_register;

  /// No description provided for @qualificationAdd_registerFailed.
  ///
  /// In ja, this message translates to:
  /// **'登録に失敗: {error}'**
  String qualificationAdd_registerFailed(String error);

  /// No description provided for @qualificationAdd_registered.
  ///
  /// In ja, this message translates to:
  /// **'資格を登録しました（審査待ち）'**
  String get qualificationAdd_registered;

  /// No description provided for @qualificationAdd_title.
  ///
  /// In ja, this message translates to:
  /// **'資格を追加'**
  String get qualificationAdd_title;

  /// 資格ラベル
  ///
  /// In ja, this message translates to:
  /// **'資格'**
  String get qualifications;

  /// No description provided for @qualifications_addHint.
  ///
  /// In ja, this message translates to:
  /// **'登録された資格はありません'**
  String get qualifications_addHint;

  /// No description provided for @qualifications_approved.
  ///
  /// In ja, this message translates to:
  /// **'承認済み'**
  String get qualifications_approved;

  /// No description provided for @qualifications_empty.
  ///
  /// In ja, this message translates to:
  /// **'登録された資格はありません'**
  String get qualifications_empty;

  /// No description provided for @qualifications_error.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {error}'**
  String qualifications_error(String error);

  /// No description provided for @qualifications_expired.
  ///
  /// In ja, this message translates to:
  /// **'（期限切れ）'**
  String get qualifications_expired;

  /// No description provided for @qualifications_expiryDate.
  ///
  /// In ja, this message translates to:
  /// **'有効期限: {date}{status}'**
  String qualifications_expiryDate(String date, String status);

  /// No description provided for @qualifications_loginRequired.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get qualifications_loginRequired;

  /// No description provided for @qualifications_pending.
  ///
  /// In ja, this message translates to:
  /// **'承認済み'**
  String get qualifications_pending;

  /// No description provided for @qualifications_rejected.
  ///
  /// In ja, this message translates to:
  /// **'審査中'**
  String get qualifications_rejected;

  /// No description provided for @qualifications_title.
  ///
  /// In ja, this message translates to:
  /// **'資格管理'**
  String get qualifications_title;

  /// No description provided for @ratingDialog_average.
  ///
  /// In ja, this message translates to:
  /// **'不満'**
  String get ratingDialog_average;

  /// No description provided for @ratingDialog_commentHint.
  ///
  /// In ja, this message translates to:
  /// **'コメント（任意）'**
  String get ratingDialog_commentHint;

  /// No description provided for @ratingDialog_dissatisfied.
  ///
  /// In ja, this message translates to:
  /// **'不満'**
  String get ratingDialog_dissatisfied;

  /// No description provided for @ratingDialog_excellent.
  ///
  /// In ja, this message translates to:
  /// **'コメント（任意）'**
  String get ratingDialog_excellent;

  /// No description provided for @ratingDialog_good.
  ///
  /// In ja, this message translates to:
  /// **'コメント（任意）'**
  String get ratingDialog_good;

  /// No description provided for @ratingDialog_later.
  ///
  /// In ja, this message translates to:
  /// **'後で'**
  String get ratingDialog_later;

  /// No description provided for @ratingDialog_selectStars.
  ///
  /// In ja, this message translates to:
  /// **'星を選択してください'**
  String get ratingDialog_selectStars;

  /// No description provided for @ratingDialog_somewhatDissatisfied.
  ///
  /// In ja, this message translates to:
  /// **'不満'**
  String get ratingDialog_somewhatDissatisfied;

  /// No description provided for @ratingDialog_submit.
  ///
  /// In ja, this message translates to:
  /// **'評価を送信しました'**
  String get ratingDialog_submit;

  /// No description provided for @ratingDialog_submitFailed.
  ///
  /// In ja, this message translates to:
  /// **'送信に失敗しました: {error}'**
  String ratingDialog_submitFailed(String error);

  /// No description provided for @ratingDialog_submitSuccess.
  ///
  /// In ja, this message translates to:
  /// **'評価を送信しました'**
  String get ratingDialog_submitSuccess;

  /// No description provided for @ratingDialog_title.
  ///
  /// In ja, this message translates to:
  /// **'お仕事の評価'**
  String get ratingDialog_title;

  /// 評価ラベル
  ///
  /// In ja, this message translates to:
  /// **'評価'**
  String get ratingLabel;

  /// No description provided for @ratingStars_count.
  ///
  /// In ja, this message translates to:
  /// **'({count}件)'**
  String ratingStars_count(String count);

  /// No description provided for @ratingStars_noRating.
  ///
  /// In ja, this message translates to:
  /// **'評価なし'**
  String get ratingStars_noRating;

  /// 通知設定トグル
  ///
  /// In ja, this message translates to:
  /// **'お知らせ通知を受け取る'**
  String get receiveNotifications;

  /// No description provided for @referral_applyButton.
  ///
  /// In ja, this message translates to:
  /// **'適用する'**
  String get referral_applyButton;

  /// No description provided for @referral_codeApplied.
  ///
  /// In ja, this message translates to:
  /// **'紹介コードを適用しました'**
  String get referral_codeApplied;

  /// No description provided for @referral_codeCopied.
  ///
  /// In ja, this message translates to:
  /// **'コードをコピーしました'**
  String get referral_codeCopied;

  /// No description provided for @referral_codeHint.
  ///
  /// In ja, this message translates to:
  /// **'例: ABC123'**
  String get referral_codeHint;

  /// No description provided for @referral_copy.
  ///
  /// In ja, this message translates to:
  /// **'コピー'**
  String get referral_copy;

  /// No description provided for @referral_enterCode.
  ///
  /// In ja, this message translates to:
  /// **'紹介コードを入力'**
  String get referral_enterCode;

  /// No description provided for @referral_enterCodeDescription.
  ///
  /// In ja, this message translates to:
  /// **'紹介コードを入力'**
  String get referral_enterCodeDescription;

  /// No description provided for @referral_inviteDescription.
  ///
  /// In ja, this message translates to:
  /// **'友達を招待して特典を受け取ろう'**
  String get referral_inviteDescription;

  /// No description provided for @referral_loginRequired.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get referral_loginRequired;

  /// No description provided for @referral_share.
  ///
  /// In ja, this message translates to:
  /// **'シェア'**
  String get referral_share;

  /// No description provided for @referral_stats.
  ///
  /// In ja, this message translates to:
  /// **'紹介実績'**
  String get referral_stats;

  /// No description provided for @referral_statsCount.
  ///
  /// In ja, this message translates to:
  /// **'{count} 人'**
  String referral_statsCount(String count);

  /// No description provided for @referral_title.
  ///
  /// In ja, this message translates to:
  /// **'友達を招待'**
  String get referral_title;

  /// No description provided for @referral_yourCode.
  ///
  /// In ja, this message translates to:
  /// **'あなたの紹介コード'**
  String get referral_yourCode;

  /// リフレッシュ中
  ///
  /// In ja, this message translates to:
  /// **'更新中...'**
  String get refreshing;

  /// 新規登録ボタン
  ///
  /// In ja, this message translates to:
  /// **'新規登録'**
  String get register;

  /// 登録成功メッセージ
  ///
  /// In ja, this message translates to:
  /// **'アカウントを作成しました'**
  String get registerSuccess;

  /// No description provided for @registrationPrompt_defaultFeature.
  ///
  /// In ja, this message translates to:
  /// **'この機能'**
  String get registrationPrompt_defaultFeature;

  /// No description provided for @registrationPrompt_description.
  ///
  /// In ja, this message translates to:
  /// **'LINEまたはメールアドレスで登録して、\\nすべての機能をご利用ください。'**
  String get registrationPrompt_description;

  /// No description provided for @registrationPrompt_emailLogin.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスで登録'**
  String get registrationPrompt_emailLogin;

  /// No description provided for @registrationPrompt_error.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました: {error}'**
  String registrationPrompt_error(String error);

  /// No description provided for @registrationPrompt_later.
  ///
  /// In ja, this message translates to:
  /// **'後で'**
  String get registrationPrompt_later;

  /// No description provided for @registrationPrompt_lineLogin.
  ///
  /// In ja, this message translates to:
  /// **'LINEで登録'**
  String get registrationPrompt_lineLogin;

  /// No description provided for @registrationPrompt_lineRedirect.
  ///
  /// In ja, this message translates to:
  /// **'LINEログインページへ移動します'**
  String get registrationPrompt_lineRedirect;

  /// No description provided for @registrationPrompt_title.
  ///
  /// In ja, this message translates to:
  /// **'{feature}には登録が必要です'**
  String registrationPrompt_title(String feature);

  /// 必須ラベル
  ///
  /// In ja, this message translates to:
  /// **'必須'**
  String get required;

  /// エラー時のリトライボタン
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retry;

  /// No description provided for @router_goHome.
  ///
  /// In ja, this message translates to:
  /// **'ホームに戻る'**
  String get router_goHome;

  /// No description provided for @router_pageDoesNotExist.
  ///
  /// In ja, this message translates to:
  /// **'{uri} は存在しません'**
  String router_pageDoesNotExist(String uri);

  /// No description provided for @router_pageNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ページが見つかりません'**
  String get router_pageNotFound;

  /// No description provided for @router_statementsTitle.
  ///
  /// In ja, this message translates to:
  /// **'明細一覧'**
  String get router_statementsTitle;

  /// No description provided for @router_workTimelineTitle.
  ///
  /// In ja, this message translates to:
  /// **'工程タイムライン'**
  String get router_workTimelineTitle;

  /// 売上ページタイトル
  ///
  /// In ja, this message translates to:
  /// **'売上'**
  String get salesTitle;

  /// No description provided for @sales_checkSales.
  ///
  /// In ja, this message translates to:
  /// **'売上確認'**
  String get sales_checkSales;

  /// No description provided for @sales_constructionCompleted.
  ///
  /// In ja, this message translates to:
  /// **'施工完了'**
  String get sales_constructionCompleted;

  /// No description provided for @sales_dataCount.
  ///
  /// In ja, this message translates to:
  /// **'データ件数: {count}件'**
  String sales_dataCount(String count);

  /// No description provided for @sales_earningsNote.
  ///
  /// In ja, this message translates to:
  /// **'※ 管理者が報酬を確定すると収入に反映されます'**
  String get sales_earningsNote;

  /// No description provided for @sales_incomeAndStatements.
  ///
  /// In ja, this message translates to:
  /// **'収入・明細'**
  String get sales_incomeAndStatements;

  /// No description provided for @sales_incomeNote.
  ///
  /// In ja, this message translates to:
  /// **'※ 確定済みの報酬のみ表示'**
  String get sales_incomeNote;

  /// No description provided for @sales_monthLabel.
  ///
  /// In ja, this message translates to:
  /// **'{month}月'**
  String sales_monthLabel(String month);

  /// No description provided for @sales_monthStatement.
  ///
  /// In ja, this message translates to:
  /// **'{month}月 明細'**
  String sales_monthStatement(String month);

  /// No description provided for @sales_monthlyTrend.
  ///
  /// In ja, this message translates to:
  /// **'月別推移'**
  String get sales_monthlyTrend;

  /// No description provided for @sales_nextPaymentDate.
  ///
  /// In ja, this message translates to:
  /// **'次回支払日: {month}月10日'**
  String sales_nextPaymentDate(String month);

  /// No description provided for @sales_noPaymentData.
  ///
  /// In ja, this message translates to:
  /// **'支払いデータがありません'**
  String get sales_noPaymentData;

  /// No description provided for @sales_noStatements.
  ///
  /// In ja, this message translates to:
  /// **'明細がありません'**
  String get sales_noStatements;

  /// No description provided for @sales_noStatementsDescription.
  ///
  /// In ja, this message translates to:
  /// **'月次明細が生成されるとここに表示されます。'**
  String get sales_noStatementsDescription;

  /// No description provided for @sales_paid.
  ///
  /// In ja, this message translates to:
  /// **'支払済'**
  String get sales_paid;

  /// No description provided for @sales_paymentHistory.
  ///
  /// In ja, this message translates to:
  /// **'支払い履歴'**
  String get sales_paymentHistory;

  /// No description provided for @sales_paymentManagement.
  ///
  /// In ja, this message translates to:
  /// **'支払い管理'**
  String get sales_paymentManagement;

  /// No description provided for @sales_registerPayment.
  ///
  /// In ja, this message translates to:
  /// **'報酬を登録'**
  String get sales_registerPayment;

  /// No description provided for @sales_registerToStart.
  ///
  /// In ja, this message translates to:
  /// **'登録して始める'**
  String get sales_registerToStart;

  /// No description provided for @sales_registrationDescription.
  ///
  /// In ja, this message translates to:
  /// **'売上情報を確認するには会員登録が必要です。'**
  String get sales_registrationDescription;

  /// No description provided for @sales_registrationRequired.
  ///
  /// In ja, this message translates to:
  /// **'会員登録が必要です'**
  String get sales_registrationRequired;

  /// No description provided for @sales_resetToThisMonth.
  ///
  /// In ja, this message translates to:
  /// **'今月に戻す'**
  String get sales_resetToThisMonth;

  /// No description provided for @sales_salesTitle.
  ///
  /// In ja, this message translates to:
  /// **'売上'**
  String get sales_salesTitle;

  /// No description provided for @sales_selectedMonthIncome.
  ///
  /// In ja, this message translates to:
  /// **'選択月の収入'**
  String get sales_selectedMonthIncome;

  /// No description provided for @sales_statusDraft.
  ///
  /// In ja, this message translates to:
  /// **'集計中'**
  String get sales_statusDraft;

  /// No description provided for @sales_statusPaid.
  ///
  /// In ja, this message translates to:
  /// **'支払済み'**
  String get sales_statusPaid;

  /// No description provided for @sales_tabIncome.
  ///
  /// In ja, this message translates to:
  /// **'収入'**
  String get sales_tabIncome;

  /// No description provided for @sales_tabStatements.
  ///
  /// In ja, this message translates to:
  /// **'明細'**
  String get sales_tabStatements;

  /// No description provided for @sales_thisMonthIncome.
  ///
  /// In ja, this message translates to:
  /// **'今月の収入'**
  String get sales_thisMonthIncome;

  /// No description provided for @sales_total.
  ///
  /// In ja, this message translates to:
  /// **'合計'**
  String get sales_total;

  /// No description provided for @sales_totalIncome.
  ///
  /// In ja, this message translates to:
  /// **'累計収入'**
  String get sales_totalIncome;

  /// No description provided for @sales_unconfirmedEarnings.
  ///
  /// In ja, this message translates to:
  /// **'未確定の報酬'**
  String get sales_unconfirmedEarnings;

  /// No description provided for @sales_unpaid.
  ///
  /// In ja, this message translates to:
  /// **'未払い'**
  String get sales_unpaid;

  /// 汎用保存ボタン
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// QRスキャン説明
  ///
  /// In ja, this message translates to:
  /// **'QRコードをスキャン'**
  String get scanQrCode;

  /// 汎用検索
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get search;

  /// 仕事検索ヒント
  ///
  /// In ja, this message translates to:
  /// **'仕事を検索'**
  String get searchJobs;

  /// 汎用送信ボタン
  ///
  /// In ja, this message translates to:
  /// **'送信'**
  String get send;

  /// メッセージ送信ボタン
  ///
  /// In ja, this message translates to:
  /// **'メッセージを送信'**
  String get sendMessage;

  /// リセットリンク送信ボタン
  ///
  /// In ja, this message translates to:
  /// **'リセットリンクを送信'**
  String get sendResetLink;

  /// 案件シェアボタン
  ///
  /// In ja, this message translates to:
  /// **'案件をシェア'**
  String get shareJob;

  /// シフトQRタイトル
  ///
  /// In ja, this message translates to:
  /// **'シフトQR'**
  String get shiftQr;

  /// No description provided for @shiftQr_generateFailed.
  ///
  /// In ja, this message translates to:
  /// **'生成に失敗: {error}'**
  String shiftQr_generateFailed(String error);

  /// No description provided for @shiftQr_generateNew.
  ///
  /// In ja, this message translates to:
  /// **'生成中...'**
  String get shiftQr_generateNew;

  /// No description provided for @shiftQr_generated.
  ///
  /// In ja, this message translates to:
  /// **'QRコードを生成しました'**
  String get shiftQr_generated;

  /// No description provided for @shiftQr_generating.
  ///
  /// In ja, this message translates to:
  /// **'生成中...'**
  String get shiftQr_generating;

  /// No description provided for @shiftQr_noQrCodes.
  ///
  /// In ja, this message translates to:
  /// **'QRコードはまだ生成されていません'**
  String get shiftQr_noQrCodes;

  /// No description provided for @shiftQr_scanInstruction.
  ///
  /// In ja, this message translates to:
  /// **'職人にこのQRコードをスキャンしてもらってください'**
  String get shiftQr_scanInstruction;

  /// No description provided for @shiftQr_title.
  ///
  /// In ja, this message translates to:
  /// **'QR出退勤管理'**
  String get shiftQr_title;

  /// パスワード表示切替
  ///
  /// In ja, this message translates to:
  /// **'パスワードを表示'**
  String get showPassword;

  /// Apple Sign In ボタン
  ///
  /// In ja, this message translates to:
  /// **'Appleでサインイン'**
  String get signInWithApple;

  /// メールログインボタン
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスでログイン'**
  String get signInWithEmail;

  /// LINE ログインボタン
  ///
  /// In ja, this message translates to:
  /// **'LINEでログイン'**
  String get signInWithLine;

  /// オンボーディング: スキップ
  ///
  /// In ja, this message translates to:
  /// **'スキップ'**
  String get skip;

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

  /// ゲストログインボタン
  ///
  /// In ja, this message translates to:
  /// **'ゲストとして始める'**
  String get startAsGuest;

  /// 口座設定開始ボタン
  ///
  /// In ja, this message translates to:
  /// **'口座設定を開始'**
  String get startOnboarding;

  /// No description provided for @statementDetail_applyButton.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get statementDetail_applyButton;

  /// No description provided for @statementDetail_completedDate.
  ///
  /// In ja, this message translates to:
  /// **'完了日: {date}'**
  String statementDetail_completedDate(String date);

  /// No description provided for @statementDetail_earlyPaymentButton.
  ///
  /// In ja, this message translates to:
  /// **'即金申請（手数料10%）'**
  String get statementDetail_earlyPaymentButton;

  /// No description provided for @statementDetail_earlyPaymentConfirm.
  ///
  /// In ja, this message translates to:
  /// **'即金申請しますか？手数料10%が差し引かれます。（金額: ¥{totalAmount}、手数料: ¥{fee}、支払額: ¥{payout}）'**
  String statementDetail_earlyPaymentConfirm(
    String totalAmount,
    String fee,
    String payout,
  );

  /// No description provided for @statementDetail_earlyPaymentError.
  ///
  /// In ja, this message translates to:
  /// **'即金申請を送信しました'**
  String get statementDetail_earlyPaymentError;

  /// No description provided for @statementDetail_earlyPaymentPending.
  ///
  /// In ja, this message translates to:
  /// **'即金申請済み（審査中）'**
  String get statementDetail_earlyPaymentPending;

  /// No description provided for @statementDetail_earlyPaymentSuccess.
  ///
  /// In ja, this message translates to:
  /// **'即金申請を送信しました'**
  String get statementDetail_earlyPaymentSuccess;

  /// No description provided for @statementDetail_earlyPaymentTitle.
  ///
  /// In ja, this message translates to:
  /// **'即金申請'**
  String get statementDetail_earlyPaymentTitle;

  /// No description provided for @statementDetail_error.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {error}'**
  String statementDetail_error(String error);

  /// No description provided for @statementDetail_jobDetails.
  ///
  /// In ja, this message translates to:
  /// **'案件明細'**
  String get statementDetail_jobDetails;

  /// No description provided for @statementDetail_monthLabel.
  ///
  /// In ja, this message translates to:
  /// **'{month}月'**
  String statementDetail_monthLabel(String month);

  /// No description provided for @statementDetail_title.
  ///
  /// In ja, this message translates to:
  /// **'明細詳細'**
  String get statementDetail_title;

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

  /// No description provided for @statusBadge_applied.
  ///
  /// In ja, this message translates to:
  /// **'応募中'**
  String get statusBadge_applied;

  /// No description provided for @statusBadge_assigned.
  ///
  /// In ja, this message translates to:
  /// **'着工前'**
  String get statusBadge_assigned;

  /// No description provided for @statusBadge_completed.
  ///
  /// In ja, this message translates to:
  /// **'施工完了'**
  String get statusBadge_completed;

  /// No description provided for @statusBadge_done.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get statusBadge_done;

  /// No description provided for @statusBadge_fixing.
  ///
  /// In ja, this message translates to:
  /// **'是正中'**
  String get statusBadge_fixing;

  /// No description provided for @statusBadge_inProgress.
  ///
  /// In ja, this message translates to:
  /// **'着工中'**
  String get statusBadge_inProgress;

  /// No description provided for @statusBadge_inspection.
  ///
  /// In ja, this message translates to:
  /// **'検収中'**
  String get statusBadge_inspection;

  /// ステータス: キャンセル
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get statusCancelled;

  /// ステータス: 完了
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get statusCompleted;

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

  /// No description provided for @stripeOnboarding_initFailed.
  ///
  /// In ja, this message translates to:
  /// **'URLの取得に失敗しました'**
  String get stripeOnboarding_initFailed;

  /// No description provided for @stripeOnboarding_retry.
  ///
  /// In ja, this message translates to:
  /// **'リトライ'**
  String get stripeOnboarding_retry;

  /// No description provided for @stripeOnboarding_title.
  ///
  /// In ja, this message translates to:
  /// **'Stripe口座設定'**
  String get stripeOnboarding_title;

  /// No description provided for @stripeOnboarding_urlFetchFailed.
  ///
  /// In ja, this message translates to:
  /// **'URLの取得に失敗しました'**
  String get stripeOnboarding_urlFetchFailed;

  /// タブ選択中アクセシビリティ
  ///
  /// In ja, this message translates to:
  /// **'選択中'**
  String get tabSelected;

  /// 利用規約リンク
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get termsOfService;

  /// No description provided for @timeline_empty.
  ///
  /// In ja, this message translates to:
  /// **'タイムラインはまだありません'**
  String get timeline_empty;

  /// No description provided for @timeline_error.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {error}'**
  String timeline_error(String error);

  /// 今日ラベル
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get today;

  /// リクエスト過多エラー
  ///
  /// In ja, this message translates to:
  /// **'リクエストが多すぎます。しばらくしてからお試しください'**
  String get tooManyRequests;

  /// 合計報酬ラベル
  ///
  /// In ja, this message translates to:
  /// **'合計報酬'**
  String get totalEarnings;

  /// メッセージ入力ヒント
  ///
  /// In ja, this message translates to:
  /// **'メッセージを入力'**
  String get typeMessage;

  /// No description provided for @unreadCount.
  ///
  /// In ja, this message translates to:
  /// **'未読{count}件'**
  String unreadCount(String count);

  /// 汎用更新ボタン
  ///
  /// In ja, this message translates to:
  /// **'更新'**
  String get update;

  /// アカウント無効エラー
  ///
  /// In ja, this message translates to:
  /// **'このアカウントは無効化されています'**
  String get userDisabled;

  /// アカウント未検出エラー
  ///
  /// In ja, this message translates to:
  /// **'アカウントが見つかりません'**
  String get userNotFound;

  /// 弱パスワードエラー
  ///
  /// In ja, this message translates to:
  /// **'パスワードが弱すぎます。6文字以上で設定してください'**
  String get weakPassword;

  /// 仕事詳細タイトル
  ///
  /// In ja, this message translates to:
  /// **'仕事詳細'**
  String get workDetail;

  /// No description provided for @workDetail_chat.
  ///
  /// In ja, this message translates to:
  /// **'チャット'**
  String get workDetail_chat;

  /// No description provided for @workDetail_checkedIn.
  ///
  /// In ja, this message translates to:
  /// **'出勤中'**
  String get workDetail_checkedIn;

  /// No description provided for @workDetail_checkedOut.
  ///
  /// In ja, this message translates to:
  /// **'退勤済み'**
  String get workDetail_checkedOut;

  /// No description provided for @workDetail_completeButton.
  ///
  /// In ja, this message translates to:
  /// **'完了報告'**
  String get workDetail_completeButton;

  /// No description provided for @workDetail_jobName.
  ///
  /// In ja, this message translates to:
  /// **'案件名'**
  String get workDetail_jobName;

  /// No description provided for @workDetail_jobNotFound.
  ///
  /// In ja, this message translates to:
  /// **'案件が見つかりません'**
  String get workDetail_jobNotFound;

  /// No description provided for @workDetail_location.
  ///
  /// In ja, this message translates to:
  /// **'場所'**
  String get workDetail_location;

  /// No description provided for @workDetail_loginRequired.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get workDetail_loginRequired;

  /// No description provided for @workDetail_noJobIdWarning.
  ///
  /// In ja, this message translates to:
  /// **'※ jobIdが未設定のため、元の案件情報を表示できません。'**
  String get workDetail_noJobIdWarning;

  /// No description provided for @workDetail_noPermission.
  ///
  /// In ja, this message translates to:
  /// **'この案件の閲覧権限がありません'**
  String get workDetail_noPermission;

  /// No description provided for @workDetail_notCheckedIn.
  ///
  /// In ja, this message translates to:
  /// **'未出勤'**
  String get workDetail_notCheckedIn;

  /// No description provided for @workDetail_payment.
  ///
  /// In ja, this message translates to:
  /// **'報酬'**
  String get workDetail_payment;

  /// No description provided for @workDetail_paymentUnconfirmed.
  ///
  /// In ja, this message translates to:
  /// **'未確定'**
  String get workDetail_paymentUnconfirmed;

  /// No description provided for @workDetail_qrAttendance.
  ///
  /// In ja, this message translates to:
  /// **'QR勤怠'**
  String get workDetail_qrAttendance;

  /// No description provided for @workDetail_qrClockIn.
  ///
  /// In ja, this message translates to:
  /// **'QR出勤'**
  String get workDetail_qrClockIn;

  /// No description provided for @workDetail_qrClockOut.
  ///
  /// In ja, this message translates to:
  /// **'QR退勤'**
  String get workDetail_qrClockOut;

  /// No description provided for @workDetail_rateButton.
  ///
  /// In ja, this message translates to:
  /// **'評価する'**
  String get workDetail_rateButton;

  /// No description provided for @workDetail_rated.
  ///
  /// In ja, this message translates to:
  /// **'評価済み'**
  String get workDetail_rated;

  /// No description provided for @workDetail_reinspect.
  ///
  /// In ja, this message translates to:
  /// **'再検査'**
  String get workDetail_reinspect;

  /// No description provided for @workDetail_reportRequired.
  ///
  /// In ja, this message translates to:
  /// **'完了するには日報を1件以上提出してください'**
  String get workDetail_reportRequired;

  /// No description provided for @workDetail_schedule.
  ///
  /// In ja, this message translates to:
  /// **'日程'**
  String get workDetail_schedule;

  /// No description provided for @workDetail_snackCompleteError.
  ///
  /// In ja, this message translates to:
  /// **'完了処理に失敗しました'**
  String get workDetail_snackCompleteError;

  /// No description provided for @workDetail_snackCompleted.
  ///
  /// In ja, this message translates to:
  /// **'施工完了しました'**
  String get workDetail_snackCompleted;

  /// No description provided for @workDetail_snackStartError.
  ///
  /// In ja, this message translates to:
  /// **'着工処理に失敗しました'**
  String get workDetail_snackStartError;

  /// No description provided for @workDetail_snackStarted.
  ///
  /// In ja, this message translates to:
  /// **'着工しました'**
  String get workDetail_snackStarted;

  /// No description provided for @workDetail_startButton.
  ///
  /// In ja, this message translates to:
  /// **'着工'**
  String get workDetail_startButton;

  /// No description provided for @workDetail_startInspection.
  ///
  /// In ja, this message translates to:
  /// **'検収'**
  String get workDetail_startInspection;

  /// No description provided for @workDetail_statusCompleted.
  ///
  /// In ja, this message translates to:
  /// **'{title}が「施工完了」になりました'**
  String workDetail_statusCompleted(String title);

  /// No description provided for @workDetail_statusInProgress.
  ///
  /// In ja, this message translates to:
  /// **'{title}が「着工中」になりました'**
  String workDetail_statusInProgress(String title);

  /// No description provided for @workDetail_statusUpdate.
  ///
  /// In ja, this message translates to:
  /// **'ステータス更新'**
  String get workDetail_statusUpdate;

  /// No description provided for @workDetail_tabDailyReport.
  ///
  /// In ja, this message translates to:
  /// **'日報'**
  String get workDetail_tabDailyReport;

  /// No description provided for @workDetail_tabDocuments.
  ///
  /// In ja, this message translates to:
  /// **'資料'**
  String get workDetail_tabDocuments;

  /// No description provided for @workDetail_tabOverview.
  ///
  /// In ja, this message translates to:
  /// **'概要'**
  String get workDetail_tabOverview;

  /// No description provided for @workDetail_tabPhotos.
  ///
  /// In ja, this message translates to:
  /// **'写真'**
  String get workDetail_tabPhotos;

  /// No description provided for @workDetail_timeline.
  ///
  /// In ja, this message translates to:
  /// **'タイムライン'**
  String get workDetail_timeline;

  /// No description provided for @workDocs_add.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get workDocs_add;

  /// No description provided for @workDocs_noDocuments.
  ///
  /// In ja, this message translates to:
  /// **'「{folder}」の資料はまだありません'**
  String workDocs_noDocuments(String folder);

  /// No description provided for @workDocs_title.
  ///
  /// In ja, this message translates to:
  /// **'資料管理'**
  String get workDocs_title;

  /// No description provided for @workDocs_uploadFailed.
  ///
  /// In ja, this message translates to:
  /// **'アップロードに失敗しました: {error}'**
  String workDocs_uploadFailed(String error);

  /// No description provided for @workDocs_uploadSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{folder}にアップロードしました'**
  String workDocs_uploadSuccess(String folder);

  /// No description provided for @workPhotos_add.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get workPhotos_add;

  /// No description provided for @workPhotos_cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get workPhotos_cancel;

  /// No description provided for @workPhotos_delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get workPhotos_delete;

  /// No description provided for @workPhotos_deleteConfirm.
  ///
  /// In ja, this message translates to:
  /// **'この写真を削除しますか？'**
  String get workPhotos_deleteConfirm;

  /// No description provided for @workPhotos_deleteSuccess.
  ///
  /// In ja, this message translates to:
  /// **'写真を削除しました'**
  String get workPhotos_deleteSuccess;

  /// No description provided for @workPhotos_deleteTitle.
  ///
  /// In ja, this message translates to:
  /// **'写真を削除'**
  String get workPhotos_deleteTitle;

  /// No description provided for @workPhotos_noPhotos.
  ///
  /// In ja, this message translates to:
  /// **'写真はまだありません'**
  String get workPhotos_noPhotos;

  /// No description provided for @workPhotos_title.
  ///
  /// In ja, this message translates to:
  /// **'現場写真'**
  String get workPhotos_title;

  /// No description provided for @workPhotos_uploadFailed.
  ///
  /// In ja, this message translates to:
  /// **'アップロードに失敗しました: {error}'**
  String workPhotos_uploadFailed(String error);

  /// No description provided for @workPhotos_uploadHint.
  ///
  /// In ja, this message translates to:
  /// **'「追加」ボタンから写真をアップロード'**
  String get workPhotos_uploadHint;

  /// No description provided for @workPhotos_uploadSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{count}枚の写真をアップロードしました'**
  String workPhotos_uploadSuccess(String count);

  /// No description provided for @workReportCreate_contentHint.
  ///
  /// In ja, this message translates to:
  /// **'作業内容 *'**
  String get workReportCreate_contentHint;

  /// No description provided for @workReportCreate_contentLabel.
  ///
  /// In ja, this message translates to:
  /// **'作業内容 *'**
  String get workReportCreate_contentLabel;

  /// No description provided for @workReportCreate_contentRequired.
  ///
  /// In ja, this message translates to:
  /// **'作業内容 *'**
  String get workReportCreate_contentRequired;

  /// No description provided for @workReportCreate_date.
  ///
  /// In ja, this message translates to:
  /// **'日付'**
  String get workReportCreate_date;

  /// No description provided for @workReportCreate_hoursLabel.
  ///
  /// In ja, this message translates to:
  /// **'作業時間（時間）'**
  String get workReportCreate_hoursLabel;

  /// No description provided for @workReportCreate_hoursSuffix.
  ///
  /// In ja, this message translates to:
  /// **'作業時間（時間）'**
  String get workReportCreate_hoursSuffix;

  /// No description provided for @workReportCreate_hoursValidation.
  ///
  /// In ja, this message translates to:
  /// **'時間'**
  String get workReportCreate_hoursValidation;

  /// No description provided for @workReportCreate_logSubmitted.
  ///
  /// In ja, this message translates to:
  /// **'日報: {title} 提出'**
  String workReportCreate_logSubmitted(String title);

  /// No description provided for @workReportCreate_notesHint.
  ///
  /// In ja, this message translates to:
  /// **'備考'**
  String get workReportCreate_notesHint;

  /// No description provided for @workReportCreate_notesLabel.
  ///
  /// In ja, this message translates to:
  /// **'備考'**
  String get workReportCreate_notesLabel;

  /// No description provided for @workReportCreate_saveFailed.
  ///
  /// In ja, this message translates to:
  /// **'保存に失敗: {error}'**
  String workReportCreate_saveFailed(String error);

  /// No description provided for @workReportCreate_submit.
  ///
  /// In ja, this message translates to:
  /// **'日報を提出しました'**
  String get workReportCreate_submit;

  /// No description provided for @workReportCreate_submitted.
  ///
  /// In ja, this message translates to:
  /// **'日報を提出しました'**
  String get workReportCreate_submitted;

  /// No description provided for @workReportCreate_title.
  ///
  /// In ja, this message translates to:
  /// **'日報作成'**
  String get workReportCreate_title;

  /// No description provided for @workReports_addHint.
  ///
  /// In ja, this message translates to:
  /// **'日報はまだありません'**
  String get workReports_addHint;

  /// No description provided for @workReports_empty.
  ///
  /// In ja, this message translates to:
  /// **'日報はまだありません'**
  String get workReports_empty;

  /// No description provided for @workReports_error.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {error}'**
  String workReports_error(String error);

  /// 勤務状況ラベル
  ///
  /// In ja, this message translates to:
  /// **'勤務状況'**
  String get workStatus;

  /// はたらくページタイトル
  ///
  /// In ja, this message translates to:
  /// **'はたらく'**
  String get workTitle;

  /// No description provided for @work_chatTooltip.
  ///
  /// In ja, this message translates to:
  /// **'チャット'**
  String get work_chatTooltip;

  /// No description provided for @work_emptyApplications.
  ///
  /// In ja, this message translates to:
  /// **'応募した案件はありません'**
  String get work_emptyApplications;

  /// No description provided for @work_emptyAssigned.
  ///
  /// In ja, this message translates to:
  /// **'アサイン済みの案件はありません'**
  String get work_emptyAssigned;

  /// No description provided for @work_emptyCompleted.
  ///
  /// In ja, this message translates to:
  /// **'施工完了の案件はありません'**
  String get work_emptyCompleted;

  /// No description provided for @work_emptyDefault.
  ///
  /// In ja, this message translates to:
  /// **'該当する案件はありません'**
  String get work_emptyDefault;

  /// No description provided for @work_emptyDone.
  ///
  /// In ja, this message translates to:
  /// **'完了した案件はありません'**
  String get work_emptyDone;

  /// No description provided for @work_emptyFixing.
  ///
  /// In ja, this message translates to:
  /// **'是正中の案件はありません'**
  String get work_emptyFixing;

  /// No description provided for @work_emptyInProgress.
  ///
  /// In ja, this message translates to:
  /// **'作業中の案件はありません'**
  String get work_emptyInProgress;

  /// No description provided for @work_emptyInspection.
  ///
  /// In ja, this message translates to:
  /// **'検収中の案件はありません'**
  String get work_emptyInspection;

  /// No description provided for @work_featureName.
  ///
  /// In ja, this message translates to:
  /// **'仕事管理'**
  String get work_featureName;

  /// No description provided for @work_groupApplied.
  ///
  /// In ja, this message translates to:
  /// **'応募中'**
  String get work_groupApplied;

  /// No description provided for @work_groupApproved.
  ///
  /// In ja, this message translates to:
  /// **'承認済み・作業中'**
  String get work_groupApproved;

  /// No description provided for @work_groupCompleted.
  ///
  /// In ja, this message translates to:
  /// **'完了・検収'**
  String get work_groupCompleted;

  /// No description provided for @work_noJobs.
  ///
  /// In ja, this message translates to:
  /// **'該当なし'**
  String get work_noJobs;

  /// No description provided for @work_registrationRequiredDescription.
  ///
  /// In ja, this message translates to:
  /// **'会員登録をして、お仕事の応募・管理機能をご利用ください。'**
  String get work_registrationRequiredDescription;

  /// No description provided for @work_registrationRequiredTitle.
  ///
  /// In ja, this message translates to:
  /// **'仕事管理を利用するには会員登録が必要です'**
  String get work_registrationRequiredTitle;

  /// No description provided for @work_tabApplications.
  ///
  /// In ja, this message translates to:
  /// **'応募一覧'**
  String get work_tabApplications;

  /// No description provided for @work_tabAssigned.
  ///
  /// In ja, this message translates to:
  /// **'アサイン済み'**
  String get work_tabAssigned;

  /// No description provided for @work_tabCompleted.
  ///
  /// In ja, this message translates to:
  /// **'施工完了'**
  String get work_tabCompleted;

  /// No description provided for @work_tabDone.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get work_tabDone;

  /// No description provided for @work_tabFixing.
  ///
  /// In ja, this message translates to:
  /// **'是正中'**
  String get work_tabFixing;

  /// No description provided for @work_tabInProgress.
  ///
  /// In ja, this message translates to:
  /// **'作業中'**
  String get work_tabInProgress;

  /// No description provided for @work_tabInspection.
  ///
  /// In ja, this message translates to:
  /// **'検収中'**
  String get work_tabInspection;

  /// ワーカーラベル
  ///
  /// In ja, this message translates to:
  /// **'ワーカー'**
  String get workerLabel;

  /// パスワード不正エラー
  ///
  /// In ja, this message translates to:
  /// **'パスワードが正しくありません'**
  String get wrongPassword;

  /// 円
  ///
  /// In ja, this message translates to:
  /// **'円'**
  String get yen;

  /// 昨日ラベル
  ///
  /// In ja, this message translates to:
  /// **'昨日'**
  String get yesterday;

  /// No description provided for @jobList_monthNumLabel.
  ///
  /// In ja, this message translates to:
  /// **'{month}月'**
  String jobList_monthNumLabel(String month);

  /// No description provided for @jobList_resultCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String jobList_resultCount(String count);

  /// No description provided for @messages_filterAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get messages_filterAll;

  /// No description provided for @messages_filterUnread.
  ///
  /// In ja, this message translates to:
  /// **'未読'**
  String get messages_filterUnread;

  /// No description provided for @messages_noUnread.
  ///
  /// In ja, this message translates to:
  /// **'未読メッセージはありません'**
  String get messages_noUnread;

  /// No description provided for @profile_totalJobs.
  ///
  /// In ja, this message translates to:
  /// **'完了案件'**
  String get profile_totalJobs;

  /// No description provided for @profile_rating.
  ///
  /// In ja, this message translates to:
  /// **'評価'**
  String get profile_rating;

  /// No description provided for @profile_qualityScore.
  ///
  /// In ja, this message translates to:
  /// **'スコア'**
  String get profile_qualityScore;

  /// No description provided for @profile_logout.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get profile_logout;

  /// No description provided for @home_unreadMessages.
  ///
  /// In ja, this message translates to:
  /// **'未読メッセージ{count}件'**
  String home_unreadMessages(String count);

  /// No description provided for @work_unreadChat.
  ///
  /// In ja, this message translates to:
  /// **'未読{count}件'**
  String work_unreadChat(String count);

  /// No description provided for @post_sectionImages.
  ///
  /// In ja, this message translates to:
  /// **'画像'**
  String get post_sectionImages;

  /// No description provided for @post_sectionImagesSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'案件の写真を追加（最大5枚）'**
  String get post_sectionImagesSubtitle;

  /// No description provided for @post_addImages.
  ///
  /// In ja, this message translates to:
  /// **'画像を追加（{current}/{max}）'**
  String post_addImages(String current, String max);

  /// No description provided for @adminApproval_noName.
  ///
  /// In ja, this message translates to:
  /// **'名前未設定'**
  String get adminApproval_noName;

  /// No description provided for @adminApproval_approve.
  ///
  /// In ja, this message translates to:
  /// **'承認'**
  String get adminApproval_approve;

  /// No description provided for @adminApproval_reject.
  ///
  /// In ja, this message translates to:
  /// **'却下'**
  String get adminApproval_reject;

  /// No description provided for @adminApproval_rejectReasonTitle.
  ///
  /// In ja, this message translates to:
  /// **'却下理由'**
  String get adminApproval_rejectReasonTitle;

  /// No description provided for @adminApproval_rejectReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'却下理由を入力してください'**
  String get adminApproval_rejectReasonHint;

  /// No description provided for @adminApproval_rejectButton.
  ///
  /// In ja, this message translates to:
  /// **'却下する'**
  String get adminApproval_rejectButton;

  /// No description provided for @adminKpi_noData.
  ///
  /// In ja, this message translates to:
  /// **'データなし'**
  String get adminKpi_noData;

  /// No description provided for @adminNav_jobs.
  ///
  /// In ja, this message translates to:
  /// **'案件'**
  String get adminNav_jobs;

  /// No description provided for @adminNav_approvals.
  ///
  /// In ja, this message translates to:
  /// **'承認'**
  String get adminNav_approvals;

  /// No description provided for @adminNav_workers.
  ///
  /// In ja, this message translates to:
  /// **'ワーカー'**
  String get adminNav_workers;

  /// No description provided for @adminNav_settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get adminNav_settings;

  /// No description provided for @adminNav_jobManagement.
  ///
  /// In ja, this message translates to:
  /// **'案件管理'**
  String get adminNav_jobManagement;

  /// No description provided for @adminNav_applicants.
  ///
  /// In ja, this message translates to:
  /// **'応募者管理'**
  String get adminNav_applicants;

  /// No description provided for @adminApproval_qualifications.
  ///
  /// In ja, this message translates to:
  /// **'資格'**
  String get adminApproval_qualifications;

  /// No description provided for @adminApproval_earlyPayments.
  ///
  /// In ja, this message translates to:
  /// **'即金'**
  String get adminApproval_earlyPayments;

  /// No description provided for @adminApproval_verification.
  ///
  /// In ja, this message translates to:
  /// **'本人確認'**
  String get adminApproval_verification;

  /// No description provided for @adminApproval_emptyTitle.
  ///
  /// In ja, this message translates to:
  /// **'未処理の承認はありません'**
  String get adminApproval_emptyTitle;

  /// No description provided for @adminApproval_emptyDescription.
  ///
  /// In ja, this message translates to:
  /// **'すべての承認が処理されました'**
  String get adminApproval_emptyDescription;

  /// No description provided for @adminApproval_pendingReview.
  ///
  /// In ja, this message translates to:
  /// **'審査待ち'**
  String get adminApproval_pendingReview;

  /// No description provided for @adminKpi_dailyTrend.
  ///
  /// In ja, this message translates to:
  /// **'応募トレンド（直近7日）'**
  String get adminKpi_dailyTrend;

  /// No description provided for @adminKpi_monthlyKpi.
  ///
  /// In ja, this message translates to:
  /// **'月次KPI'**
  String get adminKpi_monthlyKpi;

  /// No description provided for @adminKpi_mau.
  ///
  /// In ja, this message translates to:
  /// **'MAU'**
  String get adminKpi_mau;

  /// No description provided for @adminKpi_monthlyEarnings.
  ///
  /// In ja, this message translates to:
  /// **'月間売上'**
  String get adminKpi_monthlyEarnings;

  /// No description provided for @adminKpi_jobFillRate.
  ///
  /// In ja, this message translates to:
  /// **'充足率'**
  String get adminKpi_jobFillRate;

  /// No description provided for @adminWorkers_activeList.
  ///
  /// In ja, this message translates to:
  /// **'稼働一覧'**
  String get adminWorkers_activeList;

  /// No description provided for @adminWorkers_reports.
  ///
  /// In ja, this message translates to:
  /// **'日報'**
  String get adminWorkers_reports;

  /// No description provided for @adminWorkers_inspections.
  ///
  /// In ja, this message translates to:
  /// **'検査'**
  String get adminWorkers_inspections;

  /// No description provided for @adminWorkers_searchHint.
  ///
  /// In ja, this message translates to:
  /// **'ワーカー名で検索'**
  String get adminWorkers_searchHint;

  /// No description provided for @adminWorkers_emptyTitle.
  ///
  /// In ja, this message translates to:
  /// **'稼働中のワーカーはいません'**
  String get adminWorkers_emptyTitle;

  /// No description provided for @adminWorkers_emptyDescription.
  ///
  /// In ja, this message translates to:
  /// **'現在稼働中のワーカーはいません'**
  String get adminWorkers_emptyDescription;

  /// No description provided for @adminWorkers_inProgressCount.
  ///
  /// In ja, this message translates to:
  /// **'稼働中 {count}人'**
  String adminWorkers_inProgressCount(String count);

  /// No description provided for @adminWorkers_assignedCount.
  ///
  /// In ja, this message translates to:
  /// **'割当済 {count}人'**
  String adminWorkers_assignedCount(String count);

  /// No description provided for @adminWorkers_jobUnit.
  ///
  /// In ja, this message translates to:
  /// **'件'**
  String get adminWorkers_jobUnit;

  /// No description provided for @adminWorkReports_emptyTitle.
  ///
  /// In ja, this message translates to:
  /// **'日報はまだありません'**
  String get adminWorkReports_emptyTitle;

  /// No description provided for @adminWorkReports_emptyDescription.
  ///
  /// In ja, this message translates to:
  /// **'ワーカーが日報を提出するとここに表示されます'**
  String get adminWorkReports_emptyDescription;

  /// No description provided for @adminWorkReports_hours.
  ///
  /// In ja, this message translates to:
  /// **'{hours}時間'**
  String adminWorkReports_hours(String hours);

  /// No description provided for @adminInspections_filterAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get adminInspections_filterAll;

  /// No description provided for @adminInspections_filterPassed.
  ///
  /// In ja, this message translates to:
  /// **'合格'**
  String get adminInspections_filterPassed;

  /// No description provided for @adminInspections_filterFailed.
  ///
  /// In ja, this message translates to:
  /// **'不合格'**
  String get adminInspections_filterFailed;

  /// No description provided for @adminInspections_filterPartial.
  ///
  /// In ja, this message translates to:
  /// **'一部不合格'**
  String get adminInspections_filterPartial;

  /// No description provided for @adminInspections_emptyTitle.
  ///
  /// In ja, this message translates to:
  /// **'検査記録はありません'**
  String get adminInspections_emptyTitle;

  /// No description provided for @adminInspections_emptyDescription.
  ///
  /// In ja, this message translates to:
  /// **'検査が実施されるとここに表示されます'**
  String get adminInspections_emptyDescription;

  /// No description provided for @adminInspections_passed.
  ///
  /// In ja, this message translates to:
  /// **'合格'**
  String get adminInspections_passed;

  /// No description provided for @adminInspections_failed.
  ///
  /// In ja, this message translates to:
  /// **'不合格'**
  String get adminInspections_failed;

  /// No description provided for @adminInspections_partial.
  ///
  /// In ja, this message translates to:
  /// **'一部不合格'**
  String get adminInspections_partial;

  /// No description provided for @adminInspections_checkSummary.
  ///
  /// In ja, this message translates to:
  /// **'{total}項目中{passed}件合格'**
  String adminInspections_checkSummary(String total, String passed);

  /// No description provided for @adminSettings_admin.
  ///
  /// In ja, this message translates to:
  /// **'管理者'**
  String get adminSettings_admin;

  /// No description provided for @adminSettings_notifications.
  ///
  /// In ja, this message translates to:
  /// **'通知設定'**
  String get adminSettings_notifications;

  /// No description provided for @adminSettings_appVersion.
  ///
  /// In ja, this message translates to:
  /// **'アプリバージョン'**
  String get adminSettings_appVersion;

  /// No description provided for @adminSettings_legal.
  ///
  /// In ja, this message translates to:
  /// **'法的情報'**
  String get adminSettings_legal;

  /// No description provided for @adminSettings_logout.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get adminSettings_logout;

  /// No description provided for @adminSettings_logoutTitle.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get adminSettings_logoutTitle;

  /// No description provided for @adminSettings_logoutConfirm.
  ///
  /// In ja, this message translates to:
  /// **'ログアウトしますか？'**
  String get adminSettings_logoutConfirm;

  /// No description provided for @adminDashboard_workReports.
  ///
  /// In ja, this message translates to:
  /// **'日報管理'**
  String get adminDashboard_workReports;
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
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
