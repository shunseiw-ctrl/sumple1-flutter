// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get accountSettings => 'アカウント設定';

  @override
  String get accountSettings_cancel => '・チャット履歴\\n';

  @override
  String get accountSettings_changePasswordButton => '新しいパスワード（6文字以上）';

  @override
  String get accountSettings_changePasswordLabel => '名前を入力';

  @override
  String get accountSettings_confirm => '確認';

  @override
  String get accountSettings_currentPasswordHint => '現在のパスワード';

  @override
  String get accountSettings_delete => 'アカウントを削除すると、全てのデータが完全に失われます。\\n\\n';

  @override
  String get accountSettings_deleteAccount =>
      'アカウントを削除すると、全てのデータが完全に失われます。\\n\\n';

  @override
  String get accountSettings_deleteConfirmMessage =>
      'アカウントを削除すると、全てのデータが完全に失われます。\\n\\n';

  @override
  String get accountSettings_displayNameLabel => '表示名';

  @override
  String get accountSettings_downloadData => 'データをダウンロード';

  @override
  String get accountSettings_emailLabel => 'メールアドレス';

  @override
  String get accountSettings_languageLabel => '言語設定';

  @override
  String get accountSettings_loginRequired => 'ログインが必要です';

  @override
  String get accountSettings_nameHint => '名前を入力';

  @override
  String get accountSettings_newPasswordHint => '新しいパスワード（6文字以上）';

  @override
  String get accountSettings_notSet => '未設定';

  @override
  String get accountSettings_notificationSettings => '通知設定';

  @override
  String get accountSettings_receiveNotifications => 'お知らせ通知を受け取る';

  @override
  String get accountSettings_snackDataCopied => 'データをクリップボードにコピーしました';

  @override
  String accountSettings_snackDeleteFailed(String error) {
    return 'アカウント削除に失敗しました: $error';
  }

  @override
  String accountSettings_snackDeleteFailedGeneric(String error) {
    return 'アカウント削除に失敗しました: $error';
  }

  @override
  String get accountSettings_snackEnterBothPasswords =>
      '現在のパスワードと新しいパスワードを入力してください';

  @override
  String accountSettings_snackError(String error) {
    return 'エラー: $error';
  }

  @override
  String accountSettings_snackExportFailed(String error) {
    return 'データエクスポートに失敗しました: $error';
  }

  @override
  String get accountSettings_snackNameUpdated => '表示名を更新しました';

  @override
  String accountSettings_snackPasswordChangeFailed(String error) {
    return 'パスワード変更に失敗しました: $error';
  }

  @override
  String get accountSettings_snackPasswordChanged => 'パスワードを変更しました';

  @override
  String get accountSettings_snackPasswordMinLength => 'パスワードは6文字以上にしてください';

  @override
  String accountSettings_snackUpdateFailed(String error) {
    return '更新に失敗しました: $error';
  }

  @override
  String get accountSettings_snackWrongPassword => '現在のパスワードが正しくありません';

  @override
  String get accountSettings_title => '未設定';

  @override
  String get address => '住所';

  @override
  String get adminApplicants_bulkApproveButton => '一括承認する';

  @override
  String adminApplicants_bulkApproveConfirm(String count) {
    return '応募中の$count件をすべて「アサイン済み」に変更しますか？';
  }

  @override
  String adminApplicants_bulkApproveCount(String count) {
    return '一括承認 ($count件)';
  }

  @override
  String adminApplicants_bulkApproveFailed(String error) {
    return '一括承認に失敗しました: $error';
  }

  @override
  String get adminApplicants_bulkApproveTitle => '一括承認';

  @override
  String adminApplicants_bulkApproved(String count) {
    return '$count件を承認しました';
  }

  @override
  String get adminApplicants_changeButton => '変更する';

  @override
  String adminApplicants_changeFailed(String error) {
    return '変更に失敗しました: $error';
  }

  @override
  String adminApplicants_changeStatusConfirm(
    String jobTitle,
    String statusLabel,
  ) {
    return '「$jobTitle」のステータスを「$statusLabel」に変更しますか？';
  }

  @override
  String get adminApplicants_changeStatusTitle => 'ステータス変更';

  @override
  String get adminApplicants_filterAll => 'すべて';

  @override
  String get adminApplicants_filterApplied => '応募中';

  @override
  String get adminApplicants_filterAssigned => 'アサイン済み';

  @override
  String get adminApplicants_filterDone => '完了';

  @override
  String get adminApplicants_filterInProgress => '作業中';

  @override
  String adminApplicants_noApplicantsForStatus(String statusLabel) {
    return '「$statusLabel」の応募者はいません';
  }

  @override
  String get adminApplicants_noApplicantsYet => '応募者はまだいません';

  @override
  String adminApplicants_qualityScore(String score) {
    return '品質: $score';
  }

  @override
  String get adminApplicants_searchHint => '名前で検索…';

  @override
  String get adminApplicants_startWork => '作業開始';

  @override
  String adminApplicants_statusChanged(String jobTitle, String statusLabel) {
    return '「$jobTitle」→「$statusLabel」に変更しました';
  }

  @override
  String adminApplicants_statusUpdateNotifBody(
    String jobTitle,
    String statusLabel,
  ) {
    return '「$jobTitle」のステータスが「$statusLabel」に変更されました';
  }

  @override
  String get adminApplicants_statusUpdateNotifTitle => 'ステータスが更新されました';

  @override
  String get adminApplicants_workCompleted => '作業完了';

  @override
  String get adminApplications => '応募管理';

  @override
  String get adminBadge => '管理者';

  @override
  String get adminDashboard_activeJobs => '掲載中の案件';

  @override
  String adminDashboard_alertCount(String label, String count) {
    return '$label $count件';
  }

  @override
  String get adminDashboard_applicationCount => '応募数';

  @override
  String get adminDashboard_checkSales => '売上を確認';

  @override
  String get adminDashboard_earlyPaymentApproval => '即金承認';

  @override
  String get adminDashboard_identityVerification => '本人確認';

  @override
  String get adminDashboard_noApplications => 'まだ応募はありません';

  @override
  String get adminDashboard_noJobTitle => '案件名なし';

  @override
  String get adminDashboard_pendingAlerts => '未処理アラート';

  @override
  String get adminDashboard_pendingApplications => '未対応の応募';

  @override
  String get adminDashboard_pendingApproval => '承認待ちの応募';

  @override
  String get adminDashboard_pendingEarlyPayments => '即金申請待ち';

  @override
  String get adminDashboard_pendingQualifications => '資格承認待ち';

  @override
  String get adminDashboard_pendingVerifications => '本人確認待ち';

  @override
  String get adminDashboard_postJob => '案件を投稿';

  @override
  String get adminDashboard_qualificationApproval => '資格承認';

  @override
  String get adminDashboard_quickActions => 'クイックアクション';

  @override
  String get adminDashboard_recentApplications => '最近の応募';

  @override
  String get adminDashboard_registeredUsers => '登録ユーザー';

  @override
  String get adminDashboard_title => '管理者ダッシュボード';

  @override
  String get adminEarlyPayments_approveLabel => '承認';

  @override
  String get adminEarlyPayments_cancel => 'キャンセル';

  @override
  String get adminEarlyPayments_emptyDescription => 'ワーカーが即金申請を行うと、ここに表示されます。';

  @override
  String get adminEarlyPayments_emptyTitle => '承認待ちの即金申請はありません';

  @override
  String get adminEarlyPayments_fee => '手数料 (10%)';

  @override
  String adminEarlyPayments_loadError(String error) {
    return '読み込みエラー: $error';
  }

  @override
  String get adminEarlyPayments_loading => '読み込み中...';

  @override
  String get adminEarlyPayments_nameNotSet => '名前未設定';

  @override
  String get adminEarlyPayments_notifyApprovedBody =>
      '即金申請が承認されました。まもなく振り込まれます。';

  @override
  String get adminEarlyPayments_notifyApprovedTitle => '即金申請が承認されました';

  @override
  String adminEarlyPayments_notifyRejectedBody(String reason) {
    return '即金申請が却下されました。理由: $reason';
  }

  @override
  String get adminEarlyPayments_notifyRejectedTitle => '即金申請が却下されました';

  @override
  String get adminEarlyPayments_payoutAmount => '支払額';

  @override
  String get adminEarlyPayments_rejectButton => '却下する';

  @override
  String get adminEarlyPayments_rejectLabel => '却下';

  @override
  String get adminEarlyPayments_rejectReasonHint => '却下の理由を入力してください';

  @override
  String get adminEarlyPayments_rejectReasonRequired => '却下理由を入力してください';

  @override
  String get adminEarlyPayments_rejectReasonTitle => '却下理由';

  @override
  String adminEarlyPayments_requestDate(String date) {
    return '申請日時: $date';
  }

  @override
  String get adminEarlyPayments_requestedAmount => '申請額';

  @override
  String get adminEarlyPayments_snackApproveFailed => '承認に失敗しました';

  @override
  String get adminEarlyPayments_snackApproved => '即金申請を承認しました';

  @override
  String get adminEarlyPayments_snackRejectFailed => '却下に失敗しました';

  @override
  String get adminEarlyPayments_snackRejected => '即金申請を却下しました';

  @override
  String get adminEarlyPayments_statusRequested => '申請中';

  @override
  String get adminEarlyPayments_targetMonth => '対象月';

  @override
  String get adminEarlyPayments_title => '即金申請一覧';

  @override
  String adminEarlyPayments_yenFormat(String amount) {
    return '$amount円';
  }

  @override
  String get adminHome => '管理者ダッシュボード';

  @override
  String get adminHome_admin => '管理者';

  @override
  String get adminHome_applicants => '応募者';

  @override
  String get adminHome_dashboard => 'ダッシュボード';

  @override
  String get adminHome_jobManagement => '案件管理';

  @override
  String get adminHome_notifications => 'お知らせ';

  @override
  String get adminHome_salesManagement => '売上管理';

  @override
  String get adminHome_settings => '設定';

  @override
  String get adminIdentityVerification_approveButton => '承認する';

  @override
  String get adminIdentityVerification_approveConfirm => 'この本人確認を承認しますか？';

  @override
  String adminIdentityVerification_approveFailed(String error) {
    return '承認に失敗しました: $error';
  }

  @override
  String get adminIdentityVerification_approveTitle => '承認確認';

  @override
  String get adminIdentityVerification_approved => '承認しました';

  @override
  String get adminIdentityVerification_enterRejectReason => '却下理由を入力してください';

  @override
  String get adminIdentityVerification_idDocumentPhoto => '身分証明書';

  @override
  String get adminIdentityVerification_noPendingRequests => '審査待ちの申請はありません';

  @override
  String get adminIdentityVerification_rejectButton => '却下する';

  @override
  String adminIdentityVerification_rejectFailed(String error) {
    return '却下に失敗しました: $error';
  }

  @override
  String get adminIdentityVerification_rejectReasonHint => '例: 写真が不鮮明です';

  @override
  String get adminIdentityVerification_rejectTitle => '却下確認';

  @override
  String get adminIdentityVerification_rejected => '却下しました';

  @override
  String get adminIdentityVerification_selfiePhoto => '自撮り写真';

  @override
  String get adminIdentityVerification_title => '本人確認管理';

  @override
  String get adminJobManagement => '案件管理';

  @override
  String adminJobManagement_applicantCount(String count) {
    return '応募者 $count';
  }

  @override
  String get adminJobManagement_checkNetwork => '権限がありません';

  @override
  String get adminJobManagement_dateTbd => '未定';

  @override
  String get adminJobManagement_filterActive => 'すべて';

  @override
  String get adminJobManagement_filterAll => 'すべて';

  @override
  String get adminJobManagement_filterCompleted => 'すべて';

  @override
  String get adminJobManagement_filterDraft => '公開中';

  @override
  String get adminJobManagement_loadFailed => 'データの読み込みに失敗しました';

  @override
  String get adminJobManagement_locationNotSet => '場所未設定';

  @override
  String get adminJobManagement_noJobs => '案件がまだありません';

  @override
  String get adminJobManagement_noPermission => '権限がありません';

  @override
  String get adminJobManagement_noTitle => 'タイトルなし';

  @override
  String get adminJobManagement_postHint => '案件がまだありません';

  @override
  String get adminJobManagement_postJob => '案件を投稿';

  @override
  String get adminJobManagement_searchHint => 'タイトル・場所で検索';

  @override
  String get adminJobManagement_showMore => 'もっと見る';

  @override
  String get adminJob_viewJobs => '案件一覧';

  @override
  String get adminJob_viewApplications => '全応募ステータス';

  @override
  String adminJob_summaryTotal(String count) {
    return '全$count件';
  }

  @override
  String adminJob_summaryActive(String count) {
    return '募集中$count件';
  }

  @override
  String adminJob_summaryCompleted(String count) {
    return '完了$count件';
  }

  @override
  String adminApplicants_summaryPending(String count) {
    return '要対応$count件';
  }

  @override
  String adminApplicants_summaryAssigned(String count) {
    return '確定済$count件';
  }

  @override
  String adminApplicants_summaryInProgress(String count) {
    return '進行中$count件';
  }

  @override
  String adminApplicants_summaryDone(String count) {
    return '完了$count件';
  }

  @override
  String get adminWorker_title => '職人詳細';

  @override
  String get adminWorker_applicationHistory => '応募履歴';

  @override
  String get adminWorker_qualifications => '資格情報';

  @override
  String get adminWorker_unknownWorker => '不明な職人';

  @override
  String get adminWorker_noApplications => '応募履歴はありません';

  @override
  String get adminWorker_noQualifications => '資格情報はありません';

  @override
  String get adminLogin => '管理者ログイン';

  @override
  String get adminLoginDescription => '管理者パスワードを入力してください';

  @override
  String get adminLogin_email => 'メールアドレス';

  @override
  String get adminLogin_emailInvalid => '有効なメールアドレスを入力してください';

  @override
  String get adminLogin_emailRequired => 'メールアドレスを入力してください';

  @override
  String adminLogin_lockoutMessage(String minutes, String seconds) {
    return 'ログイン試行回数の上限に達しました。$minutes分$seconds秒後にお試しください';
  }

  @override
  String get adminLogin_login => 'ログインしました';

  @override
  String get adminLogin_loginSuccess => 'ログインしました';

  @override
  String get adminLogin_password => 'パスワード';

  @override
  String get adminLogin_passwordMinLength => 'パスワードは6文字以上で入力してください';

  @override
  String get adminLogin_passwordRequired => 'パスワードを入力してください';

  @override
  String get adminLogin_title => '管理者ログイン';

  @override
  String get adminPassword => '管理者パスワード';

  @override
  String get adminPayments => '決済管理';

  @override
  String get adminQualifications_approve => '承認';

  @override
  String get adminQualifications_approveError => '承認に失敗しました';

  @override
  String adminQualifications_approveSuccess(String name) {
    return '$nameを承認しました';
  }

  @override
  String adminQualifications_category(String category) {
    return 'カテゴリ: $category';
  }

  @override
  String get adminQualifications_emptyDescription => '承認待ちの資格はありません';

  @override
  String get adminQualifications_emptyTitle => '承認待ちの資格はありません';

  @override
  String get adminQualifications_imageLoadError => '画像を読み込めませんでした';

  @override
  String get adminQualifications_loadError => '読み込みに失敗しました';

  @override
  String get adminQualifications_noName => '名前なし';

  @override
  String get adminQualifications_pendingApproval => '承認待ち';

  @override
  String get adminQualifications_reject => '却下';

  @override
  String get adminQualifications_rejectButton => '却下する';

  @override
  String get adminQualifications_rejectError => '却下に失敗しました';

  @override
  String get adminQualifications_rejectReasonHint => '却下の理由を入力してください';

  @override
  String get adminQualifications_rejectReasonRequired => '却下理由を入力してください';

  @override
  String get adminQualifications_rejectReasonTitle => '却下理由';

  @override
  String adminQualifications_rejectSuccess(String name) {
    return '$nameを却下しました';
  }

  @override
  String get adminQualifications_title => '資格承認';

  @override
  String get adminSearch_hint => '検索…';

  @override
  String get adminUsers => 'ユーザー管理';

  @override
  String get agreeToPrivacy => 'プライバシーポリシーに同意する';

  @override
  String get agreeToTerms => '利用規約に同意する';

  @override
  String get allPrefectures => '全国';

  @override
  String get alreadyApplied => '応募済み';

  @override
  String get amount => '金額';

  @override
  String get appName => 'ALBAWORK';

  @override
  String get appTagline => '建設業界の仕事マッチングアプリ';

  @override
  String get appleLoginSuccess => 'Appleでログインしました';

  @override
  String get applicant => '応募者';

  @override
  String get applicationConfirm => 'この案件に応募しますか？';

  @override
  String get applicationDate => '応募日';

  @override
  String get applicationSuccess => '応募が完了しました';

  @override
  String get apply => '応募する';

  @override
  String get applyForJob => 'この案件に応募する';

  @override
  String get asyncValue_errorOccurred => 'エラーが発生しました';

  @override
  String get asyncValue_loadFailed => 'ネットワークエラーが発生しました';

  @override
  String get asyncValue_networkError => '権限がありません';

  @override
  String get asyncValue_permissionDenied => 'エラーが発生しました';

  @override
  String get authError => '認証エラーが発生しました';

  @override
  String get authGate_authError => '認証処理中にエラーが発生しました\nもう一度お試しください';

  @override
  String get authGate_roleError => 'ユーザー情報の取得に失敗しました';

  @override
  String get back => '戻る';

  @override
  String get birthDate => '生年月日';

  @override
  String get cameraPermissionRequired => 'カメラの許可が必要です';

  @override
  String get cancel => 'キャンセル';

  @override
  String get changeName => '名前を変更';

  @override
  String get changePassword => 'パスワードを変更';

  @override
  String get chatRoom_attachImage => '画像を添付';

  @override
  String get chatRoom_imageSendFailed => '画像の送信に失敗しました';

  @override
  String get chatRoom_inputHint => 'メッセージを入力';

  @override
  String get chatRoom_loadError => '読み込みエラー';

  @override
  String get chatRoom_loginRequired => 'チャットの準備ができていません';

  @override
  String get chatRoom_notReady => 'チャットの準備ができていません';

  @override
  String get chatRoom_pickFromGallery => 'ギャラリーから選択';

  @override
  String get chatRoom_read => '既読';

  @override
  String get chatRoom_retry => '再試行';

  @override
  String get chatRoom_sendFailed => 'メッセージの送信に失敗しました';

  @override
  String get chatRoom_startConversation => 'メッセージを始めましょう';

  @override
  String get chatRoom_takePhoto => 'カメラで撮影';

  @override
  String get chatRoom_title => 'チャット';

  @override
  String get chatRoom_today => '今日';

  @override
  String get chatRoom_uploadFailed => '画像のアップロードに失敗しました';

  @override
  String get chatRoom_yesterday => '今日';

  @override
  String get chatWith => 'チャット';

  @override
  String get checkIn => '出勤';

  @override
  String get checkInSuccess => '出勤しました';

  @override
  String get checkOut => '退勤';

  @override
  String get checkOutSuccess => '退勤しました';

  @override
  String get checkedIn => '出勤済み';

  @override
  String get checkedOut => '退勤済み';

  @override
  String get close => '閉じる';

  @override
  String get common_adminOnlyView => '管理者のみ閲覧できます';

  @override
  String get common_all => 'すべて';

  @override
  String get common_approve => '承認';

  @override
  String get common_cancel => 'キャンセル';

  @override
  String get common_completed => '完了';

  @override
  String get common_confirmed => '確定済み';

  @override
  String get common_dataLoadError => 'データの読み込みに失敗しました';

  @override
  String get common_delete => '削除';

  @override
  String get common_deleted => '削除しました';

  @override
  String get common_edit => '編集';

  @override
  String get common_itemsCount => '件';

  @override
  String get common_job => '案件';

  @override
  String common_loadError(String error) {
    return '読み込みエラー: $error';
  }

  @override
  String get common_noTitle => 'タイトルなし';

  @override
  String get common_notSet => '未設定';

  @override
  String get common_ok => 'OK';

  @override
  String get common_pleaseLogin => 'ログインしてください';

  @override
  String get common_registerToSaveFavorites => 'お気に入りを保存するには会員登録が必要です';

  @override
  String get common_registerToStart => '登録して始める';

  @override
  String get common_registering => '登録中…';

  @override
  String get common_reject => '却下';

  @override
  String get common_save => '保存';

  @override
  String get common_select => '選択';

  @override
  String get common_selected => '（選択中）';

  @override
  String get common_transferred => '振込済み';

  @override
  String get common_undecided => '未定';

  @override
  String get common_unknown => '不明';

  @override
  String get confirm => '確認';

  @override
  String get confirmPassword => 'パスワード確認';

  @override
  String get contactBody => 'お問い合わせ内容';

  @override
  String get contactCategory => 'カテゴリ';

  @override
  String get contactCategoryBug => '不具合報告';

  @override
  String get contactCategoryFeature => '機能要望';

  @override
  String get contactCategoryGeneral => '一般';

  @override
  String get contactCategoryOther => 'その他';

  @override
  String get contactCategoryPayment => 'お支払い';

  @override
  String get contactSent => 'お問い合わせを送信しました';

  @override
  String get contactSubject => '件名';

  @override
  String get contactTitle => 'お問い合わせ';

  @override
  String get contact_bodyHint => 'お問い合わせ内容を入力してください';

  @override
  String get contact_bodyLabel => '送信する';

  @override
  String get contact_categoryAccount => 'アカウントについて';

  @override
  String get contact_categoryBug => '不具合・バグ報告';

  @override
  String get contact_categoryGeneral => 'その他';

  @override
  String get contact_categoryJobs => '案件について';

  @override
  String get contact_categoryLabel => '件名を入力';

  @override
  String get contact_categoryOther => 'その他';

  @override
  String get contact_categoryPayment => '報酬・支払いについて';

  @override
  String get contact_sendError => 'カテゴリ';

  @override
  String get contact_sendSuccess => 'お問い合わせ';

  @override
  String get contact_subjectHint => '送信する';

  @override
  String get contact_subjectLabel => 'お問い合わせ内容を入力してください';

  @override
  String get contact_submitButton => '送信する';

  @override
  String get contact_title => '件名';

  @override
  String get contact_validationError => 'お問い合わせを送信しました。ご回答までお待ちください。';

  @override
  String get createEarnings => '売上を登録';

  @override
  String get currentPassword => '現在のパスワード';

  @override
  String get dataExportSuccess => 'データをエクスポートしました';

  @override
  String get dateSelect => '日付を選択';

  @override
  String get delete => '削除';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get deleteAccountConfirm => 'アカウントを削除しますか？この操作は取り消せません。';

  @override
  String get deleteAccountSuccess => 'アカウントを削除しました';

  @override
  String get deleteAccountTitle => 'アカウント削除';

  @override
  String get deleteJobConfirm => 'この案件を削除しますか？';

  @override
  String get dispatchLaw => '労働者派遣法について';

  @override
  String get displayName => '表示名';

  @override
  String get downloadData => 'データをダウンロード';

  @override
  String get earningsCreate_adminOnly => 'Stripe決済は管理者のみ利用できます';

  @override
  String get earningsCreate_amountHint => '例: 15000';

  @override
  String get earningsCreate_amountLabel => '金額（税込）';

  @override
  String get earningsCreate_applicantUidEmpty => '応募者UIDが空です';

  @override
  String get earningsCreate_earningRegistered => '売上を登録しました';

  @override
  String get earningsCreate_earningsNote => '※ 売上は管理者が確認後に反映されます';

  @override
  String get earningsCreate_enterAmount => '金額を入力してください';

  @override
  String get earningsCreate_enterAmountExample => '金額を入力してください（例: 15000）';

  @override
  String get earningsCreate_noAssignedJobs => '担当案件がありません';

  @override
  String get earningsCreate_paymentDateLabel => '支払日';

  @override
  String get earningsCreate_registerButton => '売上を登録';

  @override
  String earningsCreate_registerFailed(String error) {
    return '登録に失敗しました: $error';
  }

  @override
  String get earningsCreate_searchHint => '案件を検索…';

  @override
  String get earningsCreate_selectFromList => '上のリストから案件を選んでください';

  @override
  String get earningsCreate_selectJob => '先に案件を選んでください';

  @override
  String get earningsCreate_selectPaymentDate => '支払日を選択してください';

  @override
  String earningsCreate_stripeCreated(String paymentId) {
    return 'Stripe決済を作成しました (ID: $paymentId)';
  }

  @override
  String earningsCreate_stripeFailed(String error) {
    return 'Stripe決済に失敗: $error';
  }

  @override
  String get earningsCreate_stripePayButton => 'Stripe決済を作成';

  @override
  String get earningsCreate_title => '売上登録';

  @override
  String get earningsCreated => '売上を登録しました';

  @override
  String get earningsDetail => '売上詳細';

  @override
  String get edit => '編集';

  @override
  String get editProfile => 'プロフィール編集';

  @override
  String get ekycApproveConfirm => 'この本人確認を承認しますか？';

  @override
  String get ekycApproved => '本人確認が承認されました';

  @override
  String get ekycDocumentType => '身分証の種類';

  @override
  String get ekycDriversLicense => '運転免許証';

  @override
  String get ekycMyNumber => 'マイナンバーカード';

  @override
  String get ekycPassport => 'パスポート';

  @override
  String get ekycPendingReview => '本人確認申請';

  @override
  String get ekycRejectConfirm => 'この本人確認を却下しますか？';

  @override
  String get ekycRejected => '本人確認が却下されました';

  @override
  String get ekycRejectionReason => '却下理由';

  @override
  String get ekycResidenceCard => '在留カード';

  @override
  String get ekycResubmit => '再申請する';

  @override
  String get ekycTitle => '本人確認';

  @override
  String get email => 'メールアドレス';

  @override
  String get emailAlreadyInUse => 'このメールアドレスは既に登録されています';

  @override
  String emailAuthDialog_authError(String code) {
    return '認証エラー: $code';
  }

  @override
  String get emailAuthDialog_emailAlreadyInUse => 'このメールアドレスは既に使用されています';

  @override
  String get emailAuthDialog_emailLabel => 'メールアドレス';

  @override
  String get emailAuthDialog_enterEmailAndPassword => 'メールアドレスとパスワードを入力してください';

  @override
  String get emailAuthDialog_hidePassword => 'パスワードを非表示';

  @override
  String get emailAuthDialog_invalidEmail => 'メールアドレスの形式が正しくありません';

  @override
  String get emailAuthDialog_loginButton => 'ログイン';

  @override
  String get emailAuthDialog_loginFailed => 'ログインに失敗しました';

  @override
  String get emailAuthDialog_loginLocked => 'ログイン試行回数が上限に達しました。しばらくお待ちください';

  @override
  String get emailAuthDialog_loginSuccess => 'ログインしました';

  @override
  String get emailAuthDialog_operationNotAllowed => 'この認証方法は現在利用できません';

  @override
  String get emailAuthDialog_passwordLabel => 'パスワード';

  @override
  String get emailAuthDialog_passwordMinLength => 'パスワードは6文字以上にしてください';

  @override
  String get emailAuthDialog_showPassword => 'パスワードを表示';

  @override
  String get emailAuthDialog_signUpButton => '新規登録';

  @override
  String get emailAuthDialog_signUpFailed => 'アカウント作成に失敗しました';

  @override
  String get emailAuthDialog_signUpHint => 'アカウントをお持ちでない場合は「新規登録」を押してください';

  @override
  String get emailAuthDialog_signUpSuccess => 'アカウントを作成しました';

  @override
  String get emailAuthDialog_title => 'メールアドレスでログイン';

  @override
  String get emailAuthDialog_weakPassword => 'パスワードが弱すぎます。6文字以上にしてください';

  @override
  String get emailAuthDialog_wrongCredentials => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get emailAuth_cancel => 'キャンセル';

  @override
  String get emailAuth_emailInvalid => 'メールアドレスの形式が正しくありません';

  @override
  String get emailAuth_emailLabel => 'メールアドレス';

  @override
  String get emailAuth_emailRequired => 'メールアドレスを入力してください';

  @override
  String get emailAuth_errorEmailInUse => 'このメールアドレスは既に登録されています';

  @override
  String emailAuth_errorGeneric(String code) {
    return 'エラーが発生しました（$code）';
  }

  @override
  String get emailAuth_errorInvalidEmail => 'メールアドレスの形式が正しくありません';

  @override
  String get emailAuth_errorNetwork => 'ネットワーク接続を確認してください';

  @override
  String get emailAuth_errorTooManyRequests => 'リクエストが多すぎます。しばらくしてからお試しください';

  @override
  String get emailAuth_errorUserDisabled => 'このアカウントは無効化されています';

  @override
  String get emailAuth_errorUserNotFound => 'アカウントが見つかりません';

  @override
  String get emailAuth_errorWeakPassword => 'パスワードが弱すぎます。6文字以上で設定してください';

  @override
  String get emailAuth_errorWrongPassword => 'パスワードが正しくありません';

  @override
  String get emailAuth_forgotPassword => 'パスワードを忘れた方';

  @override
  String get emailAuth_loginButton => 'ログイン';

  @override
  String get emailAuth_passwordConfirmLabel => 'パスワード（確認）';

  @override
  String get emailAuth_passwordConfirmRequired => 'パスワードを再入力してください';

  @override
  String get emailAuth_passwordLabel => 'パスワード';

  @override
  String get emailAuth_passwordMinLength => 'パスワードは6文字以上で入力してください';

  @override
  String get emailAuth_passwordMismatch => 'パスワードが一致しません';

  @override
  String get emailAuth_passwordRequired => 'パスワードを入力してください';

  @override
  String get emailAuth_passwordResetTitle => 'パスワードリセット';

  @override
  String get emailAuth_passwordWithMinLength => 'パスワード（6文字以上）';

  @override
  String get emailAuth_registerButton => '新規登録';

  @override
  String get emailAuth_sendButton => '送信';

  @override
  String get emailAuth_snackLoginFailed => 'ログインに失敗しました';

  @override
  String get emailAuth_snackRegisterFailed => '登録に失敗しました';

  @override
  String get emailAuth_snackResetSent => 'パスワードリセットメールを送信しました';

  @override
  String get emailAuth_snackSendFailed => '送信に失敗しました';

  @override
  String get emailAuth_tabLogin => 'ログイン';

  @override
  String get emailAuth_tabRegister => '新規登録';

  @override
  String get emailAuth_title => 'メールアドレスで続ける';

  @override
  String get employer => '雇用主';

  @override
  String get employmentSecurityLaw => '職業安定法について';

  @override
  String get errorDataNotFound => 'データが見つかりません';

  @override
  String get errorDefaultMessage => 'しばらく経ってからもう一度お試しください';

  @override
  String get errorGeneric => 'エラーが発生しました';

  @override
  String get errorLabel => 'エラー';

  @override
  String get errorNetwork => 'ネットワークエラーが発生しました';

  @override
  String get errorNetworkMessage => 'インターネット接続を確認して\nもう一度お試しください';

  @override
  String get errorNetworkTitle => 'ネットワークエラー';

  @override
  String get errorRetry_emptyMessage => '条件を変更して再検索してください';

  @override
  String get errorRetry_emptyTitle => 'データが見つかりません';

  @override
  String get errorRetry_generalMessage => '予期しないエラーが発生しました';

  @override
  String get errorRetry_generalTitle => 'エラーが発生しました';

  @override
  String get errorRetry_networkErrorMessage => 'インターネット接続を確認してください';

  @override
  String get errorRetry_networkErrorTitle => 'ネットワークエラー';

  @override
  String get errorRetry_timeoutMessage => '通信がタイムアウトしました。再試行してください';

  @override
  String get errorRetry_timeoutTitle => 'タイムアウト';

  @override
  String get errorSearchRetry => '条件を変更して再検索してください';

  @override
  String get errorTimeout => 'タイムアウト';

  @override
  String get errorTimeoutMessage => 'サーバーへの接続に時間がかかっています\nもう一度お試しください';

  @override
  String get experienceYears => '経験年数';

  @override
  String get familyName => '姓';

  @override
  String get familyNameKana => '姓（カナ）';

  @override
  String get faqTitle => 'よくある質問';

  @override
  String get faq_a1 => 'ALBAWORKとは何ですか？';

  @override
  String get faq_a2 => 'ALBAWORKとは何ですか？';

  @override
  String get faq_a3 => '利用料金はかかりますか？';

  @override
  String get faq_a4 => '応募するにはどうすればいいですか？';

  @override
  String get faq_a5 => '出退勤はどのように記録しますか？';

  @override
  String get faq_a6 => '報酬はどのように受け取れますか？';

  @override
  String get faq_a7 => '本人確認は必要ですか？';

  @override
  String get faq_a8 => '退会するにはどうすればいいですか？';

  @override
  String get faq_q1 => 'ALBAWORKとは何ですか？';

  @override
  String get faq_q2 => 'ALBAWORKとは何ですか？';

  @override
  String get faq_q3 => '利用料金はかかりますか？';

  @override
  String get faq_q4 => '応募するにはどうすればいいですか？';

  @override
  String get faq_q5 => '出退勤はどのように記録しますか？';

  @override
  String get faq_q6 => '報酬はどのように受け取れますか？';

  @override
  String get faq_q7 => '本人確認は必要ですか？';

  @override
  String get faq_q8 => '退会するにはどうすればいいですか？';

  @override
  String get faq_title => 'よくある質問';

  @override
  String get favorites_empty => 'お気に入りはまだありません';

  @override
  String get favorites_emptyDescription => '気になる案件をお気に入りに追加してみましょう';

  @override
  String get favorites_loginRequired => 'ログインが必要です';

  @override
  String get favorites_noTitle => 'タイトルなし';

  @override
  String get favorites_title => 'お気に入り案件';

  @override
  String get featureQuickEarn => 'すぐに稼げる';

  @override
  String get featureSearch => '仕事を探す';

  @override
  String get featureSecurePayment => '安心の支払い';

  @override
  String get filterByPrefecture => '都道府県で絞り込み';

  @override
  String get forceUpdate_available => 'アップデートが必要です';

  @override
  String get forceUpdate_availableMessage => '最新バージョンにアップデートしてください。';

  @override
  String get forceUpdate_later => 'あとで';

  @override
  String get forceUpdate_required => 'アップデートが必要です';

  @override
  String get forceUpdate_requiredMessage => '最新バージョンにアップデートしてください。';

  @override
  String get forceUpdate_update => 'アップデート';

  @override
  String get forgotPassword => 'パスワードを忘れた方';

  @override
  String get gender => '性別';

  @override
  String get genderFemale => '女性';

  @override
  String get genderMale => '男性';

  @override
  String get genderOther => 'その他';

  @override
  String get getStarted => '始める';

  @override
  String get givenName => '名';

  @override
  String get givenNameKana => '名（カナ）';

  @override
  String get guestCannotApply => 'ゲストは応募できません。ログインしてください';

  @override
  String get guestHome_agreeByLogin => 'ログインすることで利用規約・プライバシーポリシーに同意したものとみなします';

  @override
  String get guestHome_appleLoginSuccess => 'Appleでログインしました';

  @override
  String get guestHome_emailLogin => 'メールアドレスでログイン';

  @override
  String get guestHome_featureEarn => 'すぐに稼げる';

  @override
  String get guestHome_featurePayment => '安心の支払い';

  @override
  String get guestHome_featureSearch => '仕事を探す';

  @override
  String get guestHome_guestLoginSuccess => 'ゲストとしてログインしました';

  @override
  String get guestHome_lineLogin => 'LINEでログイン';

  @override
  String get guestHome_phoneLogin => '電話番号でログイン';

  @override
  String get guestHome_privacyPolicy => 'プライバシーポリシー';

  @override
  String get guestHome_startAsGuest => 'ゲストとして始める';

  @override
  String get guestHome_subtitle => '建設業界の仕事マッチングアプリ';

  @override
  String get guestHome_termsOfService => '利用規約';

  @override
  String get guestLoginSuccess => 'ゲストとしてログインしました';

  @override
  String get guestModeWarning => 'ゲストモードでは一部機能が制限されます';

  @override
  String get hidePassword => 'パスワードを非表示';

  @override
  String get home_admin => '管理者';

  @override
  String get home_greetingAfternoon => 'こんにちは';

  @override
  String get home_greetingEvening => 'こんばんは';

  @override
  String get home_greetingMorning => 'おはようございます';

  @override
  String get home_navMessages => 'メッセージ';

  @override
  String get home_navProfile => 'プロフィール';

  @override
  String get home_navSales => '収入';

  @override
  String get home_navSearch => '検索';

  @override
  String get home_navSelected => '、選択中';

  @override
  String home_navTabLabel(String label, String suffix) {
    return '$labelタブ$suffix';
  }

  @override
  String get home_navWork => 'はたらく';

  @override
  String home_notifications(String count) {
    return 'お知らせ、未読$count件';
  }

  @override
  String home_notificationsUnread(String count) {
    return 'お知らせ、未読$count件';
  }

  @override
  String get home_postJob => '案件を投稿';

  @override
  String get home_statusAdmin => 'ステータス: 管理者';

  @override
  String get identityVerification => '本人確認';

  @override
  String get identityVerification_documentTypeLabel => '書類の種類';

  @override
  String get identityVerification_ekycBanner =>
      '提出された書類はeKYC（オンライン本人確認）に基づき、管理者が審査します。';

  @override
  String get identityVerification_idDocumentSubtitle => '運転免許証・マイナンバーカード等';

  @override
  String get identityVerification_idDocumentTitle => '身分証明書';

  @override
  String get identityVerification_instructions =>
      '本人確認のため、身分証明書の写真と自撮り写真をアップロードしてください。';

  @override
  String get identityVerification_loadStatusFailed => '本人確認ステータスの読み込みに失敗しました';

  @override
  String identityVerification_rejectionReason(String reason) {
    return '理由: $reason';
  }

  @override
  String get identityVerification_resubmitButton => '再申請する';

  @override
  String get identityVerification_selfieSubtitle => '顔全体が写るように撮影してください';

  @override
  String get identityVerification_selfieTitle => '自撮り写真';

  @override
  String get identityVerification_statusApproved => '本人確認が完了しました';

  @override
  String get identityVerification_statusPending => '審査中です。しばらくお待ちください';

  @override
  String get identityVerification_statusRejected => '本人確認が却下されました';

  @override
  String get identityVerification_stepSelfie => '自撮り';

  @override
  String get identityVerification_stepSubmit => '申請';

  @override
  String get identityVerification_stepUploadId => '身分証';

  @override
  String get identityVerification_submitButton => '本人確認を申請する';

  @override
  String identityVerification_submitFailed(String error) {
    return '申請に失敗しました: $error';
  }

  @override
  String get identityVerification_submitted => '本人確認を申請しました。審査をお待ちください';

  @override
  String get identityVerification_tapToSelect => 'タップして選択';

  @override
  String get identityVerification_title => '本人確認';

  @override
  String get identityVerification_uploadBoth => '身分証明書と自撮り写真の両方をアップロードしてください';

  @override
  String get imagePicker_camera => 'カメラで撮影';

  @override
  String get imagePicker_cancel => 'キャンセル';

  @override
  String get imagePicker_error => 'エラーが発生しました';

  @override
  String get imagePicker_gallery => 'ギャラリーから選択（複数可）';

  @override
  String get imagePicker_galleryMultiple => 'ギャラリーから選択（複数可）';

  @override
  String get imagePicker_noImageSelected => '画像が選択されませんでした';

  @override
  String get imagePicker_selectImage => '画像を選択';

  @override
  String imagePicker_uploadPartial(String successCount, String failedCount) {
    return '$successCount枚成功、$failedCount枚失敗しました';
  }

  @override
  String imagePicker_uploadSuccess(String count) {
    return '$count枚の画像をアップロードしました';
  }

  @override
  String get imagePicker_uploaded => '画像をアップロードしました';

  @override
  String get inspection_checklist => 'チェックリスト';

  @override
  String inspection_completedLog(String result) {
    return '検査完了: $result';
  }

  @override
  String get inspection_fail => '検査合格 → 完了';

  @override
  String get inspection_failedFixRequest => '検査合格 → 完了';

  @override
  String get inspection_needsFix => '要是正';

  @override
  String get inspection_overallComment => '総合コメント';

  @override
  String get inspection_pass => '合格';

  @override
  String get inspection_passed => '合格';

  @override
  String get inspection_passedComplete => '検査合格 → 完了';

  @override
  String inspection_submitFailed(String error) {
    return '検査提出に失敗: $error';
  }

  @override
  String get inspection_submitResult => '検査結果を提出';

  @override
  String get inspection_title => '施工検査';

  @override
  String get introduction => '自己紹介';

  @override
  String get invalidEmail => 'メールアドレスの形式が正しくありません';

  @override
  String get inviteFriends => '友達を招待';

  @override
  String get inviteFriendsSubtitle => '紹介コードで友達を招待';

  @override
  String itemCount(String count) {
    return '$count件';
  }

  @override
  String get jobCard_actions => '操作';

  @override
  String get jobCard_addFavorite => 'お気に入りから削除';

  @override
  String get jobCard_delete => '編集';

  @override
  String get jobCard_edit => '編集';

  @override
  String get jobCard_noOwnerId => 'ownerIdなし';

  @override
  String get jobCard_perDay => ' /日';

  @override
  String get jobCard_quickStart => '即日勤務OK';

  @override
  String jobCard_remainingSlots(String count) {
    return '残り$count枠';
  }

  @override
  String get jobCard_removeFavorite => 'お気に入りから削除';

  @override
  String jobCard_semanticsLabel(
    String title,
    String location,
    String date,
    String price,
  ) {
    return '$title、場所: $location、日程: $date、報酬: $price';
  }

  @override
  String get jobCreateTitle => '案件作成';

  @override
  String get jobDate => '勤務日';

  @override
  String get jobDeleted => '案件を削除しました';

  @override
  String get jobDescription => '仕事内容';

  @override
  String get jobDetail => '案件詳細';

  @override
  String get jobDetail_addToFavorites => 'お気に入りに追加';

  @override
  String jobDetail_applicationReceived(String projectName) {
    return '$projectNameに応募がありました';
  }

  @override
  String get jobDetail_applied => '応募済み';

  @override
  String get jobDetail_applyButton => '応募する';

  @override
  String get jobDetail_applyError => '応募に失敗しました';

  @override
  String get jobDetail_applyToJob => '案件応募';

  @override
  String get jobDetail_applyToThisJob => 'この案件に応募する';

  @override
  String get jobDetail_category => 'カテゴリ';

  @override
  String get jobDetail_checking => '確認中...';

  @override
  String get jobDetail_checkingStatus => '確認中...';

  @override
  String get jobDetail_defaultDescription => '詳細情報はまだ登録されていません。';

  @override
  String get jobDetail_defaultNotes => '特記事項はありません。';

  @override
  String get jobDetail_deleteConfirmMessage => 'この案件を削除してよろしいですか？この操作は取り消せません。';

  @override
  String get jobDetail_deleteConfirmTitle => '案件を削除';

  @override
  String get jobDetail_deleteError => '削除に失敗しました';

  @override
  String get jobDetail_deleteThisJob => 'この案件を削除';

  @override
  String get jobDetail_favorite => 'お気に入り';

  @override
  String get jobDetail_jobDescription => '仕事内容';

  @override
  String get jobDetail_legacyData => '旧データ';

  @override
  String get jobDetail_locationLabel => '場所';

  @override
  String get jobDetail_mayBeDeleted => 'この案件は削除された可能性があります';

  @override
  String get jobDetail_newApplication => '新しい応募';

  @override
  String get jobDetail_notes => '備考・注意事項';

  @override
  String get jobDetail_paymentLabel => '報酬';

  @override
  String get jobDetail_removeFromFavorites => 'お気に入りから削除';

  @override
  String get jobDetail_scheduleLabel => '日程';

  @override
  String get jobDetail_share => '共有';

  @override
  String get jobDetail_snackApplied => '応募が完了しました';

  @override
  String get jobDetail_status => 'ステータス';

  @override
  String get jobDetail_title => '案件詳細';

  @override
  String get jobEditTitle => '案件編集';

  @override
  String get jobEdit_dateHint => 'タップして日付を選択';

  @override
  String get jobEdit_dateLabel => '日程';

  @override
  String get jobEdit_datePickerCancel => 'キャンセル';

  @override
  String get jobEdit_datePickerConfirm => '決定';

  @override
  String get jobEdit_datePickerHelp => '日程を選択';

  @override
  String get jobEdit_descriptionHint => '例）現場作業の補助、清掃、資材運搬など';

  @override
  String get jobEdit_descriptionLabel => '仕事内容';

  @override
  String get jobEdit_hintBody =>
      '更新後は一覧に戻ります。日程はカレンダーから選択できます。緯度・経度を設定するとQR出退勤時のGPS検証が有効になります。';

  @override
  String get jobEdit_hintTitle => 'ヒント';

  @override
  String get jobEdit_latitudeHint => '例）35.6812';

  @override
  String get jobEdit_latitudeLabel => '緯度（任意）';

  @override
  String get jobEdit_locationHint => '例）千葉県千葉市花見川区';

  @override
  String get jobEdit_locationLabel => '場所';

  @override
  String get jobEdit_longitudeHint => '例）139.7671';

  @override
  String get jobEdit_longitudeLabel => '経度（任意）';

  @override
  String get jobEdit_notesHint => '例）遅刻厳禁、安全第一、詳細はチャットで確認など';

  @override
  String get jobEdit_notesLabel => '注意事項';

  @override
  String get jobEdit_priceHint => '例）30000';

  @override
  String get jobEdit_priceLabel => '報酬（円）';

  @override
  String get jobEdit_sectionSubtitle => '案件の情報を更新してください';

  @override
  String get jobEdit_sectionTitle => '編集内容';

  @override
  String get jobEdit_snackEmptyFields => '未入力の項目があります';

  @override
  String get jobEdit_snackPriceNumeric => '金額は数字で入力してください';

  @override
  String get jobEdit_snackSelectDateFromCalendar => '日程はカレンダーから選択してください';

  @override
  String jobEdit_snackUpdateFailed(String error) {
    return '更新に失敗しました: $error';
  }

  @override
  String get jobEdit_title => '案件を編集';

  @override
  String get jobEdit_titleHint => '例）クロス張替え（1LDK）';

  @override
  String get jobEdit_titleLabel => 'タイトル';

  @override
  String get jobEdit_updateButton => '更新する';

  @override
  String get jobFilter_areaHint => 'エリアを選択';

  @override
  String get jobFilter_areaLabel => 'エリア';

  @override
  String get jobFilter_dateRange => '日程';

  @override
  String get jobFilter_dateSeparator => '〜';

  @override
  String get jobFilter_endDate => '終了日';

  @override
  String get jobFilter_priceRange => '報酬範囲';

  @override
  String get jobFilter_qualBuildingManagement => '建築施工管理技士';

  @override
  String get jobFilter_qualCivilEngineering => '土木施工管理技士';

  @override
  String get jobFilter_qualElectrician => '電気工事士';

  @override
  String get jobFilter_qualForklift => 'フォークリフト運転者';

  @override
  String get jobFilter_qualHazmat => '危険物取扱者';

  @override
  String get jobFilter_qualScaffolding => '建築施工管理';

  @override
  String get jobFilter_qualSlinging => '玉掛け技能者';

  @override
  String get jobFilter_qualWelding => '溶接技能者';

  @override
  String get jobFilter_requiredQualifications => '必要資格';

  @override
  String get jobFilter_reset => 'リセット';

  @override
  String get jobFilter_searchButton => '検索する';

  @override
  String get jobFilter_startDate => '開始日';

  @override
  String get jobFilter_title => '絞り込み検索';

  @override
  String get jobListTitle => '仕事一覧';

  @override
  String get jobList_dataLoadError => 'データの読み込みに失敗しました';

  @override
  String get jobList_deleteConfirmMessage => 'この案件を削除してよろしいですか？この操作は取り消せません。';

  @override
  String get jobList_deleteConfirmTitle => '案件を削除';

  @override
  String get jobList_deleteError => '削除に失敗しました';

  @override
  String get jobList_fetchJobsError => '案件情報の取得に失敗しました';

  @override
  String get jobList_filter => 'フィルタ';

  @override
  String get jobList_filterActiveLabel => 'フィルタ適用中';

  @override
  String get jobList_locationError => '位置情報の取得に失敗しました';

  @override
  String get jobList_monthLabel => 'すべて';

  @override
  String get jobList_nextMonth => '来月';

  @override
  String get jobList_noJobs => '案件がありません';

  @override
  String get jobList_noJobsDescription => '現在、この条件に該当する案件はありません。';

  @override
  String get jobList_noMatchingJobs => '該当する案件がありません';

  @override
  String get jobList_noMatchingJobsDescription => '条件を変更して再度検索してください。';

  @override
  String get jobList_openSearchFilter => '検索フィルタを開く';

  @override
  String get jobList_prefChiba => '千葉県';

  @override
  String get jobList_prefKanagawa => '神奈川県';

  @override
  String get jobList_prefOther => 'その他';

  @override
  String get jobList_prefTokyo => '東京都';

  @override
  String get jobList_searchByAreaCondition => 'エリア・条件で検索';

  @override
  String get jobList_sortDistance => '距離順';

  @override
  String get jobList_sortHighestPay => '金額が高い順';

  @override
  String get jobList_sortNewest => '新着順';

  @override
  String get jobList_sortTooltip => '並べ替え';

  @override
  String get jobList_thisMonth => '今月';

  @override
  String get jobList_viewOnMap => 'マップで見る';

  @override
  String get jobList_viewGrid => 'グリッド表示に切替';

  @override
  String get jobList_viewList => 'リスト表示に切替';

  @override
  String get jobList_viewOnMapAccessibility => '地図で案件を見る';

  @override
  String get jobLocation => '勤務地';

  @override
  String get jobNotes => '備考';

  @override
  String get jobOverview => '概要';

  @override
  String get jobPrice => '報酬';

  @override
  String get jobSaved => '案件を保存しました';

  @override
  String get jobTitle => '案件名';

  @override
  String get laborInsurance => '労災保険について';

  @override
  String get legalCompliance => '法令遵守';

  @override
  String get legalDocuments => '法的ドキュメント';

  @override
  String get legalIndex => '法的情報';

  @override
  String get legalIndex_compliance => '法令遵守';

  @override
  String get legalIndex_dispatchLaw => '労働者派遣法について';

  @override
  String get legalIndex_employmentSecurityLaw => '職業安定法について';

  @override
  String get legalIndex_laborInsurance => '労災保険について';

  @override
  String get legalIndex_legalDocuments => '法的ドキュメント';

  @override
  String get legalIndex_privacyPolicy => 'プライバシーポリシー';

  @override
  String get legalIndex_termsOfService => '利用規約';

  @override
  String get legalIndex_title => '法的情報';

  @override
  String get legalInfo => '法的情報';

  @override
  String get legalInfoSubtitle => 'プライバシーポリシー・利用規約・法令情報';

  @override
  String get loadMore => 'もっと見る';

  @override
  String get loadMore_showMore => 'もっと表示';

  @override
  String get loading => '読み込み中...';

  @override
  String get locationPermissionRequired => '位置情報の許可が必要です';

  @override
  String get login => 'ログイン';

  @override
  String get loginSuccess => 'ログインしました';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutConfirm => 'ログアウトしますか？';

  @override
  String get logoutSuccess => 'ログアウトしました';

  @override
  String get mapSearch_details => '詳細';

  @override
  String get mapSearch_noJobs => '地図に表示できる案件がありません';

  @override
  String get mapSearch_noTitle => 'タイトルなし';

  @override
  String get mapSearch_notSet => 'タイトルなし';

  @override
  String mapSearch_pricePerDay(String price) {
    return '¥$price /日';
  }

  @override
  String get mapSearch_title => '地図で探す';

  @override
  String get markAsRead => '既読にする';

  @override
  String get messagesTitle => 'メッセージ';

  @override
  String get messages_emptyAdmin => 'チャットルームはまだありません';

  @override
  String get messages_emptyDescription => '案件に応募するとチャットが開始されます';

  @override
  String get messages_emptyUser => 'メッセージはまだありません';

  @override
  String get messages_featureName => 'メッセージ';

  @override
  String get messages_noSearchResults => '検索結果なし';

  @override
  String get messages_registrationRequiredDescription =>
      '会員登録をして、メッセージ機能をご利用ください。';

  @override
  String get messages_registrationRequiredTitle => 'メッセージを利用するには会員登録が必要です';

  @override
  String get messages_searchHint => 'メッセージを検索…';

  @override
  String messages_statusLabel(String status) {
    return 'ステータス: $status';
  }

  @override
  String get messages_title => 'メッセージ';

  @override
  String get messages_titleAdmin => 'メッセージ（管理者）';

  @override
  String get messages_tryDifferentKeyword => '別のキーワードで検索してください';

  @override
  String get myProfile => 'プロフィール';

  @override
  String get myProfile_addQualification => '資格を追加';

  @override
  String get myProfile_addressHint => '例: 東京都渋谷区...';

  @override
  String get myProfile_addressLabel => '住所';

  @override
  String get myProfile_addressSection => '住所';

  @override
  String get myProfile_adminRating => '管理者からの評価';

  @override
  String get myProfile_avatarUpdated => 'プロフィール写真を更新しました';

  @override
  String get myProfile_avatarUploadError => '写真のアップロードに失敗しました';

  @override
  String get myProfile_basicInfo => '基本情報';

  @override
  String get myProfile_birthDate => '生年月日';

  @override
  String get myProfile_birthDateLabel => '生年月日';

  @override
  String get myProfile_completionRate => '完了率';

  @override
  String get myProfile_experienceSkills => '経験・スキル';

  @override
  String get myProfile_experienceYearsHint => '例: 5';

  @override
  String get myProfile_experienceYearsLabel => '経験年数';

  @override
  String get myProfile_familyName => '姓';

  @override
  String get myProfile_familyNameKana => 'セイ';

  @override
  String get myProfile_familyNameKanaLabel => 'セイ（カナ）';

  @override
  String get myProfile_familyNameLabel => '姓';

  @override
  String get myProfile_genderFemale => '女性';

  @override
  String get myProfile_genderLabel => '性別';

  @override
  String get myProfile_genderMale => '男性';

  @override
  String get myProfile_genderNotAnswered => '未回答';

  @override
  String get myProfile_genderOther => 'その他';

  @override
  String get myProfile_genderRequired => '性別を選択してください';

  @override
  String get myProfile_givenName => '名';

  @override
  String get myProfile_givenNameKana => 'メイ';

  @override
  String get myProfile_givenNameKanaLabel => 'メイ（カナ）';

  @override
  String get myProfile_givenNameLabel => '名';

  @override
  String get myProfile_identityVerified => '本人確認済み';

  @override
  String get myProfile_introHint => '得意な作業や経験をアピールしましょう';

  @override
  String get myProfile_introLabel => '自己紹介';

  @override
  String get myProfile_loadError => 'プロフィールの読み込みに失敗しました';

  @override
  String get myProfile_loginRequired => 'ログインが必要です';

  @override
  String get myProfile_loginRequiredMessage =>
      'プロフィール編集にはログインが必要です。設定画面からログインしてください。';

  @override
  String get myProfile_loginRequiredTitle => 'ログインが必要です';

  @override
  String get myProfile_photoSetByVerification => '本人確認後に写真が設定されます';

  @override
  String get myProfile_pickFromGallery => 'ギャラリーから選択';

  @override
  String get myProfile_postalCodeHint => '例: 123-4567';

  @override
  String get myProfile_postalCodeInvalid => '郵便番号の形式が正しくありません';

  @override
  String get myProfile_postalCodeLabel => '郵便番号';

  @override
  String get myProfile_profilePhoto => 'プロフィール写真';

  @override
  String get myProfile_qualificationHint => '資格名を入力';

  @override
  String get myProfile_qualifications => '資格';

  @override
  String get myProfile_qualityScore => '品質スコア';

  @override
  String get myProfile_ratingAverage => '評価平均';

  @override
  String myProfile_requiredField(String label) {
    return '$labelは必須です';
  }

  @override
  String get myProfile_saveButton => '保存する';

  @override
  String get myProfile_saveError => '保存に失敗しました';

  @override
  String get myProfile_saveSuccess => 'プロフィールを保存しました';

  @override
  String get myProfile_selectBirthDate => '生年月日を選択';

  @override
  String get myProfile_selectGender => '性別を選択してください';

  @override
  String get myProfile_stripeActive => 'Stripe連携済み — 報酬の受け取りが可能です';

  @override
  String get myProfile_stripeIntegration => 'Stripe連携';

  @override
  String get myProfile_stripeNotConfigured =>
      'Stripe未設定 — 報酬の受け取りにはStripe連携が必要です';

  @override
  String get myProfile_stripePending => 'Stripe審査中 — 確認が完了するまでお待ちください';

  @override
  String get myProfile_takePhoto => '写真を撮る';

  @override
  String get myProfile_tapToChangePhoto => 'タップして写真を変更';

  @override
  String get myProfile_title => 'プロフィール編集';

  @override
  String get myProfile_verifiedQualifications => '認定資格';

  @override
  String get myProfile_yearsSuffix => '年';

  @override
  String get myProfile_yourRating => 'あなたの評価';

  @override
  String get name => '氏名';

  @override
  String get nameChanged => '名前を変更しました';

  @override
  String get navHome => 'ホーム';

  @override
  String get navMessages => 'メッセージ';

  @override
  String get navMyPage => 'マイページ';

  @override
  String get navProfile => 'プロフィール';

  @override
  String get navSales => '売上';

  @override
  String get navSearch => '検索';

  @override
  String get navWork => '仕事';

  @override
  String get netAmount => '振込金額';

  @override
  String get networkCheckConnection => 'ネットワーク接続を確認してください';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get next => '次へ';

  @override
  String get noData => 'データがありません';

  @override
  String get noEarnings => '売上データがありません';

  @override
  String get noJobsFound => '条件に合う仕事が見つかりません';

  @override
  String get noMessages => 'メッセージはありません';

  @override
  String get noMoreData => 'これ以上データはありません';

  @override
  String get noNotifications => 'お知らせはありません';

  @override
  String get noWork => '現在の仕事はありません';

  @override
  String get notificationSettings => '通知設定';

  @override
  String get notifications => 'お知らせ';

  @override
  String get notifications_allRead => 'すべて既読にしました';

  @override
  String get notifications_empty => 'お知らせはまだありません';

  @override
  String get notifications_emptyDescription => 'お知らせはまだありません';

  @override
  String notifications_error(String error) {
    return 'エラー: $error';
  }

  @override
  String get notifications_loginDescription => 'ログインが必要です';

  @override
  String get notifications_loginRequired => 'お知らせ';

  @override
  String get notifications_markAllRead => 'すべて既読にしました';

  @override
  String get notifications_title => 'お知らせ';

  @override
  String get offlineBanner_connectionRestored => '接続が復旧しました';

  @override
  String get offlineBanner_offlineMode => 'オフラインモード — キャッシュデータを表示中';

  @override
  String get offlineBanner_retry => '再試行';

  @override
  String get onboardingDesc1 => '建設業界の仕事を簡単に検索・応募できます';

  @override
  String get onboardingDesc2 => 'QRコードをスキャンして簡単に出退勤管理';

  @override
  String get onboardingDesc3 => 'Stripe決済で安全・確実に報酬を受け取れます';

  @override
  String get onboardingTitle1 => '仕事を見つけよう';

  @override
  String get onboardingTitle2 => 'QRで出退勤';

  @override
  String get onboardingTitle3 => '安心の支払い';

  @override
  String get onboarding_agreed => '、同意済み';

  @override
  String get onboarding_getStarted => 'アプリを始める';

  @override
  String get onboarding_nextPage => 'アプリを始める';

  @override
  String onboarding_pageIndicator(String current, String total) {
    return 'ページ$current / $total';
  }

  @override
  String get onboarding_privacyPolicy => 'プライバシーポリシー';

  @override
  String get onboarding_skip => 'オンボーディングをスキップ';

  @override
  String get onboarding_termsOfService => '利用規約';

  @override
  String get openSettings => '設定を開く';

  @override
  String get optional => '任意';

  @override
  String get password => 'パスワード';

  @override
  String get passwordChanged => 'パスワードを変更しました';

  @override
  String get passwordResetDescription => '登録されたメールアドレスにリセットリンクを送信します';

  @override
  String get passwordResetSent => 'パスワードリセットメールを送信しました';

  @override
  String get passwordResetTitle => 'パスワードリセット';

  @override
  String get paymentDetail => '決済詳細';

  @override
  String get paymentDetail_createdAt => '作成日時';

  @override
  String get paymentDetail_netAmount => '支払い金額';

  @override
  String get paymentDetail_notFound => '支払い情報が見つかりません';

  @override
  String get paymentDetail_paymentAmount => '案件名';

  @override
  String get paymentDetail_paymentStatus => '受取金額';

  @override
  String get paymentDetail_payoutStatus => '決済ステータス';

  @override
  String get paymentDetail_platformFee => '支払い金額';

  @override
  String get paymentDetail_projectName => '案件名';

  @override
  String get paymentDetail_title => '支払い詳細';

  @override
  String get paymentFailed => '決済失敗';

  @override
  String get paymentPending => '決済待ち';

  @override
  String get paymentStatus => '決済状況';

  @override
  String get paymentSucceeded => '決済完了';

  @override
  String get payoutDate => '支払い日';

  @override
  String get phone => '電話番号';

  @override
  String get phoneAuth_changePhoneNumber => '電話番号を変更する';

  @override
  String phoneAuth_codeSentTo(String phone) {
    return '$phone に送信された6桁のコードを入力してください';
  }

  @override
  String get phoneAuth_enterCode => '認証コードを入力';

  @override
  String get phoneAuth_enterJapaneseNumber => '日本の電話番号を入力してください';

  @override
  String get phoneAuth_enterSixDigitCode => '6桁のコードを入力してください';

  @override
  String get phoneAuth_invalidPhoneNumber => '有効な電話番号を入力してください（10〜11桁）';

  @override
  String get phoneAuth_login => 'ログイン';

  @override
  String get phoneAuth_loginSuccess => 'ログインしました';

  @override
  String get phoneAuth_phoneNumberLabel => '電話番号';

  @override
  String get phoneAuth_resendCode => 'コードを再送信';

  @override
  String phoneAuth_resendCountdown(String seconds) {
    return '再送信まで $seconds秒';
  }

  @override
  String get phoneAuth_restartVerification => '認証コードの送信からやり直してください';

  @override
  String get phoneAuth_sendCode => '認証コードを送信';

  @override
  String get phoneAuth_smsDescription => 'SMSで認証コードを送信します';

  @override
  String get phoneAuth_title => '電話番号でログイン';

  @override
  String get phoneAuth_verificationCodeLabel => '認証コード';

  @override
  String get platformFee => 'プラットフォーム手数料';

  @override
  String get postJob => '案件を投稿';

  @override
  String get postJobSuccess => '案件を投稿しました';

  @override
  String get postJobTitle => '案件を投稿';

  @override
  String get post_dateHint => 'タップして日付を選択';

  @override
  String get post_dateLabel => '日程';

  @override
  String get post_datePickerCancel => 'キャンセル';

  @override
  String get post_datePickerConfirm => '決定';

  @override
  String get post_datePickerHelp => '日程を選択';

  @override
  String get post_hintBody =>
      '日程はカレンダーから選択できます。緯度・経度を入力するとQR出退勤時にGPS検証が有効になります。';

  @override
  String get post_hintTitle => 'ヒント';

  @override
  String get post_latitudeHint => '例）35.6812';

  @override
  String get post_latitudeLabel => '緯度（任意）';

  @override
  String get post_locationHint => '例）千葉県千葉市花見川区';

  @override
  String get post_locationLabel => '場所';

  @override
  String get post_longitudeHint => '例）139.7671';

  @override
  String get post_longitudeLabel => '経度（任意）';

  @override
  String get post_noPermissionMessage => 'この画面は管理者のみ利用できます。';

  @override
  String get post_noPermissionTitle => '権限がありません';

  @override
  String get post_priceHint => '例）30000';

  @override
  String get post_priceLabel => '報酬（円）';

  @override
  String get post_sectionBasicInfo => '基本情報';

  @override
  String get post_sectionBasicInfoSubtitle => '案件の内容を入力してください';

  @override
  String get post_snackAdminOnly => '管理者のみ投稿できます';

  @override
  String get post_snackCheckingPermission => '権限確認中です。少し待ってください。';

  @override
  String get post_snackEmptyFields => '未入力の項目があります';

  @override
  String get post_snackLoginRequired => 'ログインが必要です';

  @override
  String post_snackPostFailed(String error) {
    return '投稿失敗: $error';
  }

  @override
  String get post_snackPriceNumeric => '金額は数字で入力してください';

  @override
  String get post_snackSelectDateFromCalendar => '日程はカレンダーから選択してください';

  @override
  String get post_submitButton => '投稿する';

  @override
  String get post_title => '案件を投稿';

  @override
  String get post_titleHint => '例）クロス張替え（1LDK）';

  @override
  String get post_titleLabel => 'タイトル';

  @override
  String get postalCode => '郵便番号';

  @override
  String get prefecture => '都道府県';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get profilePhotoChange => '写真を変更';

  @override
  String get profileSaved => 'プロフィールを保存しました';

  @override
  String get profileTitle => 'マイページ';

  @override
  String get profileWidgets_guest => 'Guest';

  @override
  String get profileWidgets_loggedIn => 'Logged in';

  @override
  String get profileWidgets_status => 'Status';

  @override
  String get profile_accountSettings => 'アカウント設定';

  @override
  String get profile_adminLogin => '管理者ログイン';

  @override
  String get profile_adminLoginSubtitle => '案件の投稿・編集ができます';

  @override
  String get profile_adminLogout => '管理者ログアウト';

  @override
  String get profile_adminLogoutSubtitle => '現在ログインしていません';

  @override
  String get profile_contact => 'お問い合わせ';

  @override
  String get profile_darkMode => 'ダークモード';

  @override
  String get profile_darkModeDescription =>
      'ダークモードはお使いの端末のシステム設定に連動しています。\\n\\n';

  @override
  String get profile_darkModeSubtitle => 'システム設定に従う';

  @override
  String get profile_darkModeLight => 'ライト';

  @override
  String get profile_darkModeDark => 'ダーク';

  @override
  String get profile_darkModeSystem => 'システム設定に従う';

  @override
  String get profile_faq => 'よくある質問';

  @override
  String get profile_favoriteJobs => 'お気に入り案件';

  @override
  String get profile_favoriteJobsSubtitle => '保存した案件を確認';

  @override
  String get profile_guest => 'ゲスト';

  @override
  String get profile_identityVerification => '本人確認';

  @override
  String get profile_identityVerificationSubtitle => '身分証明書と顔写真を提出';

  @override
  String get profile_inviteFriends => '友達を招待';

  @override
  String get profile_inviteFriendsSubtitle => '紹介コードで友達を招待';

  @override
  String get profile_legalInfo => '法的情報';

  @override
  String get profile_legalInfoSubtitle => 'プライバシーポリシー・利用規約・法令情報';

  @override
  String get profile_lineLoginButton => 'LINEでログイン';

  @override
  String get profile_lineLoginSemanticsLabel => 'LINEアカウントでログインする';

  @override
  String get profile_loggedIn => 'ログインすると応募・チャットが使えます';

  @override
  String get profile_loggedInUser => 'ログインユーザー';

  @override
  String get profile_loginButton => 'ログインする';

  @override
  String get profile_loginPromptSubtitle => 'ログインすると応募・チャットが使えます';

  @override
  String get profile_loginRequired => 'ログインが必要です';

  @override
  String get profile_loginRequiredMessage => '応募・チャットなど一部機能を利用するにはログインが必要です。';

  @override
  String get profile_notLoggedIn => '現在ログインしていません';

  @override
  String get profile_qualifications => '資格管理';

  @override
  String get profile_qualificationsSubtitle => '保有資格の登録・確認';

  @override
  String get profile_sectionAccount => 'アカウント';

  @override
  String get profile_sectionAdmin => '管理者';

  @override
  String get profile_sectionOther => 'その他';

  @override
  String get profile_sectionSupport => 'サポート';

  @override
  String get profile_snackLoggedOut => 'ログアウトしました（ゲストに戻りました）';

  @override
  String get profile_stripeAccount => 'Stripe口座設定';

  @override
  String get profile_stripeAccountSubtitle => '報酬の受取口座を設定';

  @override
  String get profile_yourProfile => 'あなたのプロフィール';

  @override
  String get projectName => '案件名';

  @override
  String get qrCheckIn => 'QR出勤';

  @override
  String get qrCheckin_clockIn => '退勤';

  @override
  String get qrCheckin_clockOut => '退勤';

  @override
  String get qrCheckin_error => 'エラー';

  @override
  String qrCheckin_errorOccurred(String error) {
    return 'エラーが発生しました: $error';
  }

  @override
  String qrCheckin_gpsVerification(String action) {
    return 'GPS検証: 現場から100m以内で$actionできます';
  }

  @override
  String get qrCheckin_scanAdminQr => '管理者のQRコードをスキャンしてください';

  @override
  String qrCheckin_title(String action) {
    return 'QRスキャン（$action）';
  }

  @override
  String get qualificationAdd_categoryLabel => 'カテゴリ *';

  @override
  String get qualificationAdd_expiryDate => '有効期限';

  @override
  String get qualificationAdd_nameHint => '資格名 *';

  @override
  String get qualificationAdd_nameLabel => '資格名 *';

  @override
  String get qualificationAdd_nameRequired => '資格名を入力してください';

  @override
  String get qualificationAdd_noExpiry => '有効期限';

  @override
  String get qualificationAdd_register => '資格を登録しました（審査待ち）';

  @override
  String qualificationAdd_registerFailed(String error) {
    return '登録に失敗: $error';
  }

  @override
  String get qualificationAdd_registered => '資格を登録しました（審査待ち）';

  @override
  String get qualificationAdd_title => '資格を追加';

  @override
  String get qualifications => '資格';

  @override
  String get qualifications_addHint => '登録された資格はありません';

  @override
  String get qualifications_approved => '承認済み';

  @override
  String get qualifications_empty => '登録された資格はありません';

  @override
  String qualifications_error(String error) {
    return 'エラー: $error';
  }

  @override
  String get qualifications_expired => '（期限切れ）';

  @override
  String qualifications_expiryDate(String date, String status) {
    return '有効期限: $date$status';
  }

  @override
  String get qualifications_loginRequired => 'ログインが必要です';

  @override
  String get qualifications_pending => '承認済み';

  @override
  String get qualifications_rejected => '審査中';

  @override
  String get qualifications_title => '資格管理';

  @override
  String get ratingDialog_average => '不満';

  @override
  String get ratingDialog_commentHint => 'コメント（任意）';

  @override
  String get ratingDialog_dissatisfied => '不満';

  @override
  String get ratingDialog_excellent => 'コメント（任意）';

  @override
  String get ratingDialog_good => 'コメント（任意）';

  @override
  String get ratingDialog_later => '後で';

  @override
  String get ratingDialog_selectStars => '星を選択してください';

  @override
  String get ratingDialog_somewhatDissatisfied => '不満';

  @override
  String get ratingDialog_submit => '評価を送信しました';

  @override
  String ratingDialog_submitFailed(String error) {
    return '送信に失敗しました: $error';
  }

  @override
  String get ratingDialog_submitSuccess => '評価を送信しました';

  @override
  String get ratingDialog_title => 'お仕事の評価';

  @override
  String get ratingLabel => '評価';

  @override
  String ratingStars_count(String count) {
    return '($count件)';
  }

  @override
  String get ratingStars_noRating => '評価なし';

  @override
  String get receiveNotifications => 'お知らせ通知を受け取る';

  @override
  String get referral_applyButton => '適用する';

  @override
  String get referral_codeApplied => '紹介コードを適用しました';

  @override
  String get referral_codeCopied => 'コードをコピーしました';

  @override
  String get referral_codeHint => '例: ABC123';

  @override
  String get referral_copy => 'コピー';

  @override
  String get referral_enterCode => '紹介コードを入力';

  @override
  String get referral_enterCodeDescription => '紹介コードを入力';

  @override
  String get referral_inviteDescription => '友達を招待して特典を受け取ろう';

  @override
  String get referral_loginRequired => 'ログインが必要です';

  @override
  String get referral_share => 'シェア';

  @override
  String get referral_stats => '紹介実績';

  @override
  String referral_statsCount(String count) {
    return '$count 人';
  }

  @override
  String get referral_title => '友達を招待';

  @override
  String get referral_yourCode => 'あなたの紹介コード';

  @override
  String get refreshing => '更新中...';

  @override
  String get register => '新規登録';

  @override
  String get registerSuccess => 'アカウントを作成しました';

  @override
  String get registrationPrompt_defaultFeature => 'この機能';

  @override
  String get registrationPrompt_description =>
      'LINEまたはメールアドレスで登録して、\\nすべての機能をご利用ください。';

  @override
  String get registrationPrompt_emailLogin => 'メールアドレスで登録';

  @override
  String registrationPrompt_error(String error) {
    return 'エラーが発生しました: $error';
  }

  @override
  String get registrationPrompt_later => '後で';

  @override
  String get registrationPrompt_lineLogin => 'LINEで登録';

  @override
  String get registrationPrompt_lineRedirect => 'LINEログインページへ移動します';

  @override
  String registrationPrompt_title(String feature) {
    return '$featureには登録が必要です';
  }

  @override
  String get required => '必須';

  @override
  String get retry => '再試行';

  @override
  String get router_goHome => 'ホームに戻る';

  @override
  String router_pageDoesNotExist(String uri) {
    return '$uri は存在しません';
  }

  @override
  String get router_pageNotFound => 'ページが見つかりません';

  @override
  String get router_statementsTitle => '明細一覧';

  @override
  String get router_workTimelineTitle => '工程タイムライン';

  @override
  String get salesTitle => '売上';

  @override
  String get sales_checkSales => '売上確認';

  @override
  String get sales_constructionCompleted => '施工完了';

  @override
  String sales_dataCount(String count) {
    return 'データ件数: $count件';
  }

  @override
  String get sales_earningsNote => '※ 管理者が報酬を確定すると収入に反映されます';

  @override
  String get sales_incomeAndStatements => '収入・明細';

  @override
  String get sales_incomeNote => '※ 確定済みの報酬のみ表示';

  @override
  String sales_monthLabel(String month) {
    return '$month月';
  }

  @override
  String sales_monthStatement(String month) {
    return '$month月 明細';
  }

  @override
  String get sales_monthlyTrend => '月別推移';

  @override
  String sales_nextPaymentDate(String month) {
    return '次回支払日: $month月10日';
  }

  @override
  String get sales_noPaymentData => '支払いデータがありません';

  @override
  String get sales_noStatements => '明細がありません';

  @override
  String get sales_noStatementsDescription => '月次明細が生成されるとここに表示されます。';

  @override
  String get sales_paid => '支払済';

  @override
  String get sales_paymentHistory => '支払い履歴';

  @override
  String get sales_paymentManagement => '支払い管理';

  @override
  String get sales_registerPayment => '報酬を登録';

  @override
  String get sales_registerToStart => '登録して始める';

  @override
  String get sales_registrationDescription => '売上情報を確認するには会員登録が必要です。';

  @override
  String get sales_registrationRequired => '会員登録が必要です';

  @override
  String get sales_resetToThisMonth => '今月に戻す';

  @override
  String get sales_salesTitle => '売上';

  @override
  String get sales_selectedMonthIncome => '選択月の収入';

  @override
  String get sales_statusDraft => '集計中';

  @override
  String get sales_statusPaid => '支払済み';

  @override
  String get sales_tabIncome => '収入';

  @override
  String get sales_tabStatements => '明細';

  @override
  String get sales_thisMonthIncome => '今月の収入';

  @override
  String get sales_total => '合計';

  @override
  String get sales_totalIncome => '累計収入';

  @override
  String get sales_unconfirmedEarnings => '未確定の報酬';

  @override
  String get sales_unpaid => '未払い';

  @override
  String get save => '保存';

  @override
  String get scanQrCode => 'QRコードをスキャン';

  @override
  String get search => '検索';

  @override
  String get searchJobs => '仕事を検索';

  @override
  String get send => '送信';

  @override
  String get sendMessage => 'メッセージを送信';

  @override
  String get sendResetLink => 'リセットリンクを送信';

  @override
  String get shareJob => '案件をシェア';

  @override
  String get shiftQr => 'シフトQR';

  @override
  String shiftQr_generateFailed(String error) {
    return '生成に失敗: $error';
  }

  @override
  String get shiftQr_generateNew => '生成中...';

  @override
  String get shiftQr_generated => 'QRコードを生成しました';

  @override
  String get shiftQr_generating => '生成中...';

  @override
  String get shiftQr_noQrCodes => 'QRコードはまだ生成されていません';

  @override
  String get shiftQr_scanInstruction => '職人にこのQRコードをスキャンしてもらってください';

  @override
  String get shiftQr_title => 'QR出退勤管理';

  @override
  String get showPassword => 'パスワードを表示';

  @override
  String get signInWithApple => 'Appleでサインイン';

  @override
  String get signInWithEmail => 'メールアドレスでログイン';

  @override
  String get signInWithLine => 'LINEでログイン';

  @override
  String get skip => 'スキップ';

  @override
  String get sortByNewest => '新着順';

  @override
  String get sortByPriceHigh => '報酬が高い順';

  @override
  String get startAsGuest => 'ゲストとして始める';

  @override
  String get startOnboarding => '口座設定を開始';

  @override
  String get statementDetail_applyButton => 'キャンセル';

  @override
  String statementDetail_completedDate(String date) {
    return '完了日: $date';
  }

  @override
  String get statementDetail_earlyPaymentButton => '即金申請（手数料10%）';

  @override
  String statementDetail_earlyPaymentConfirm(
    String totalAmount,
    String fee,
    String payout,
  ) {
    return '即金申請しますか？手数料10%が差し引かれます。（金額: ¥$totalAmount、手数料: ¥$fee、支払額: ¥$payout）';
  }

  @override
  String get statementDetail_earlyPaymentError => '即金申請を送信しました';

  @override
  String get statementDetail_earlyPaymentPending => '即金申請済み（審査中）';

  @override
  String get statementDetail_earlyPaymentSuccess => '即金申請を送信しました';

  @override
  String get statementDetail_earlyPaymentTitle => '即金申請';

  @override
  String statementDetail_error(String error) {
    return 'エラー: $error';
  }

  @override
  String get statementDetail_jobDetails => '案件明細';

  @override
  String statementDetail_monthLabel(String month) {
    return '$month月';
  }

  @override
  String get statementDetail_title => '明細詳細';

  @override
  String get statusApplied => '応募中';

  @override
  String get statusAssigned => '確定';

  @override
  String get statusBadge_applied => '応募中';

  @override
  String get statusBadge_assigned => '着工前';

  @override
  String get statusBadge_completed => '施工完了';

  @override
  String get statusBadge_done => '完了';

  @override
  String get statusBadge_fixing => '是正中';

  @override
  String get statusBadge_inProgress => '着工中';

  @override
  String get statusBadge_inspection => '検収中';

  @override
  String get statusCancelled => 'キャンセル';

  @override
  String get statusCompleted => '完了';

  @override
  String get statusPending => '審査中';

  @override
  String get statusRejected => '不採用';

  @override
  String get stripeOnboarding => '口座設定';

  @override
  String get stripeOnboardingDescription => '報酬を受け取るために口座情報を設定してください';

  @override
  String get stripeOnboarding_initFailed => 'URLの取得に失敗しました';

  @override
  String get stripeOnboarding_retry => 'リトライ';

  @override
  String get stripeOnboarding_title => 'Stripe口座設定';

  @override
  String get stripeOnboarding_urlFetchFailed => 'URLの取得に失敗しました';

  @override
  String get tabSelected => '選択中';

  @override
  String get termsOfService => '利用規約';

  @override
  String get timeline_empty => 'タイムラインはまだありません';

  @override
  String timeline_error(String error) {
    return 'エラー: $error';
  }

  @override
  String get today => '今日';

  @override
  String get tooManyRequests => 'リクエストが多すぎます。しばらくしてからお試しください';

  @override
  String get totalEarnings => '合計報酬';

  @override
  String get typeMessage => 'メッセージを入力';

  @override
  String unreadCount(String count) {
    return '未読$count件';
  }

  @override
  String get update => '更新';

  @override
  String get userDisabled => 'このアカウントは無効化されています';

  @override
  String get userNotFound => 'アカウントが見つかりません';

  @override
  String get weakPassword => 'パスワードが弱すぎます。6文字以上で設定してください';

  @override
  String get workDetail => '仕事詳細';

  @override
  String get workDetail_chat => 'チャット';

  @override
  String get workDetail_checkedIn => '出勤中';

  @override
  String get workDetail_checkedOut => '退勤済み';

  @override
  String get workDetail_completeButton => '完了報告';

  @override
  String get workDetail_jobName => '案件名';

  @override
  String get workDetail_jobNotFound => '案件が見つかりません';

  @override
  String get workDetail_location => '場所';

  @override
  String get workDetail_loginRequired => 'ログインが必要です';

  @override
  String get workDetail_noJobIdWarning => '※ jobIdが未設定のため、元の案件情報を表示できません。';

  @override
  String get workDetail_noPermission => 'この案件の閲覧権限がありません';

  @override
  String get workDetail_notCheckedIn => '未出勤';

  @override
  String get workDetail_payment => '報酬';

  @override
  String get workDetail_paymentUnconfirmed => '未確定';

  @override
  String get workDetail_qrAttendance => 'QR勤怠';

  @override
  String get workDetail_qrClockIn => 'QR出勤';

  @override
  String get workDetail_qrClockOut => 'QR退勤';

  @override
  String get workDetail_rateButton => '評価する';

  @override
  String get workDetail_rated => '評価済み';

  @override
  String get workDetail_reinspect => '再検査';

  @override
  String get workDetail_reportRequired => '完了するには日報を1件以上提出してください';

  @override
  String get workDetail_schedule => '日程';

  @override
  String get workDetail_snackCompleteError => '完了処理に失敗しました';

  @override
  String get workDetail_snackCompleted => '施工完了しました';

  @override
  String get workDetail_snackStartError => '着工処理に失敗しました';

  @override
  String get workDetail_snackStarted => '着工しました';

  @override
  String get workDetail_startButton => '着工';

  @override
  String get workDetail_startInspection => '検収';

  @override
  String workDetail_statusCompleted(String title) {
    return '$titleが「施工完了」になりました';
  }

  @override
  String workDetail_statusInProgress(String title) {
    return '$titleが「着工中」になりました';
  }

  @override
  String get workDetail_statusUpdate => 'ステータス更新';

  @override
  String get workDetail_tabDailyReport => '日報';

  @override
  String get workDetail_tabDocuments => '資料';

  @override
  String get workDetail_tabOverview => '概要';

  @override
  String get workDetail_tabPhotos => '写真';

  @override
  String get workDetail_timeline => 'タイムライン';

  @override
  String get workDocs_add => '追加';

  @override
  String workDocs_noDocuments(String folder) {
    return '「$folder」の資料はまだありません';
  }

  @override
  String get workDocs_title => '資料管理';

  @override
  String workDocs_uploadFailed(String error) {
    return 'アップロードに失敗しました: $error';
  }

  @override
  String workDocs_uploadSuccess(String folder) {
    return '$folderにアップロードしました';
  }

  @override
  String get workPhotos_add => '追加';

  @override
  String get workPhotos_cancel => 'キャンセル';

  @override
  String get workPhotos_delete => '削除';

  @override
  String get workPhotos_deleteConfirm => 'この写真を削除しますか？';

  @override
  String get workPhotos_deleteSuccess => '写真を削除しました';

  @override
  String get workPhotos_deleteTitle => '写真を削除';

  @override
  String get workPhotos_noPhotos => '写真はまだありません';

  @override
  String get workPhotos_title => '現場写真';

  @override
  String workPhotos_uploadFailed(String error) {
    return 'アップロードに失敗しました: $error';
  }

  @override
  String get workPhotos_uploadHint => '「追加」ボタンから写真をアップロード';

  @override
  String workPhotos_uploadSuccess(String count) {
    return '$count枚の写真をアップロードしました';
  }

  @override
  String get workReportCreate_contentHint => '作業内容 *';

  @override
  String get workReportCreate_contentLabel => '作業内容 *';

  @override
  String get workReportCreate_contentRequired => '作業内容 *';

  @override
  String get workReportCreate_date => '日付';

  @override
  String get workReportCreate_hoursLabel => '作業時間（時間）';

  @override
  String get workReportCreate_hoursSuffix => '作業時間（時間）';

  @override
  String get workReportCreate_hoursValidation => '時間';

  @override
  String workReportCreate_logSubmitted(String title) {
    return '日報: $title 提出';
  }

  @override
  String get workReportCreate_notesHint => '備考';

  @override
  String get workReportCreate_notesLabel => '備考';

  @override
  String workReportCreate_saveFailed(String error) {
    return '保存に失敗: $error';
  }

  @override
  String get workReportCreate_submit => '日報を提出しました';

  @override
  String get workReportCreate_submitted => '日報を提出しました';

  @override
  String get workReportCreate_title => '日報作成';

  @override
  String get workReports_addHint => '日報はまだありません';

  @override
  String get workReports_empty => '日報はまだありません';

  @override
  String workReports_error(String error) {
    return 'エラー: $error';
  }

  @override
  String get workStatus => '勤務状況';

  @override
  String get workTitle => 'はたらく';

  @override
  String get work_chatTooltip => 'チャット';

  @override
  String get work_emptyApplications => '応募した案件はありません';

  @override
  String get work_emptyAssigned => 'アサイン済みの案件はありません';

  @override
  String get work_emptyCompleted => '施工完了の案件はありません';

  @override
  String get work_emptyDefault => '該当する案件はありません';

  @override
  String get work_emptyDone => '完了した案件はありません';

  @override
  String get work_emptyFixing => '是正中の案件はありません';

  @override
  String get work_emptyInProgress => '作業中の案件はありません';

  @override
  String get work_emptyInspection => '検収中の案件はありません';

  @override
  String get work_featureName => '仕事管理';

  @override
  String get work_groupApplied => '応募中';

  @override
  String get work_groupApproved => '承認済み・作業中';

  @override
  String get work_groupCompleted => '完了・検収';

  @override
  String get work_noJobs => '該当なし';

  @override
  String get work_registrationRequiredDescription =>
      '会員登録をして、お仕事の応募・管理機能をご利用ください。';

  @override
  String get work_registrationRequiredTitle => '仕事管理を利用するには会員登録が必要です';

  @override
  String get work_tabApplications => '応募一覧';

  @override
  String get work_tabAssigned => 'アサイン済み';

  @override
  String get work_tabCompleted => '施工完了';

  @override
  String get work_tabDone => '完了';

  @override
  String get work_tabFixing => '是正中';

  @override
  String get work_tabInProgress => '作業中';

  @override
  String get work_tabInspection => '検収中';

  @override
  String get workerLabel => 'ワーカー';

  @override
  String get wrongPassword => 'パスワードが正しくありません';

  @override
  String get yen => '円';

  @override
  String get yesterday => '昨日';

  @override
  String jobList_monthNumLabel(String month) {
    return '$month月';
  }

  @override
  String jobList_resultCount(String count) {
    return '$count件';
  }

  @override
  String get messages_filterAll => 'すべて';

  @override
  String get messages_filterUnread => '未読';

  @override
  String get messages_noUnread => '未読メッセージはありません';

  @override
  String get profile_totalJobs => '完了案件';

  @override
  String get profile_rating => '評価';

  @override
  String get profile_qualityScore => 'スコア';

  @override
  String get profile_logout => 'ログアウト';

  @override
  String home_unreadMessages(String count) {
    return '未読メッセージ$count件';
  }

  @override
  String work_unreadChat(String count) {
    return '未読$count件';
  }

  @override
  String get post_sectionImages => '画像';

  @override
  String get post_sectionImagesSubtitle => '案件の写真を追加（最大5枚）';

  @override
  String post_addImages(String current, String max) {
    return '画像を追加（$current/$max）';
  }

  @override
  String get adminApproval_noName => '名前未設定';

  @override
  String get adminApproval_approve => '承認';

  @override
  String get adminApproval_reject => '却下';

  @override
  String get adminApproval_rejectReasonTitle => '却下理由';

  @override
  String get adminApproval_rejectReasonHint => '却下理由を入力してください';

  @override
  String get adminApproval_rejectButton => '却下する';

  @override
  String get adminKpi_noData => 'データなし';

  @override
  String get adminNav_jobs => '案件';

  @override
  String get adminNav_approvals => '承認';

  @override
  String get adminNav_workers => 'ワーカー';

  @override
  String get adminNav_settings => '設定';

  @override
  String get adminNav_jobManagement => '案件管理';

  @override
  String get adminNav_applicants => '応募者管理';

  @override
  String get adminApproval_qualifications => '資格';

  @override
  String get adminApproval_earlyPayments => '即金';

  @override
  String get adminApproval_verification => '本人確認';

  @override
  String get adminApproval_emptyTitle => '未処理の承認はありません';

  @override
  String get adminApproval_emptyDescription => 'すべての承認が処理されました';

  @override
  String get adminApproval_pendingReview => '審査待ち';

  @override
  String get adminKpi_dailyTrend => '応募トレンド（直近7日）';

  @override
  String get adminKpi_monthlyKpi => '月次KPI';

  @override
  String get adminKpi_mau => 'MAU';

  @override
  String get adminKpi_monthlyEarnings => '月間売上';

  @override
  String get adminKpi_jobFillRate => '充足率';

  @override
  String get adminWorkers_activeList => '稼働一覧';

  @override
  String get adminWorkers_reports => '日報';

  @override
  String get adminWorkers_inspections => '検査';

  @override
  String get adminWorkers_searchHint => 'ワーカー名で検索';

  @override
  String get adminWorkers_emptyTitle => '稼働中のワーカーはいません';

  @override
  String get adminWorkers_emptyDescription => '現在稼働中のワーカーはいません';

  @override
  String adminWorkers_inProgressCount(String count) {
    return '稼働中 $count人';
  }

  @override
  String adminWorkers_assignedCount(String count) {
    return '割当済 $count人';
  }

  @override
  String get adminWorkers_jobUnit => '件';

  @override
  String get adminWorkReports_emptyTitle => '日報はまだありません';

  @override
  String get adminWorkReports_emptyDescription => 'ワーカーが日報を提出するとここに表示されます';

  @override
  String adminWorkReports_hours(String hours) {
    return '$hours時間';
  }

  @override
  String get adminInspections_filterAll => 'すべて';

  @override
  String get adminInspections_filterPassed => '合格';

  @override
  String get adminInspections_filterFailed => '不合格';

  @override
  String get adminInspections_filterPartial => '一部不合格';

  @override
  String get adminInspections_emptyTitle => '検査記録はありません';

  @override
  String get adminInspections_emptyDescription => '検査が実施されるとここに表示されます';

  @override
  String get adminInspections_passed => '合格';

  @override
  String get adminInspections_failed => '不合格';

  @override
  String get adminInspections_partial => '一部不合格';

  @override
  String adminInspections_checkSummary(String total, String passed) {
    return '$total項目中$passed件合格';
  }

  @override
  String get adminSettings_admin => '管理者';

  @override
  String get adminSettings_notifications => '通知設定';

  @override
  String get adminSettings_appVersion => 'アプリバージョン';

  @override
  String get adminSettings_legal => '法的情報';

  @override
  String get adminSettings_logout => 'ログアウト';

  @override
  String get adminSettings_logoutTitle => 'ログアウト';

  @override
  String get adminSettings_logoutConfirm => 'ログアウトしますか？';

  @override
  String get adminDashboard_workReports => '日報管理';

  @override
  String adminApplicants_qualCount(String count) {
    return '資格$count';
  }

  @override
  String adminApplicants_completedCount(String count) {
    return '完了$count';
  }

  @override
  String get adminApplicants_openChat => 'チャットを開く';

  @override
  String get adminSettings_accountSettings => 'アカウント設定';

  @override
  String get adminSettings_language => '言語';

  @override
  String get adminSettings_dataExport => 'データエクスポート';

  @override
  String get adminWorker_statistics => '統計';

  @override
  String get adminWorker_statCompleted => '完了数';

  @override
  String get adminWorker_statTotalEarnings => '総報酬';

  @override
  String get adminWorker_statCompletionRate => '完了率';

  @override
  String get adminWorker_memoTitle => '管理者メモ';

  @override
  String get adminWorker_memoHint => 'このワーカーに関するメモを入力…';

  @override
  String get adminWorker_memoSave => 'メモを保存';

  @override
  String get adminWorker_memoSaved => 'メモを保存しました';

  @override
  String get adminWorker_memoSaveFailed => 'メモの保存に失敗しました';

  @override
  String get adminWorker_openChat => 'チャットを開く';

  @override
  String get adminWorker_noChatAvailable => 'チャット可能な応募がありません';

  @override
  String get adminWorker_ekycApproved => '本人確認済';

  @override
  String get adminWorker_ekycPending => '確認中';

  @override
  String get adminWorker_ekycRejected => '確認否認';

  @override
  String get post_saveDraft => '下書き';

  @override
  String get post_draftSaved => '下書きを保存しました';

  @override
  String get post_draftSaveFailed => '下書きの保存に失敗しました';

  @override
  String get post_draftNeedTitle => 'タイトルを入力してください';

  @override
  String get adminWorkReports_filterAll => 'すべて';

  @override
  String get adminWorkReports_filterPending => '未レビュー';

  @override
  String get adminWorkReports_filterReviewed => 'レビュー済';

  @override
  String get adminWorkReports_reviewPending => '未レビュー';

  @override
  String get adminWorkReports_reviewed => 'レビュー済';

  @override
  String get adminWorkReports_addFeedback => 'コメント追加';

  @override
  String get adminWorkReports_markReviewed => '確認済みにする';

  @override
  String get adminWorkReports_feedbackTitle => '日報フィードバック';

  @override
  String get adminWorkReports_feedbackHint => 'コメントを入力…';

  @override
  String get adminWorkReports_feedbackSubmit => '送信';

  @override
  String get adminWorkReports_feedbackCancel => 'キャンセル';

  @override
  String get adminWorkReports_feedbackSent => 'フィードバックを送信しました';

  @override
  String get adminWorkReports_feedbackFailed => 'フィードバックの送信に失敗しました';

  @override
  String get adminWorkReports_markedReviewed => 'レビュー済みにしました';

  @override
  String get adminWorkReports_markFailed => 'レビュー更新に失敗しました';

  @override
  String get inspection_customItems => 'カスタム検査項目';

  @override
  String get inspection_customItemsHint => '項目名を入力';

  @override
  String get inspection_addItem => '項目を追加';

  @override
  String get inspection_removeItem => '項目を削除';

  @override
  String get inspection_defaultItems => 'デフォルト項目を使用';

  @override
  String get inspection_customItemsHelp => '案件ごとにカスタム検査項目を設定できます';

  @override
  String get inspection_itemPhotoAttach => '写真を添付';

  @override
  String inspection_itemPhotoCount(String count) {
    return '$count枚';
  }

  @override
  String get adminDrafts_title => '下書き一覧';

  @override
  String get adminDrafts_empty => '下書きはありません';

  @override
  String get adminDrafts_publish => '公開する';

  @override
  String get adminDrafts_delete => '削除する';

  @override
  String get adminDrafts_deleteConfirm => 'この下書きを削除しますか？';

  @override
  String get adminDrafts_published => '案件を公開しました';

  @override
  String get adminDrafts_publishFailed => '公開に失敗しました';

  @override
  String get adminDrafts_deleted => '下書きを削除しました';

  @override
  String get adminDrafts_deleteFailed => '削除に失敗しました';

  @override
  String get adminKpi_avgJobPrice => '平均案件単価';

  @override
  String get adminKpi_workerAnalysis => 'ワーカー分析';

  @override
  String get adminKpi_activeWorkerRate => 'アクティブ率';

  @override
  String get adminKpi_repeatWorkerRate => 'リピート率';

  @override
  String get adminKpi_regionDistribution => '地域分布';

  @override
  String get notifications_filterAll => 'すべて';

  @override
  String get notifications_filterApplications => '応募';

  @override
  String get notifications_filterReports => '日報';

  @override
  String get notifications_filterInspections => '検査';
}
