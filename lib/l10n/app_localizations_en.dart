// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get accountSettings_cancel => 'Cancel';

  @override
  String get accountSettings_changePasswordButton => 'Change password';

  @override
  String get accountSettings_changePasswordLabel => 'Change password';

  @override
  String get accountSettings_confirm => 'Confirm';

  @override
  String get accountSettings_currentPasswordHint => 'Current password';

  @override
  String get accountSettings_delete => 'Delete';

  @override
  String get accountSettings_deleteAccount => 'Delete account';

  @override
  String get accountSettings_deleteConfirmMessage =>
      'Deleting your account will permanently erase all your data.\n\n- Profile information\n- Application history\n- Chat history\n- Favorites\n- Notifications\n\nThis action cannot be undone. Are you sure you want to delete?';

  @override
  String get accountSettings_displayNameLabel => 'Display name';

  @override
  String get accountSettings_downloadData => 'Download data';

  @override
  String get accountSettings_emailLabel => 'Email';

  @override
  String get accountSettings_languageLabel => 'Language settings';

  @override
  String get accountSettings_loginRequired => 'Login required';

  @override
  String get accountSettings_nameHint => 'Enter your name';

  @override
  String get accountSettings_newPasswordHint => 'New password (6+ characters)';

  @override
  String get accountSettings_notSet => 'Not set';

  @override
  String get accountSettings_notificationSettings => 'Notification settings';

  @override
  String get accountSettings_receiveNotifications => 'Receive notifications';

  @override
  String get accountSettings_snackDataCopied => 'Data copied to clipboard';

  @override
  String accountSettings_snackDeleteFailed(String error) {
    return 'Failed to delete account: $error';
  }

  @override
  String accountSettings_snackDeleteFailedGeneric(String error) {
    return 'Failed to delete account: $error';
  }

  @override
  String get accountSettings_snackEnterBothPasswords =>
      'Please enter both current and new passwords';

  @override
  String accountSettings_snackError(String error) {
    return 'Error: $error';
  }

  @override
  String accountSettings_snackExportFailed(String error) {
    return 'Failed to export data: $error';
  }

  @override
  String get accountSettings_snackNameUpdated => 'Display name updated';

  @override
  String accountSettings_snackPasswordChangeFailed(String error) {
    return 'Failed to change password: $error';
  }

  @override
  String get accountSettings_snackPasswordChanged => 'Password changed';

  @override
  String get accountSettings_snackPasswordMinLength =>
      'Password must be at least 6 characters';

  @override
  String accountSettings_snackUpdateFailed(String error) {
    return 'Failed to update: $error';
  }

  @override
  String get accountSettings_snackWrongPassword =>
      'Current password is incorrect';

  @override
  String get accountSettings_title => 'Account Settings';

  @override
  String get address => 'Address';

  @override
  String get adminApplicants_bulkApproveButton => 'Bulk approve';

  @override
  String adminApplicants_bulkApproveConfirm(String count) {
    return 'Assign all $count pending applications?';
  }

  @override
  String adminApplicants_bulkApproveCount(String count) {
    return 'Bulk approve ($count)';
  }

  @override
  String adminApplicants_bulkApproveFailed(String error) {
    return 'Bulk approval failed: $error';
  }

  @override
  String get adminApplicants_bulkApproveTitle => 'Bulk Approve';

  @override
  String adminApplicants_bulkApproved(String count) {
    return '$count applications approved';
  }

  @override
  String get adminApplicants_changeButton => 'Change';

  @override
  String adminApplicants_changeFailed(String error) {
    return 'Failed to change status: $error';
  }

  @override
  String adminApplicants_changeStatusConfirm(
    String jobTitle,
    String statusLabel,
  ) {
    return 'Change the status of \"$jobTitle\" to \"$statusLabel\"?';
  }

  @override
  String get adminApplicants_changeStatusTitle => 'Change Status';

  @override
  String get adminApplicants_filterAll => 'All';

  @override
  String get adminApplicants_filterApplied => 'Applied';

  @override
  String get adminApplicants_filterAssigned => 'Assigned';

  @override
  String get adminApplicants_filterDone => 'Done';

  @override
  String get adminApplicants_filterInProgress => 'In Progress';

  @override
  String adminApplicants_noApplicantsForStatus(String statusLabel) {
    return 'No applicants with status \"$statusLabel\"';
  }

  @override
  String get adminApplicants_noApplicantsYet => 'No applicants yet';

  @override
  String adminApplicants_qualityScore(String score) {
    return 'Quality: $score';
  }

  @override
  String get adminApplicants_searchHint => 'Search by name...';

  @override
  String get adminApplicants_startWork => 'Start work';

  @override
  String adminApplicants_statusChanged(String jobTitle, String statusLabel) {
    return '\"$jobTitle\" changed to \"$statusLabel\"';
  }

  @override
  String adminApplicants_statusUpdateNotifBody(
    String jobTitle,
    String statusLabel,
  ) {
    return 'The status of \"$jobTitle\" has been changed to \"$statusLabel\"';
  }

  @override
  String get adminApplicants_statusUpdateNotifTitle => 'Status updated';

  @override
  String get adminApplicants_workCompleted => 'Work completed';

  @override
  String get adminApplications => 'Application Management';

  @override
  String get adminBadge => 'Admin';

  @override
  String get adminDashboard_activeJobs => 'Active jobs';

  @override
  String adminDashboard_alertCount(String label, String count) {
    return '$label $count';
  }

  @override
  String get adminDashboard_applicationCount => 'Applications';

  @override
  String get adminDashboard_checkSales => 'Check earnings';

  @override
  String get adminDashboard_earlyPaymentApproval => 'Early payment approval';

  @override
  String get adminDashboard_identityVerification => 'Identity verification';

  @override
  String get adminDashboard_noApplications => 'No applications yet';

  @override
  String get adminDashboard_noJobTitle => 'No job title';

  @override
  String get adminDashboard_pendingAlerts => 'Pending alerts';

  @override
  String get adminDashboard_pendingApplications => 'Pending applications';

  @override
  String get adminDashboard_pendingApproval => 'Pending approval';

  @override
  String get adminDashboard_pendingEarlyPayments => 'Pending early payments';

  @override
  String get adminDashboard_pendingQualifications => 'Pending qualifications';

  @override
  String get adminDashboard_pendingVerifications => 'Pending verifications';

  @override
  String get adminDashboard_postJob => 'Post a job';

  @override
  String get adminDashboard_qualificationApproval => 'Qualification approval';

  @override
  String get adminDashboard_quickActions => 'Quick actions';

  @override
  String get adminDashboard_recentApplications => 'Recent applications';

  @override
  String get adminDashboard_registeredUsers => 'Registered users';

  @override
  String get adminDashboard_title => 'Admin Dashboard';

  @override
  String get adminEarlyPayments_approveLabel => 'Approve';

  @override
  String get adminEarlyPayments_cancel => 'Cancel';

  @override
  String get adminEarlyPayments_emptyDescription =>
      'When workers submit early payment requests, they will appear here.';

  @override
  String get adminEarlyPayments_emptyTitle =>
      'No pending early payment requests';

  @override
  String get adminEarlyPayments_fee => 'Fee (10%)';

  @override
  String adminEarlyPayments_loadError(String error) {
    return 'Load error: $error';
  }

  @override
  String get adminEarlyPayments_loading => 'Loading...';

  @override
  String get adminEarlyPayments_nameNotSet => 'Name not set';

  @override
  String get adminEarlyPayments_notifyApprovedBody =>
      'Your early payment request has been approved. Funds will be transferred soon.';

  @override
  String get adminEarlyPayments_notifyApprovedTitle => 'Early payment approved';

  @override
  String adminEarlyPayments_notifyRejectedBody(String reason) {
    return 'Early payment request was rejected. Reason: $reason';
  }

  @override
  String get adminEarlyPayments_notifyRejectedTitle => 'Early payment rejected';

  @override
  String get adminEarlyPayments_payoutAmount => 'Payout amount';

  @override
  String get adminEarlyPayments_rejectButton => 'Reject';

  @override
  String get adminEarlyPayments_rejectLabel => 'Reject';

  @override
  String get adminEarlyPayments_rejectReasonHint =>
      'Enter the reason for rejection';

  @override
  String get adminEarlyPayments_rejectReasonRequired =>
      'Please enter a reason for rejection';

  @override
  String get adminEarlyPayments_rejectReasonTitle => 'Rejection reason';

  @override
  String adminEarlyPayments_requestDate(String date) {
    return 'Request date: $date';
  }

  @override
  String get adminEarlyPayments_requestedAmount => 'Requested amount';

  @override
  String get adminEarlyPayments_snackApproveFailed => 'Failed to approve';

  @override
  String get adminEarlyPayments_snackApproved => 'Early payment approved';

  @override
  String get adminEarlyPayments_snackRejectFailed => 'Failed to reject';

  @override
  String get adminEarlyPayments_snackRejected => 'Early payment rejected';

  @override
  String get adminEarlyPayments_statusRequested => 'Requested';

  @override
  String get adminEarlyPayments_targetMonth => 'Target month';

  @override
  String get adminEarlyPayments_title => 'Early Payment Requests';

  @override
  String adminEarlyPayments_yenFormat(String amount) {
    return '¥$amount';
  }

  @override
  String get adminHome => 'Admin Dashboard';

  @override
  String get adminHome_admin => 'Admin';

  @override
  String get adminHome_applicants => 'Applicants';

  @override
  String get adminHome_dashboard => 'Dashboard';

  @override
  String get adminHome_jobManagement => 'Job Management';

  @override
  String get adminHome_notifications => 'Notifications';

  @override
  String get adminHome_salesManagement => 'Sales Management';

  @override
  String get adminHome_settings => 'Settings';

  @override
  String get adminIdentityVerification_approveButton => 'Approve';

  @override
  String get adminIdentityVerification_approveConfirm =>
      'Approve this identity verification?';

  @override
  String adminIdentityVerification_approveFailed(String error) {
    return 'Approval failed: $error';
  }

  @override
  String get adminIdentityVerification_approveTitle => 'Confirm Approval';

  @override
  String get adminIdentityVerification_approved => 'Approved';

  @override
  String get adminIdentityVerification_enterRejectReason =>
      'Please enter a reason for rejection';

  @override
  String get adminIdentityVerification_idDocumentPhoto => 'ID Document';

  @override
  String get adminIdentityVerification_noPendingRequests =>
      'No pending verification requests';

  @override
  String get adminIdentityVerification_rejectButton => 'Reject';

  @override
  String adminIdentityVerification_rejectFailed(String error) {
    return 'Rejection failed: $error';
  }

  @override
  String get adminIdentityVerification_rejectReasonHint =>
      'e.g. Photo is unclear';

  @override
  String get adminIdentityVerification_rejectTitle => 'Confirm Rejection';

  @override
  String get adminIdentityVerification_rejected => 'Rejected';

  @override
  String get adminIdentityVerification_selfiePhoto => 'Selfie';

  @override
  String get adminIdentityVerification_title =>
      'Identity Verification Management';

  @override
  String get adminJobManagement => 'Job Management';

  @override
  String adminJobManagement_applicantCount(String count) {
    return '$count applications';
  }

  @override
  String get adminJobManagement_checkNetwork =>
      'Please check your network connection';

  @override
  String get adminJobManagement_dateTbd => 'Date TBD';

  @override
  String get adminJobManagement_filterActive => 'Active';

  @override
  String get adminJobManagement_filterAll => 'All';

  @override
  String get adminJobManagement_filterCompleted => 'Completed';

  @override
  String get adminJobManagement_filterDraft => 'Draft';

  @override
  String get adminJobManagement_loadFailed => 'Failed to load';

  @override
  String get adminJobManagement_locationNotSet => 'Location not set';

  @override
  String get adminJobManagement_noJobs => 'No jobs';

  @override
  String get adminJobManagement_noPermission => 'No permission';

  @override
  String get adminJobManagement_noTitle => 'No title';

  @override
  String get adminJobManagement_postHint => 'Add jobs using the Post button';

  @override
  String get adminJobManagement_postJob => 'Post job';

  @override
  String get adminJobManagement_searchHint => 'Search jobs...';

  @override
  String get adminJobManagement_showMore => 'Show more';

  @override
  String get adminJob_viewJobs => 'Jobs';

  @override
  String get adminJob_viewApplications => 'All Applications';

  @override
  String adminJob_summaryTotal(String count) {
    return 'Total $count';
  }

  @override
  String adminJob_summaryActive(String count) {
    return '$count active';
  }

  @override
  String adminJob_summaryCompleted(String count) {
    return '$count completed';
  }

  @override
  String adminApplicants_summaryPending(String count) {
    return '$count pending';
  }

  @override
  String adminApplicants_summaryAssigned(String count) {
    return '$count assigned';
  }

  @override
  String adminApplicants_summaryInProgress(String count) {
    return '$count in progress';
  }

  @override
  String adminApplicants_summaryDone(String count) {
    return '$count done';
  }

  @override
  String get adminWorker_title => 'Worker Detail';

  @override
  String get adminWorker_applicationHistory => 'Application History';

  @override
  String get adminWorker_qualifications => 'Qualifications';

  @override
  String get adminWorker_unknownWorker => 'Unknown worker';

  @override
  String get adminWorker_noApplications => 'No application history';

  @override
  String get adminWorker_noQualifications => 'No qualifications';

  @override
  String get adminLogin => 'Admin Login';

  @override
  String get adminLoginDescription => 'Enter admin password';

  @override
  String get adminLogin_email => 'Email';

  @override
  String get adminLogin_emailInvalid => 'Invalid email format';

  @override
  String get adminLogin_emailRequired => 'Email is required';

  @override
  String adminLogin_lockoutMessage(String minutes, String seconds) {
    return 'Too many login attempts. Please try again in ${minutes}m ${seconds}s';
  }

  @override
  String get adminLogin_login => 'Log in';

  @override
  String get adminLogin_loginSuccess => 'Login successful';

  @override
  String get adminLogin_password => 'Password';

  @override
  String get adminLogin_passwordMinLength =>
      'Password must be at least 6 characters';

  @override
  String get adminLogin_passwordRequired => 'Password is required';

  @override
  String get adminLogin_title => 'Admin Login';

  @override
  String get adminPassword => 'Admin Password';

  @override
  String get adminPayments => 'Payment Management';

  @override
  String get adminQualifications_approve => 'Approve';

  @override
  String get adminQualifications_approveError => 'Failed to approve';

  @override
  String adminQualifications_approveSuccess(String name) {
    return '$name approved';
  }

  @override
  String adminQualifications_category(String category) {
    return 'Category: $category';
  }

  @override
  String get adminQualifications_emptyDescription =>
      'When workers register qualifications, they will appear here for review.';

  @override
  String get adminQualifications_emptyTitle =>
      'No qualifications pending review';

  @override
  String get adminQualifications_imageLoadError => 'Failed to load image';

  @override
  String get adminQualifications_loadError => 'Failed to load qualifications';

  @override
  String get adminQualifications_noName => 'No name';

  @override
  String get adminQualifications_pendingApproval => 'Pending approval';

  @override
  String get adminQualifications_reject => 'Reject';

  @override
  String get adminQualifications_rejectButton => 'Reject';

  @override
  String get adminQualifications_rejectError => 'Failed to reject';

  @override
  String get adminQualifications_rejectReasonHint =>
      'Enter the reason for rejection';

  @override
  String get adminQualifications_rejectReasonRequired =>
      'Please enter a reason for rejection';

  @override
  String get adminQualifications_rejectReasonTitle => 'Rejection reason';

  @override
  String adminQualifications_rejectSuccess(String name) {
    return '$name rejected';
  }

  @override
  String get adminQualifications_title => 'Qualification Management';

  @override
  String get adminSearch_hint => 'Search...';

  @override
  String get adminUsers => 'User Management';

  @override
  String get agreeToPrivacy => 'I agree to the Privacy Policy';

  @override
  String get agreeToTerms => 'I agree to the Terms of Service';

  @override
  String get allPrefectures => 'All areas';

  @override
  String get alreadyApplied => 'Already applied';

  @override
  String get amount => 'Amount';

  @override
  String get appName => 'ALBAWORK';

  @override
  String get appTagline => 'Construction Job Matching App';

  @override
  String get appleLoginSuccess => 'Signed in with Apple';

  @override
  String get applicant => 'Applicant';

  @override
  String get applicationConfirm => 'Apply for this job?';

  @override
  String get applicationDate => 'Application Date';

  @override
  String get applicationSuccess => 'Application submitted';

  @override
  String get apply => 'Apply';

  @override
  String get applyForJob => 'Apply for this job';

  @override
  String get asyncValue_errorOccurred => 'An error occurred';

  @override
  String get asyncValue_loadFailed => 'Failed to load';

  @override
  String get asyncValue_networkError => 'Network error';

  @override
  String get asyncValue_permissionDenied => 'Permission denied';

  @override
  String get authError => 'Authentication error occurred';

  @override
  String get authGate_authError =>
      'An error occurred during authentication.\nPlease try again.';

  @override
  String get authGate_roleError => 'Failed to retrieve user information';

  @override
  String get back => 'Back';

  @override
  String get birthDate => 'Date of Birth';

  @override
  String get cameraPermissionRequired => 'Camera permission is required';

  @override
  String get cancel => 'Cancel';

  @override
  String get changeName => 'Change Name';

  @override
  String get changePassword => 'Change Password';

  @override
  String get chatRoom_attachImage => 'Attach image';

  @override
  String get chatRoom_imageSendFailed => 'Failed to send image';

  @override
  String get chatRoom_inputHint => 'Type a message...';

  @override
  String get chatRoom_loadError => 'Failed to load chat';

  @override
  String get chatRoom_loginRequired => 'Login required to chat';

  @override
  String get chatRoom_notReady => 'Chat is not ready yet';

  @override
  String get chatRoom_pickFromGallery => 'Choose from gallery';

  @override
  String get chatRoom_read => 'Read';

  @override
  String get chatRoom_retry => 'Retry';

  @override
  String get chatRoom_sendFailed => 'Failed to send message';

  @override
  String get chatRoom_startConversation => 'Start a conversation';

  @override
  String get chatRoom_takePhoto => 'Take photo';

  @override
  String get chatRoom_title => 'Chat';

  @override
  String get chatRoom_today => 'Today';

  @override
  String get chatRoom_uploadFailed => 'Upload failed';

  @override
  String get chatRoom_yesterday => 'Yesterday';

  @override
  String get chatWith => 'Chat';

  @override
  String get checkIn => 'Check In';

  @override
  String get checkInSuccess => 'Checked in successfully';

  @override
  String get checkOut => 'Check Out';

  @override
  String get checkOutSuccess => 'Checked out successfully';

  @override
  String get checkedIn => 'Checked In';

  @override
  String get checkedOut => 'Checked Out';

  @override
  String get close => 'Close';

  @override
  String get common_adminOnlyView => 'Visible to administrators only';

  @override
  String get common_all => 'All';

  @override
  String get common_approve => 'Approve';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_completed => 'Completed';

  @override
  String get common_confirmed => 'Confirmed';

  @override
  String get common_dataLoadError => 'Failed to load data';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_deleted => 'Deleted';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_itemsCount => ' items';

  @override
  String get common_job => 'Job';

  @override
  String common_loadError(String error) {
    return 'Load error: $error';
  }

  @override
  String get common_noTitle => 'No Title';

  @override
  String get common_notSet => 'Not Set';

  @override
  String get common_ok => 'OK';

  @override
  String get common_pleaseLogin => 'Please log in';

  @override
  String get common_registerToSaveFavorites =>
      'Registration is required to save favorites';

  @override
  String get common_registerToStart => 'Register to start';

  @override
  String get common_registering => 'Registering...';

  @override
  String get common_reject => 'Reject';

  @override
  String get common_save => 'Save';

  @override
  String get common_select => 'Select';

  @override
  String get common_selected => ' (Selected)';

  @override
  String get common_transferred => 'Transferred';

  @override
  String get common_undecided => 'TBD';

  @override
  String get common_unknown => 'Unknown';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get contactBody => 'Message';

  @override
  String get contactCategory => 'Category';

  @override
  String get contactCategoryBug => 'Bug Report';

  @override
  String get contactCategoryFeature => 'Feature Request';

  @override
  String get contactCategoryGeneral => 'General';

  @override
  String get contactCategoryOther => 'Other';

  @override
  String get contactCategoryPayment => 'Payment';

  @override
  String get contactSent => 'Message sent successfully';

  @override
  String get contactSubject => 'Subject';

  @override
  String get contactTitle => 'Contact Us';

  @override
  String get contact_bodyHint => 'Enter your message';

  @override
  String get contact_bodyLabel => 'Message';

  @override
  String get contact_categoryAccount => 'Account';

  @override
  String get contact_categoryBug => 'Bug report';

  @override
  String get contact_categoryGeneral => 'General inquiry';

  @override
  String get contact_categoryJobs => 'Jobs';

  @override
  String get contact_categoryLabel => 'Category';

  @override
  String get contact_categoryOther => 'Other';

  @override
  String get contact_categoryPayment => 'Payment';

  @override
  String get contact_sendError => 'Failed to send';

  @override
  String get contact_sendSuccess => 'Inquiry sent';

  @override
  String get contact_subjectHint => 'Enter the subject';

  @override
  String get contact_subjectLabel => 'Subject';

  @override
  String get contact_submitButton => 'Send';

  @override
  String get contact_title => 'Contact Us';

  @override
  String get contact_validationError => 'Please fill in all required fields';

  @override
  String get createEarnings => 'Record Earnings';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get dataExportSuccess => 'Data exported';

  @override
  String get dateSelect => 'Select date';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm =>
      'Delete your account? This action cannot be undone.';

  @override
  String get deleteAccountSuccess => 'Account deleted';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteJobConfirm => 'Delete this job?';

  @override
  String get dispatchLaw => 'Worker Dispatch Act';

  @override
  String get displayName => 'Display Name';

  @override
  String get downloadData => 'Download Data';

  @override
  String get earningsCreate_adminOnly =>
      'Stripe payments are available to administrators only';

  @override
  String get earningsCreate_amountHint => 'e.g. 15000';

  @override
  String get earningsCreate_amountLabel => 'Amount (tax included)';

  @override
  String get earningsCreate_applicantUidEmpty => 'Applicant UID is empty';

  @override
  String get earningsCreate_earningRegistered => 'Earnings registered';

  @override
  String get earningsCreate_earningsNote =>
      '* Earnings will be reflected after administrator review';

  @override
  String get earningsCreate_enterAmount => 'Please enter an amount';

  @override
  String get earningsCreate_enterAmountExample =>
      'Please enter an amount (e.g. 15000)';

  @override
  String get earningsCreate_noAssignedJobs => 'No assigned jobs';

  @override
  String get earningsCreate_paymentDateLabel => 'Payment date';

  @override
  String get earningsCreate_registerButton => 'Register earnings';

  @override
  String earningsCreate_registerFailed(String error) {
    return 'Registration failed: $error';
  }

  @override
  String get earningsCreate_searchHint => 'Search jobs...';

  @override
  String get earningsCreate_selectFromList =>
      'Please select a job from the list above';

  @override
  String get earningsCreate_selectJob => 'Please select a job first';

  @override
  String get earningsCreate_selectPaymentDate => 'Please select a payment date';

  @override
  String earningsCreate_stripeCreated(String paymentId) {
    return 'Stripe payment created (ID: $paymentId)';
  }

  @override
  String earningsCreate_stripeFailed(String error) {
    return 'Stripe payment failed: $error';
  }

  @override
  String get earningsCreate_stripePayButton => 'Create Stripe payment';

  @override
  String get earningsCreate_title => 'Register Earnings';

  @override
  String get earningsCreated => 'Earnings recorded';

  @override
  String get earningsDetail => 'Earnings Details';

  @override
  String get edit => 'Edit';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get ekycApproveConfirm => 'Approve this identity verification?';

  @override
  String get ekycApproved => 'Identity verified';

  @override
  String get ekycDocumentType => 'Document Type';

  @override
  String get ekycDriversLicense => 'Driver\'s License';

  @override
  String get ekycMyNumber => 'My Number Card';

  @override
  String get ekycPassport => 'Passport';

  @override
  String get ekycPendingReview => 'Identity Verification Request';

  @override
  String get ekycRejectConfirm => 'Reject this identity verification?';

  @override
  String get ekycRejected => 'Identity verification rejected';

  @override
  String get ekycRejectionReason => 'Reason for Rejection';

  @override
  String get ekycResidenceCard => 'Residence Card';

  @override
  String get ekycResubmit => 'Resubmit';

  @override
  String get ekycTitle => 'Identity Verification';

  @override
  String get email => 'Email';

  @override
  String get emailAlreadyInUse => 'This email is already registered';

  @override
  String emailAuthDialog_authError(String code) {
    return 'Authentication error: $code';
  }

  @override
  String get emailAuthDialog_emailAlreadyInUse =>
      'This email is already in use';

  @override
  String get emailAuthDialog_emailLabel => 'Email address';

  @override
  String get emailAuthDialog_enterEmailAndPassword =>
      'Please enter your email and password';

  @override
  String get emailAuthDialog_hidePassword => 'Hide password';

  @override
  String get emailAuthDialog_invalidEmail => 'Invalid email format';

  @override
  String get emailAuthDialog_loginButton => 'Log In';

  @override
  String get emailAuthDialog_loginFailed => 'Login failed';

  @override
  String get emailAuthDialog_loginLocked =>
      'Too many login attempts. Please wait a moment';

  @override
  String get emailAuthDialog_loginSuccess => 'Logged in successfully';

  @override
  String get emailAuthDialog_operationNotAllowed =>
      'This authentication method is currently unavailable';

  @override
  String get emailAuthDialog_passwordLabel => 'Password';

  @override
  String get emailAuthDialog_passwordMinLength =>
      'Password must be at least 6 characters';

  @override
  String get emailAuthDialog_showPassword => 'Show password';

  @override
  String get emailAuthDialog_signUpButton => 'Sign Up';

  @override
  String get emailAuthDialog_signUpFailed => 'Account creation failed';

  @override
  String get emailAuthDialog_signUpHint =>
      'If you don\'t have an account, tap \"Sign Up\"';

  @override
  String get emailAuthDialog_signUpSuccess => 'Account created successfully';

  @override
  String get emailAuthDialog_title => 'Sign in with email';

  @override
  String get emailAuthDialog_weakPassword =>
      'Password is too weak. Use at least 6 characters';

  @override
  String get emailAuthDialog_wrongCredentials => 'Incorrect email or password';

  @override
  String get emailAuth_cancel => 'Cancel';

  @override
  String get emailAuth_emailInvalid => 'Invalid email format';

  @override
  String get emailAuth_emailLabel => 'Email address';

  @override
  String get emailAuth_emailRequired => 'Please enter your email address';

  @override
  String get emailAuth_errorEmailInUse => 'This email is already registered';

  @override
  String emailAuth_errorGeneric(String code) {
    return 'An error occurred ($code)';
  }

  @override
  String get emailAuth_errorInvalidEmail => 'Invalid email format';

  @override
  String get emailAuth_errorNetwork => 'Please check your network connection';

  @override
  String get emailAuth_errorTooManyRequests =>
      'Too many requests. Please try again later';

  @override
  String get emailAuth_errorUserDisabled => 'This account has been disabled';

  @override
  String get emailAuth_errorUserNotFound => 'Account not found';

  @override
  String get emailAuth_errorWeakPassword =>
      'Password is too weak. Use at least 6 characters';

  @override
  String get emailAuth_errorWrongPassword => 'Incorrect password';

  @override
  String get emailAuth_forgotPassword => 'Forgot password?';

  @override
  String get emailAuth_loginButton => 'Log in';

  @override
  String get emailAuth_passwordConfirmLabel => 'Confirm password';

  @override
  String get emailAuth_passwordConfirmRequired =>
      'Please re-enter your password';

  @override
  String get emailAuth_passwordLabel => 'Password';

  @override
  String get emailAuth_passwordMinLength =>
      'Password must be at least 6 characters';

  @override
  String get emailAuth_passwordMismatch => 'Passwords do not match';

  @override
  String get emailAuth_passwordRequired => 'Please enter your password';

  @override
  String get emailAuth_passwordResetTitle => 'Password Reset';

  @override
  String get emailAuth_passwordWithMinLength => 'Password (6+ characters)';

  @override
  String get emailAuth_registerButton => 'Sign up';

  @override
  String get emailAuth_sendButton => 'Send';

  @override
  String get emailAuth_snackLoginFailed => 'Login failed';

  @override
  String get emailAuth_snackRegisterFailed => 'Registration failed';

  @override
  String get emailAuth_snackResetSent => 'Password reset email sent';

  @override
  String get emailAuth_snackSendFailed => 'Failed to send';

  @override
  String get emailAuth_tabLogin => 'Log in';

  @override
  String get emailAuth_tabRegister => 'Sign up';

  @override
  String get emailAuth_title => 'Continue with email';

  @override
  String get employer => 'Employer';

  @override
  String get employmentSecurityLaw => 'Employment Security Act';

  @override
  String get errorDataNotFound => 'Data not found';

  @override
  String get errorDefaultMessage => 'Please try again later';

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get errorLabel => 'Error';

  @override
  String get errorNetwork => 'A network error occurred';

  @override
  String get errorNetworkMessage =>
      'Please check your internet connection\nand try again';

  @override
  String get errorNetworkTitle => 'Network Error';

  @override
  String get errorRetry_emptyMessage => 'Try changing your search criteria';

  @override
  String get errorRetry_emptyTitle => 'No Data Found';

  @override
  String get errorRetry_generalMessage => 'An unexpected error occurred';

  @override
  String get errorRetry_generalTitle => 'Error occurred';

  @override
  String get errorRetry_networkErrorMessage =>
      'Please check your internet connection';

  @override
  String get errorRetry_networkErrorTitle => 'Network Error';

  @override
  String get errorRetry_timeoutMessage =>
      'Connection timed out. Please try again';

  @override
  String get errorRetry_timeoutTitle => 'Timeout';

  @override
  String get errorSearchRetry =>
      'Please change your search criteria and try again';

  @override
  String get errorTimeout => 'Timeout';

  @override
  String get errorTimeoutMessage =>
      'The connection is taking too long\nPlease try again';

  @override
  String get experienceYears => 'Years of Experience';

  @override
  String get familyName => 'Last Name';

  @override
  String get familyNameKana => 'Last Name (Kana)';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faq_a1 =>
      'Download the app and create an account with your email, LINE, or phone number.';

  @override
  String get faq_a2 =>
      'Browse available jobs on the search page and tap \"Apply\" on the job you want.';

  @override
  String get faq_a3 =>
      'Payments are processed on the 10th of each month for work completed the previous month.';

  @override
  String get faq_a4 =>
      'Use the QR code attendance feature on-site. Scan the QR code provided by the site supervisor.';

  @override
  String get faq_a5 =>
      'Requirements vary by job. Some jobs require specific construction qualifications. Check the job details.';

  @override
  String get faq_a6 =>
      'Use the chat feature to contact the job supervisor directly, or submit a daily report through the app.';

  @override
  String get faq_a7 =>
      'You can cancel applications before they are approved. Contact the supervisor for cancellations after approval.';

  @override
  String get faq_a8 =>
      'Go to Profile > Identity Verification and upload your ID document and a selfie.';

  @override
  String get faq_q1 => 'How do I register?';

  @override
  String get faq_q2 => 'How do I apply for a job?';

  @override
  String get faq_q3 => 'When do I get paid?';

  @override
  String get faq_q4 => 'How do I check in/out?';

  @override
  String get faq_q5 => 'What qualifications do I need?';

  @override
  String get faq_q6 => 'How do I report issues on-site?';

  @override
  String get faq_q7 => 'Can I cancel an application?';

  @override
  String get faq_q8 => 'How do I verify my identity?';

  @override
  String get faq_title => 'FAQ';

  @override
  String get favorites_empty => 'No favorites yet';

  @override
  String get favorites_emptyDescription =>
      'Add jobs you like to your favorites';

  @override
  String get favorites_loginRequired => 'Login required';

  @override
  String get favorites_noTitle => 'No title';

  @override
  String get favorites_title => 'Favorites';

  @override
  String get featureQuickEarn => 'Quick Earnings';

  @override
  String get featureSearch => 'Find Jobs';

  @override
  String get featureSecurePayment => 'Secure Payments';

  @override
  String get filterByPrefecture => 'Filter by prefecture';

  @override
  String get forceUpdate_available => 'Update Available';

  @override
  String get forceUpdate_availableMessage =>
      'A new version is available. Would you like to update?';

  @override
  String get forceUpdate_later => 'Later';

  @override
  String get forceUpdate_required => 'Update Required';

  @override
  String get forceUpdate_requiredMessage =>
      'Please update to the latest version to continue using the app.';

  @override
  String get forceUpdate_update => 'Update';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get gender => 'Gender';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderMale => 'Male';

  @override
  String get genderOther => 'Other';

  @override
  String get getStarted => 'Get Started';

  @override
  String get givenName => 'First Name';

  @override
  String get givenNameKana => 'First Name (Kana)';

  @override
  String get guestCannotApply => 'Guests cannot apply. Please log in';

  @override
  String get guestHome_agreeByLogin =>
      'By logging in, you agree to our Terms of Service and Privacy Policy';

  @override
  String get guestHome_appleLoginSuccess => 'Apple login successful';

  @override
  String get guestHome_emailLogin => 'Log in with email';

  @override
  String get guestHome_featureEarn => 'Earn money';

  @override
  String get guestHome_featurePayment => 'Easy payment';

  @override
  String get guestHome_featureSearch => 'Find jobs';

  @override
  String get guestHome_guestLoginSuccess => 'Continuing as guest';

  @override
  String get guestHome_lineLogin => 'Log in with LINE';

  @override
  String get guestHome_phoneLogin => 'Log in with phone';

  @override
  String get guestHome_privacyPolicy => 'Privacy Policy';

  @override
  String get guestHome_startAsGuest => 'Continue as guest';

  @override
  String get guestHome_subtitle => 'Find construction jobs near you';

  @override
  String get guestHome_termsOfService => 'Terms of Service';

  @override
  String get guestLoginSuccess => 'Logged in as guest';

  @override
  String get guestModeWarning => 'Some features are limited in guest mode';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get home_admin => 'Admin';

  @override
  String get home_greetingAfternoon => 'Good afternoon';

  @override
  String get home_greetingEvening => 'Good evening';

  @override
  String get home_greetingMorning => 'Good morning';

  @override
  String get home_navMessages => 'Messages';

  @override
  String get home_navProfile => 'Profile';

  @override
  String get home_navSales => 'Earnings';

  @override
  String get home_navSearch => 'Search';

  @override
  String get home_navSelected => ', selected';

  @override
  String home_navTabLabel(String label, String suffix) {
    return '$label tab$suffix';
  }

  @override
  String get home_navWork => 'Work';

  @override
  String home_notifications(String count) {
    return 'Notifications, $count unread';
  }

  @override
  String home_notificationsUnread(String count) {
    return 'Notifications, $count unread';
  }

  @override
  String get home_postJob => 'Post job';

  @override
  String get home_statusAdmin => 'Admin mode';

  @override
  String get identityVerification => 'Identity Verification';

  @override
  String get identityVerification_documentTypeLabel => 'Document type';

  @override
  String get identityVerification_ekycBanner =>
      'Submitted documents will be reviewed by an administrator based on eKYC (online identity verification).';

  @override
  String get identityVerification_idDocumentSubtitle =>
      'Driver\'s license, My Number card, etc.';

  @override
  String get identityVerification_idDocumentTitle => 'ID Document';

  @override
  String get identityVerification_instructions =>
      'Please upload a photo of your ID document and a selfie for identity verification.';

  @override
  String get identityVerification_loadStatusFailed =>
      'Failed to load verification status';

  @override
  String identityVerification_rejectionReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get identityVerification_resubmitButton => 'Resubmit';

  @override
  String get identityVerification_selfieSubtitle =>
      'Make sure your full face is visible';

  @override
  String get identityVerification_selfieTitle => 'Selfie';

  @override
  String get identityVerification_statusApproved => 'Identity verified';

  @override
  String get identityVerification_statusPending => 'Under review. Please wait';

  @override
  String get identityVerification_statusRejected =>
      'Identity verification rejected';

  @override
  String get identityVerification_stepSelfie => 'Selfie';

  @override
  String get identityVerification_stepSubmit => 'Submit';

  @override
  String get identityVerification_stepUploadId => 'ID';

  @override
  String get identityVerification_submitButton => 'Submit verification';

  @override
  String identityVerification_submitFailed(String error) {
    return 'Submission failed: $error';
  }

  @override
  String get identityVerification_submitted =>
      'Verification submitted. Please wait for review';

  @override
  String get identityVerification_tapToSelect => 'Tap to select';

  @override
  String get identityVerification_title => 'Identity Verification';

  @override
  String get identityVerification_uploadBoth =>
      'Please upload both an ID document and a selfie';

  @override
  String get imagePicker_camera => 'Camera';

  @override
  String get imagePicker_cancel => 'Cancel';

  @override
  String get imagePicker_error => 'Failed to select image';

  @override
  String get imagePicker_gallery => 'Gallery';

  @override
  String get imagePicker_galleryMultiple => 'Gallery (multiple)';

  @override
  String get imagePicker_noImageSelected => 'No image selected';

  @override
  String get imagePicker_selectImage => 'Select image';

  @override
  String imagePicker_uploadPartial(String successCount, String failedCount) {
    return '$successCount succeeded, $failedCount failed';
  }

  @override
  String imagePicker_uploadSuccess(String count) {
    return 'Uploaded $count images';
  }

  @override
  String get imagePicker_uploaded => 'Uploaded';

  @override
  String get inspection_checklist => 'Inspection checklist';

  @override
  String inspection_completedLog(String result) {
    return 'Inspection complete: $result';
  }

  @override
  String get inspection_fail => 'Fail';

  @override
  String get inspection_failedFixRequest =>
      'Inspection failed. Fix request sent';

  @override
  String get inspection_needsFix => 'Needs fix';

  @override
  String get inspection_overallComment => 'Overall comment';

  @override
  String get inspection_pass => 'Pass';

  @override
  String get inspection_passed => 'Passed';

  @override
  String get inspection_passedComplete => 'Inspection passed. Job completed';

  @override
  String inspection_submitFailed(String error) {
    return 'Failed to submit inspection: $error';
  }

  @override
  String get inspection_submitResult => 'Submit results';

  @override
  String get inspection_title => 'Inspection';

  @override
  String get introduction => 'Introduction';

  @override
  String get invalidEmail => 'Invalid email format';

  @override
  String get inviteFriends => 'Invite Friends';

  @override
  String get inviteFriendsSubtitle => 'Invite friends with your referral code';

  @override
  String itemCount(String count) {
    return '$count items';
  }

  @override
  String get jobCard_actions => 'Actions';

  @override
  String get jobCard_addFavorite => 'Add to favorites';

  @override
  String get jobCard_delete => 'Delete';

  @override
  String get jobCard_edit => 'Edit';

  @override
  String get jobCard_noOwnerId => 'No owner ID';

  @override
  String get jobCard_perDay => 'per day';

  @override
  String get jobCard_quickStart => 'Quick start';

  @override
  String jobCard_remainingSlots(String count) {
    return '$count slots left';
  }

  @override
  String get jobCard_removeFavorite => 'Remove from favorites';

  @override
  String jobCard_semanticsLabel(
    String title,
    String location,
    String date,
    String price,
  ) {
    return '$title, Location: $location, Date: $date, Pay: $price';
  }

  @override
  String get jobCreateTitle => 'Create Job';

  @override
  String get jobDate => 'Work Date';

  @override
  String get jobDeleted => 'Job deleted';

  @override
  String get jobDescription => 'Job Description';

  @override
  String get jobDetail => 'Job Details';

  @override
  String get jobDetail_addToFavorites => 'Add to favorites';

  @override
  String jobDetail_applicationReceived(String projectName) {
    return 'New application received for $projectName';
  }

  @override
  String get jobDetail_applied => 'Applied';

  @override
  String get jobDetail_applyButton => 'Apply';

  @override
  String get jobDetail_applyError => 'Failed to apply';

  @override
  String get jobDetail_applyToJob => 'Apply to Job';

  @override
  String get jobDetail_applyToThisJob => 'Apply to this job';

  @override
  String get jobDetail_category => 'Category';

  @override
  String get jobDetail_checking => 'Checking...';

  @override
  String get jobDetail_checkingStatus => 'Checking...';

  @override
  String get jobDetail_defaultDescription =>
      'No details have been registered yet.';

  @override
  String get jobDetail_defaultNotes => 'No special notes.';

  @override
  String get jobDetail_deleteConfirmMessage =>
      'Are you sure you want to delete this job? This action cannot be undone.';

  @override
  String get jobDetail_deleteConfirmTitle => 'Delete Job';

  @override
  String get jobDetail_deleteError => 'Failed to delete';

  @override
  String get jobDetail_deleteThisJob => 'Delete this job';

  @override
  String get jobDetail_favorite => 'Favorite';

  @override
  String get jobDetail_jobDescription => 'Job Description';

  @override
  String get jobDetail_legacyData => 'Legacy Data';

  @override
  String get jobDetail_locationLabel => 'Location';

  @override
  String get jobDetail_mayBeDeleted => 'This job may have been deleted';

  @override
  String get jobDetail_newApplication => 'New Application';

  @override
  String get jobDetail_notes => 'Notes & Precautions';

  @override
  String get jobDetail_paymentLabel => 'Payment';

  @override
  String get jobDetail_removeFromFavorites => 'Remove from favorites';

  @override
  String get jobDetail_scheduleLabel => 'Schedule';

  @override
  String get jobDetail_share => 'Share';

  @override
  String get jobDetail_snackApplied => 'Application submitted';

  @override
  String get jobDetail_status => 'Status';

  @override
  String get jobDetail_title => 'Job Details';

  @override
  String get jobEditTitle => 'Edit Job';

  @override
  String get jobEdit_dateHint => 'Tap to select date';

  @override
  String get jobEdit_dateLabel => 'Schedule';

  @override
  String get jobEdit_datePickerCancel => 'Cancel';

  @override
  String get jobEdit_datePickerConfirm => 'Confirm';

  @override
  String get jobEdit_datePickerHelp => 'Select a date';

  @override
  String get jobEdit_descriptionHint =>
      'e.g. On-site assistance, cleaning, material transport';

  @override
  String get jobEdit_descriptionLabel => 'Job description';

  @override
  String get jobEdit_hintBody =>
      'After updating, you will return to the list. Select dates from the calendar. Setting latitude/longitude enables GPS verification for QR attendance.';

  @override
  String get jobEdit_hintTitle => 'Hint';

  @override
  String get jobEdit_latitudeHint => 'e.g. 35.6812';

  @override
  String get jobEdit_latitudeLabel => 'Latitude (optional)';

  @override
  String get jobEdit_locationHint => 'e.g. Hanamigawa-ku, Chiba City, Chiba';

  @override
  String get jobEdit_locationLabel => 'Location';

  @override
  String get jobEdit_longitudeHint => 'e.g. 139.7671';

  @override
  String get jobEdit_longitudeLabel => 'Longitude (optional)';

  @override
  String get jobEdit_notesHint =>
      'e.g. No tardiness, safety first, confirm details via chat';

  @override
  String get jobEdit_notesLabel => 'Notes';

  @override
  String get jobEdit_priceHint => 'e.g. 30000';

  @override
  String get jobEdit_priceLabel => 'Payment (JPY)';

  @override
  String get jobEdit_sectionSubtitle => 'Please update the job information';

  @override
  String get jobEdit_sectionTitle => 'Edit details';

  @override
  String get jobEdit_snackEmptyFields => 'Some fields are empty';

  @override
  String get jobEdit_snackPriceNumeric => 'Please enter a numeric amount';

  @override
  String get jobEdit_snackSelectDateFromCalendar =>
      'Please select a date from the calendar';

  @override
  String jobEdit_snackUpdateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get jobEdit_title => 'Edit Job';

  @override
  String get jobEdit_titleHint => 'e.g. Wallpaper replacement (1LDK)';

  @override
  String get jobEdit_titleLabel => 'Title';

  @override
  String get jobEdit_updateButton => 'Update';

  @override
  String get jobFilter_areaHint => 'Select area';

  @override
  String get jobFilter_areaLabel => 'Area';

  @override
  String get jobFilter_dateRange => 'Date range';

  @override
  String get jobFilter_dateSeparator => '~';

  @override
  String get jobFilter_endDate => 'End date';

  @override
  String get jobFilter_priceRange => 'Pay range';

  @override
  String get jobFilter_qualBuildingManagement =>
      'Building Construction Supervisor';

  @override
  String get jobFilter_qualCivilEngineering => 'Civil Engineering Supervisor';

  @override
  String get jobFilter_qualElectrician => 'Electrician';

  @override
  String get jobFilter_qualForklift => 'Forklift Operator';

  @override
  String get jobFilter_qualHazmat => 'Hazardous Materials Handler';

  @override
  String get jobFilter_qualScaffolding => 'Scaffolding Worker';

  @override
  String get jobFilter_qualSlinging => 'Slinger';

  @override
  String get jobFilter_qualWelding => 'Welder';

  @override
  String get jobFilter_requiredQualifications => 'Required qualifications';

  @override
  String get jobFilter_reset => 'Reset';

  @override
  String get jobFilter_searchButton => 'Search';

  @override
  String get jobFilter_startDate => 'Start date';

  @override
  String get jobFilter_title => 'Search Filter';

  @override
  String get jobListTitle => 'Job Listings';

  @override
  String get jobList_dataLoadError => 'Failed to load data';

  @override
  String get jobList_deleteConfirmMessage =>
      'Are you sure you want to delete this job? This action cannot be undone.';

  @override
  String get jobList_deleteConfirmTitle => 'Delete Job';

  @override
  String get jobList_deleteError => 'Failed to delete';

  @override
  String get jobList_fetchJobsError => 'Failed to fetch job information';

  @override
  String get jobList_filter => 'Filter';

  @override
  String get jobList_filterActiveLabel => 'Filters active';

  @override
  String get jobList_locationError => 'Failed to get location';

  @override
  String get jobList_monthLabel => 'Month';

  @override
  String get jobList_nextMonth => 'Next month';

  @override
  String get jobList_noJobs => 'No jobs available';

  @override
  String get jobList_noJobsDescription =>
      'There are currently no jobs matching this criteria.';

  @override
  String get jobList_noMatchingJobs => 'No matching jobs';

  @override
  String get jobList_noMatchingJobsDescription =>
      'Please change conditions and search again.';

  @override
  String get jobList_openSearchFilter => 'Open search filter';

  @override
  String get jobList_prefChiba => 'Chiba';

  @override
  String get jobList_prefKanagawa => 'Kanagawa';

  @override
  String get jobList_prefOther => 'Other';

  @override
  String get jobList_prefTokyo => 'Tokyo';

  @override
  String get jobList_searchByAreaCondition => 'Search by area & conditions';

  @override
  String get jobList_sortDistance => 'By Distance';

  @override
  String get jobList_sortHighestPay => 'Highest Pay';

  @override
  String get jobList_sortNewest => 'Newest First';

  @override
  String get jobList_sortTooltip => 'Sort';

  @override
  String get jobList_thisMonth => 'This month';

  @override
  String get jobList_viewOnMap => 'Map View';

  @override
  String get jobList_viewGrid => 'Switch to grid view';

  @override
  String get jobList_viewList => 'Switch to list view';

  @override
  String get jobList_viewOnMapAccessibility => 'View jobs on map';

  @override
  String get jobLocation => 'Location';

  @override
  String get jobNotes => 'Notes';

  @override
  String get jobOverview => 'Overview';

  @override
  String get jobPrice => 'Pay';

  @override
  String get jobSaved => 'Job saved';

  @override
  String get jobTitle => 'Job Title';

  @override
  String get laborInsurance => 'Workers\' Compensation Insurance';

  @override
  String get legalCompliance => 'Legal Compliance';

  @override
  String get legalDocuments => 'Legal Documents';

  @override
  String get legalIndex => 'Legal Information';

  @override
  String get legalIndex_compliance => 'Labor Law Compliance';

  @override
  String get legalIndex_dispatchLaw => 'Worker Dispatch Act';

  @override
  String get legalIndex_employmentSecurityLaw => 'Employment Security Act';

  @override
  String get legalIndex_laborInsurance => 'Labor Insurance';

  @override
  String get legalIndex_legalDocuments => 'Legal Documents';

  @override
  String get legalIndex_privacyPolicy => 'Privacy Policy';

  @override
  String get legalIndex_termsOfService => 'Terms of Service';

  @override
  String get legalIndex_title => 'Legal Information';

  @override
  String get legalInfo => 'Legal Information';

  @override
  String get legalInfoSubtitle =>
      'Privacy Policy, Terms of Service, Legal Info';

  @override
  String get loadMore => 'Load More';

  @override
  String get loadMore_showMore => 'Show more';

  @override
  String get loading => 'Loading...';

  @override
  String get locationPermissionRequired => 'Location permission is required';

  @override
  String get login => 'Log In';

  @override
  String get loginSuccess => 'Logged in successfully';

  @override
  String get logout => 'Log Out';

  @override
  String get logoutConfirm => 'Log out?';

  @override
  String get logoutSuccess => 'Logged out';

  @override
  String get mapSearch_details => 'Details';

  @override
  String get mapSearch_noJobs => 'No jobs in this area';

  @override
  String get mapSearch_noTitle => 'No title';

  @override
  String get mapSearch_notSet => 'Not set';

  @override
  String mapSearch_pricePerDay(String price) {
    return '¥$price /day';
  }

  @override
  String get mapSearch_title => 'Map Search';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messages_emptyAdmin => 'No chat rooms yet';

  @override
  String get messages_emptyDescription =>
      'Chat will begin when you apply for a job';

  @override
  String get messages_emptyUser => 'No messages yet';

  @override
  String get messages_featureName => 'Messages';

  @override
  String get messages_noSearchResults => 'No search results';

  @override
  String get messages_registrationRequiredDescription =>
      'Register to use the messaging feature.';

  @override
  String get messages_registrationRequiredTitle =>
      'Registration required to use messages';

  @override
  String get messages_searchHint => 'Search messages...';

  @override
  String messages_statusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String get messages_title => 'Messages';

  @override
  String get messages_titleAdmin => 'Messages (Admin)';

  @override
  String get messages_tryDifferentKeyword => 'Try a different keyword';

  @override
  String get myProfile => 'Profile';

  @override
  String get myProfile_addQualification => 'Add Qualification';

  @override
  String get myProfile_addressHint => 'e.g. Shibuya, Tokyo...';

  @override
  String get myProfile_addressLabel => 'Address';

  @override
  String get myProfile_addressSection => 'Address';

  @override
  String get myProfile_adminRating => 'Rating from administrators';

  @override
  String get myProfile_avatarUpdated => 'Profile photo updated';

  @override
  String get myProfile_avatarUploadError => 'Failed to upload photo';

  @override
  String get myProfile_basicInfo => 'Basic Information';

  @override
  String get myProfile_birthDate => 'Date of Birth';

  @override
  String get myProfile_birthDateLabel => 'Date of Birth';

  @override
  String get myProfile_completionRate => 'Completion Rate';

  @override
  String get myProfile_experienceSkills => 'Experience & Skills';

  @override
  String get myProfile_experienceYearsHint => 'e.g. 5';

  @override
  String get myProfile_experienceYearsLabel => 'Years of Experience';

  @override
  String get myProfile_familyName => 'Family Name';

  @override
  String get myProfile_familyNameKana => 'Family Name (Kana)';

  @override
  String get myProfile_familyNameKanaLabel => 'Family Name (Kana)';

  @override
  String get myProfile_familyNameLabel => 'Family Name';

  @override
  String get myProfile_genderFemale => 'Female';

  @override
  String get myProfile_genderLabel => 'Gender';

  @override
  String get myProfile_genderMale => 'Male';

  @override
  String get myProfile_genderNotAnswered => 'Prefer not to say';

  @override
  String get myProfile_genderOther => 'Other';

  @override
  String get myProfile_genderRequired => 'Please select a gender';

  @override
  String get myProfile_givenName => 'Given Name';

  @override
  String get myProfile_givenNameKana => 'Given Name (Kana)';

  @override
  String get myProfile_givenNameKanaLabel => 'Given Name (Kana)';

  @override
  String get myProfile_givenNameLabel => 'Given Name';

  @override
  String get myProfile_identityVerified => 'Identity Verified';

  @override
  String get myProfile_introHint => 'Showcase your expertise and experience';

  @override
  String get myProfile_introLabel => 'Self Introduction';

  @override
  String get myProfile_loadError => 'Failed to load profile';

  @override
  String get myProfile_loginRequired => 'Login is required';

  @override
  String get myProfile_loginRequiredMessage =>
      'Login is required to edit your profile. Please log in from the Settings page.';

  @override
  String get myProfile_loginRequiredTitle => 'Login Required';

  @override
  String get myProfile_photoSetByVerification =>
      'Photo will be set after identity verification';

  @override
  String get myProfile_pickFromGallery => 'Choose from Gallery';

  @override
  String get myProfile_postalCodeHint => 'e.g. 123-4567';

  @override
  String get myProfile_postalCodeInvalid => 'Invalid postal code format';

  @override
  String get myProfile_postalCodeLabel => 'Postal Code';

  @override
  String get myProfile_profilePhoto => 'Profile Photo';

  @override
  String get myProfile_qualificationHint => 'Enter qualification name';

  @override
  String get myProfile_qualifications => 'Qualifications';

  @override
  String get myProfile_qualityScore => 'Quality Score';

  @override
  String get myProfile_ratingAverage => 'Rating Average';

  @override
  String myProfile_requiredField(String label) {
    return '$label is required';
  }

  @override
  String get myProfile_saveButton => 'Save';

  @override
  String get myProfile_saveError => 'Failed to save';

  @override
  String get myProfile_saveSuccess => 'Profile saved';

  @override
  String get myProfile_selectBirthDate => 'Select Date of Birth';

  @override
  String get myProfile_selectGender => 'Please select a gender';

  @override
  String get myProfile_stripeActive =>
      'Stripe connected — You can receive payments';

  @override
  String get myProfile_stripeIntegration => 'Stripe Integration';

  @override
  String get myProfile_stripeNotConfigured =>
      'Stripe not configured — Stripe integration is required to receive payments';

  @override
  String get myProfile_stripePending =>
      'Stripe under review — Please wait for verification to complete';

  @override
  String get myProfile_takePhoto => 'Take a Photo';

  @override
  String get myProfile_tapToChangePhoto => 'Tap to change photo';

  @override
  String get myProfile_title => 'Edit Profile';

  @override
  String get myProfile_verifiedQualifications => 'Verified Qualifications';

  @override
  String get myProfile_yearsSuffix => 'years';

  @override
  String get myProfile_yourRating => 'Your Rating';

  @override
  String get name => 'Full Name';

  @override
  String get nameChanged => 'Name changed';

  @override
  String get navHome => 'Home';

  @override
  String get navMessages => 'Messages';

  @override
  String get navMyPage => 'My Page';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSales => 'Earnings';

  @override
  String get navSearch => 'Search';

  @override
  String get navWork => 'Work';

  @override
  String get netAmount => 'Net Amount';

  @override
  String get networkCheckConnection => 'Please check your network connection';

  @override
  String get newPassword => 'New Password';

  @override
  String get next => 'Next';

  @override
  String get noData => 'No data available';

  @override
  String get noEarnings => 'No earnings data';

  @override
  String get noJobsFound => 'No jobs matching your criteria';

  @override
  String get noMessages => 'No messages';

  @override
  String get noMoreData => 'No more data';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get noWork => 'No current work assignments';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifications_allRead => 'All notifications read';

  @override
  String get notifications_empty => 'No notifications';

  @override
  String get notifications_emptyDescription =>
      'You will receive notifications about job updates here';

  @override
  String notifications_error(String error) {
    return 'Error: $error';
  }

  @override
  String get notifications_loginDescription => 'Login to receive notifications';

  @override
  String get notifications_loginRequired => 'Login required';

  @override
  String get notifications_markAllRead => 'Mark all as read';

  @override
  String get notifications_title => 'Notifications';

  @override
  String get offlineBanner_connectionRestored => 'Connection restored';

  @override
  String get offlineBanner_offlineMode => 'Offline mode';

  @override
  String get offlineBanner_retry => 'Retry';

  @override
  String get onboardingDesc1 => 'Easily search and apply for construction jobs';

  @override
  String get onboardingDesc2 =>
      'Simple attendance management with QR code scanning';

  @override
  String get onboardingDesc3 => 'Receive your earnings safely and reliably';

  @override
  String get onboardingTitle1 => 'Find Work';

  @override
  String get onboardingTitle2 => 'QR Check-in/out';

  @override
  String get onboardingTitle3 => 'Secure Payments';

  @override
  String get onboarding_agreed => ', agreed';

  @override
  String get onboarding_getStarted => 'Get Started';

  @override
  String get onboarding_nextPage => 'Next';

  @override
  String onboarding_pageIndicator(String current, String total) {
    return 'Page $current / $total';
  }

  @override
  String get onboarding_privacyPolicy => 'Privacy Policy';

  @override
  String get onboarding_skip => 'Skip';

  @override
  String get onboarding_termsOfService => 'Terms of Service';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get optional => 'Optional';

  @override
  String get password => 'Password';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get passwordResetDescription =>
      'We will send a reset link to your registered email';

  @override
  String get passwordResetSent => 'Password reset email sent';

  @override
  String get passwordResetTitle => 'Reset Password';

  @override
  String get paymentDetail => 'Payment Details';

  @override
  String get paymentDetail_createdAt => 'Created';

  @override
  String get paymentDetail_netAmount => 'Net amount';

  @override
  String get paymentDetail_notFound => 'Payment details not found';

  @override
  String get paymentDetail_paymentAmount => 'Payment amount';

  @override
  String get paymentDetail_paymentStatus => 'Payment status';

  @override
  String get paymentDetail_payoutStatus => 'Payout status';

  @override
  String get paymentDetail_platformFee => 'Platform fee';

  @override
  String get paymentDetail_projectName => 'Job name';

  @override
  String get paymentDetail_title => 'Payment Details';

  @override
  String get paymentFailed => 'Payment Failed';

  @override
  String get paymentPending => 'Payment Pending';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get paymentSucceeded => 'Payment Complete';

  @override
  String get payoutDate => 'Payout Date';

  @override
  String get phone => 'Phone Number';

  @override
  String get phoneAuth_changePhoneNumber => 'Change phone number';

  @override
  String phoneAuth_codeSentTo(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get phoneAuth_enterCode => 'Enter verification code';

  @override
  String get phoneAuth_enterJapaneseNumber =>
      'Please enter a Japanese phone number';

  @override
  String get phoneAuth_enterSixDigitCode => 'Enter the 6-digit code';

  @override
  String get phoneAuth_invalidPhoneNumber =>
      'Please enter a valid phone number (10-11 digits)';

  @override
  String get phoneAuth_login => 'Log in';

  @override
  String get phoneAuth_loginSuccess => 'Logged in successfully';

  @override
  String get phoneAuth_phoneNumberLabel => 'Phone number';

  @override
  String get phoneAuth_resendCode => 'Resend code';

  @override
  String phoneAuth_resendCountdown(String seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get phoneAuth_restartVerification =>
      'Please restart the verification process';

  @override
  String get phoneAuth_sendCode => 'Send verification code';

  @override
  String get phoneAuth_smsDescription =>
      'A verification code will be sent via SMS';

  @override
  String get phoneAuth_title => 'Log in with phone number';

  @override
  String get phoneAuth_verificationCodeLabel => 'Verification code';

  @override
  String get platformFee => 'Platform Fee';

  @override
  String get postJob => 'Post Job';

  @override
  String get postJobSuccess => 'Job posted';

  @override
  String get postJobTitle => 'Post a Job';

  @override
  String get post_dateHint => 'Tap to select date';

  @override
  String get post_dateLabel => 'Schedule';

  @override
  String get post_datePickerCancel => 'Cancel';

  @override
  String get post_datePickerConfirm => 'Confirm';

  @override
  String get post_datePickerHelp => 'Select a date';

  @override
  String get post_hintBody =>
      'Select dates from the calendar. Setting latitude/longitude enables GPS verification for QR attendance.';

  @override
  String get post_hintTitle => 'Hint';

  @override
  String get post_latitudeHint => 'e.g. 35.6812';

  @override
  String get post_latitudeLabel => 'Latitude (optional)';

  @override
  String get post_locationHint => 'e.g. Hanamigawa-ku, Chiba City, Chiba';

  @override
  String get post_locationLabel => 'Location';

  @override
  String get post_longitudeHint => 'e.g. 139.7671';

  @override
  String get post_longitudeLabel => 'Longitude (optional)';

  @override
  String get post_noPermissionMessage =>
      'This screen is for administrators only.';

  @override
  String get post_noPermissionTitle => 'No permission';

  @override
  String get post_priceHint => 'e.g. 30000';

  @override
  String get post_priceLabel => 'Payment (JPY)';

  @override
  String get post_sectionBasicInfo => 'Basic Information';

  @override
  String get post_sectionBasicInfoSubtitle => 'Please enter the job details';

  @override
  String get post_snackAdminOnly => 'Only administrators can post jobs';

  @override
  String get post_snackCheckingPermission =>
      'Checking permissions. Please wait.';

  @override
  String get post_snackEmptyFields => 'Some fields are empty';

  @override
  String get post_snackLoginRequired => 'Login required';

  @override
  String post_snackPostFailed(String error) {
    return 'Post failed: $error';
  }

  @override
  String get post_snackPriceNumeric => 'Please enter a numeric amount';

  @override
  String get post_snackSelectDateFromCalendar =>
      'Please select a date from the calendar';

  @override
  String get post_submitButton => 'Post job';

  @override
  String get post_title => 'Post a Job';

  @override
  String get post_titleHint => 'e.g. Wallpaper replacement (1LDK)';

  @override
  String get post_titleLabel => 'Title';

  @override
  String get postalCode => 'Postal Code';

  @override
  String get prefecture => 'Prefecture';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get profilePhotoChange => 'Change Photo';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileTitle => 'My Page';

  @override
  String get profileWidgets_guest => 'Guest';

  @override
  String get profileWidgets_loggedIn => 'Logged in';

  @override
  String get profileWidgets_status => 'Status';

  @override
  String get profile_accountSettings => 'Account settings';

  @override
  String get profile_adminLogin => 'Admin login';

  @override
  String get profile_adminLoginSubtitle => 'Post and edit jobs';

  @override
  String get profile_adminLogout => 'Admin logout';

  @override
  String get profile_adminLogoutSubtitle => 'Not currently logged in';

  @override
  String get profile_contact => 'Contact us';

  @override
  String get profile_darkMode => 'Dark mode';

  @override
  String get profile_darkModeDescription =>
      'Dark mode follows your device\'s system settings.\n\nYou can change this in your device\'s Settings > Display > Dark Mode.';

  @override
  String get profile_darkModeSubtitle => 'Follows system settings';

  @override
  String get profile_darkModeLight => 'Light';

  @override
  String get profile_darkModeDark => 'Dark';

  @override
  String get profile_darkModeSystem => 'Follow system settings';

  @override
  String get profile_faq => 'FAQ';

  @override
  String get profile_favoriteJobs => 'Favorite jobs';

  @override
  String get profile_favoriteJobsSubtitle => 'View saved jobs';

  @override
  String get profile_guest => 'Guest';

  @override
  String get profile_identityVerification => 'Identity verification';

  @override
  String get profile_identityVerificationSubtitle => 'Submit ID and selfie';

  @override
  String get profile_inviteFriends => 'Invite friends';

  @override
  String get profile_inviteFriendsSubtitle =>
      'Invite friends with referral code';

  @override
  String get profile_legalInfo => 'Legal information';

  @override
  String get profile_legalInfoSubtitle => 'Privacy policy, terms of service';

  @override
  String get profile_lineLoginButton => 'Log in with LINE';

  @override
  String get profile_lineLoginSemanticsLabel => 'Log in with LINE account';

  @override
  String get profile_loggedIn => 'Log in to apply and chat';

  @override
  String get profile_loggedInUser => 'Logged in user';

  @override
  String get profile_loginButton => 'Log in';

  @override
  String get profile_loginPromptSubtitle => 'Log in to apply and chat';

  @override
  String get profile_loginRequired => 'Login required';

  @override
  String get profile_loginRequiredMessage =>
      'Login is required for some features like applying and chatting.';

  @override
  String get profile_notLoggedIn => 'Not currently logged in';

  @override
  String get profile_qualifications => 'Qualifications';

  @override
  String get profile_qualificationsSubtitle =>
      'Register and manage qualifications';

  @override
  String get profile_sectionAccount => 'Account';

  @override
  String get profile_sectionAdmin => 'Admin';

  @override
  String get profile_sectionOther => 'Other';

  @override
  String get profile_sectionSupport => 'Support';

  @override
  String get profile_snackLoggedOut => 'Logged out (returned to guest mode)';

  @override
  String get profile_stripeAccount => 'Stripe account settings';

  @override
  String get profile_stripeAccountSubtitle => 'Set up payment account';

  @override
  String get profile_yourProfile => 'Your profile';

  @override
  String get projectName => 'Project Name';

  @override
  String get qrCheckIn => 'QR Check-in';

  @override
  String get qrCheckin_clockIn => 'Clock in';

  @override
  String get qrCheckin_clockOut => 'Clock out';

  @override
  String get qrCheckin_error => 'Error';

  @override
  String qrCheckin_errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String qrCheckin_gpsVerification(String action) {
    return 'GPS verification: $action available within 100m of the site';
  }

  @override
  String get qrCheckin_scanAdminQr => 'Scan admin QR code';

  @override
  String qrCheckin_title(String action) {
    return 'QR Scan ($action)';
  }

  @override
  String get qualificationAdd_categoryLabel => 'Category';

  @override
  String get qualificationAdd_expiryDate => 'Expiry date';

  @override
  String get qualificationAdd_nameHint => 'Enter qualification name';

  @override
  String get qualificationAdd_nameLabel => 'Qualification name';

  @override
  String get qualificationAdd_nameRequired => 'Qualification name is required';

  @override
  String get qualificationAdd_noExpiry => 'No expiry';

  @override
  String get qualificationAdd_register => 'Register';

  @override
  String qualificationAdd_registerFailed(String error) {
    return 'Registration failed: $error';
  }

  @override
  String get qualificationAdd_registered => 'Qualification registered';

  @override
  String get qualificationAdd_title => 'Add Qualification';

  @override
  String get qualifications => 'Qualifications';

  @override
  String get qualifications_addHint => 'Add your qualifications';

  @override
  String get qualifications_approved => 'Approved';

  @override
  String get qualifications_empty => 'No qualifications registered';

  @override
  String qualifications_error(String error) {
    return 'Error: $error';
  }

  @override
  String get qualifications_expired => '(expired)';

  @override
  String qualifications_expiryDate(String date, String status) {
    return 'Expiry: $date$status';
  }

  @override
  String get qualifications_loginRequired =>
      'Login required to manage qualifications';

  @override
  String get qualifications_pending => 'Pending';

  @override
  String get qualifications_rejected => 'Rejected';

  @override
  String get qualifications_title => 'Qualifications';

  @override
  String get ratingDialog_average => 'Average';

  @override
  String get ratingDialog_commentHint => 'Enter your comment (optional)';

  @override
  String get ratingDialog_dissatisfied => 'Dissatisfied';

  @override
  String get ratingDialog_excellent => 'Excellent';

  @override
  String get ratingDialog_good => 'Good';

  @override
  String get ratingDialog_later => 'Later';

  @override
  String get ratingDialog_selectStars => 'Please select a rating';

  @override
  String get ratingDialog_somewhatDissatisfied => 'Somewhat dissatisfied';

  @override
  String get ratingDialog_submit => 'Submit';

  @override
  String ratingDialog_submitFailed(String error) {
    return 'Failed to submit: $error';
  }

  @override
  String get ratingDialog_submitSuccess => 'Rating submitted';

  @override
  String get ratingDialog_title => 'Rate this job';

  @override
  String get ratingLabel => 'Rating';

  @override
  String ratingStars_count(String count) {
    return '($count reviews)';
  }

  @override
  String get ratingStars_noRating => 'No rating';

  @override
  String get receiveNotifications => 'Receive notifications';

  @override
  String get referral_applyButton => 'Apply';

  @override
  String get referral_codeApplied => 'Referral code applied';

  @override
  String get referral_codeCopied => 'Code copied';

  @override
  String get referral_codeHint => 'e.g. ABC123';

  @override
  String get referral_copy => 'Copy';

  @override
  String get referral_enterCode => 'Enter referral code';

  @override
  String get referral_enterCodeDescription =>
      'Enter the referral code from your friend';

  @override
  String get referral_inviteDescription => 'Invite friends and earn rewards';

  @override
  String get referral_loginRequired => 'Login required';

  @override
  String get referral_share => 'Share with friends';

  @override
  String get referral_stats => 'Referral Stats';

  @override
  String referral_statsCount(String count) {
    return '$count people';
  }

  @override
  String get referral_title => 'Invite Friends';

  @override
  String get referral_yourCode => 'Your referral code';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get register => 'Sign Up';

  @override
  String get registerSuccess => 'Account created successfully';

  @override
  String get registrationPrompt_defaultFeature => 'this feature';

  @override
  String get registrationPrompt_description => 'Register to use all features';

  @override
  String get registrationPrompt_emailLogin => 'Log in with email';

  @override
  String registrationPrompt_error(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get registrationPrompt_later => 'Later';

  @override
  String get registrationPrompt_lineLogin => 'Log in with LINE';

  @override
  String get registrationPrompt_lineRedirect => 'Redirecting to LINE login...';

  @override
  String registrationPrompt_title(String feature) {
    return '$feature requires registration';
  }

  @override
  String get required => 'Required';

  @override
  String get retry => 'Retry';

  @override
  String get router_goHome => 'Go to Home';

  @override
  String router_pageDoesNotExist(String uri) {
    return '$uri does not exist';
  }

  @override
  String get router_pageNotFound => 'Page Not Found';

  @override
  String get router_statementsTitle => 'Statements';

  @override
  String get router_workTimelineTitle => 'Work Timeline';

  @override
  String get salesTitle => 'Earnings';

  @override
  String get sales_checkSales => 'Check Sales';

  @override
  String get sales_constructionCompleted => 'Construction Completed';

  @override
  String sales_dataCount(String count) {
    return 'Data count: $count items';
  }

  @override
  String get sales_earningsNote =>
      '* Earnings will be reflected when confirmed by an administrator';

  @override
  String get sales_incomeAndStatements => 'Income & Statements';

  @override
  String get sales_incomeNote => '* Only confirmed earnings are shown';

  @override
  String sales_monthLabel(String month) {
    return 'Month $month';
  }

  @override
  String sales_monthStatement(String month) {
    return '$month Statement';
  }

  @override
  String get sales_monthlyTrend => 'Monthly Trend';

  @override
  String sales_nextPaymentDate(String month) {
    return 'Next Payment: $month/10';
  }

  @override
  String get sales_noPaymentData => 'No payment data';

  @override
  String get sales_noStatements => 'No statements';

  @override
  String get sales_noStatementsDescription =>
      'Monthly statements will appear here when generated.';

  @override
  String get sales_paid => 'Paid';

  @override
  String get sales_paymentHistory => 'Payment History';

  @override
  String get sales_paymentManagement => 'Payment Management';

  @override
  String get sales_registerPayment => 'Register Payment';

  @override
  String get sales_registerToStart => 'Register to Start';

  @override
  String get sales_registrationDescription =>
      'Registration is required to view sales information.';

  @override
  String get sales_registrationRequired => 'Registration Required';

  @override
  String get sales_resetToThisMonth => 'Reset to this month';

  @override
  String get sales_salesTitle => 'Sales';

  @override
  String get sales_selectedMonthIncome => 'Selected Month Income';

  @override
  String get sales_statusDraft => 'In Progress';

  @override
  String get sales_statusPaid => 'Paid';

  @override
  String get sales_tabIncome => 'Income';

  @override
  String get sales_tabStatements => 'Statements';

  @override
  String get sales_thisMonthIncome => 'This Month\'s Income';

  @override
  String get sales_total => 'Total';

  @override
  String get sales_totalIncome => 'Total Income';

  @override
  String get sales_unconfirmedEarnings => 'Unconfirmed Earnings';

  @override
  String get sales_unpaid => 'Unpaid';

  @override
  String get save => 'Save';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get search => 'Search';

  @override
  String get searchJobs => 'Search jobs';

  @override
  String get send => 'Send';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get shareJob => 'Share Job';

  @override
  String get shiftQr => 'Shift QR';

  @override
  String shiftQr_generateFailed(String error) {
    return 'Failed to generate: $error';
  }

  @override
  String get shiftQr_generateNew => 'Generate new QR';

  @override
  String get shiftQr_generated => 'QR code generated';

  @override
  String get shiftQr_generating => 'Generating...';

  @override
  String get shiftQr_noQrCodes => 'No QR codes';

  @override
  String get shiftQr_scanInstruction => 'Have workers scan this code';

  @override
  String get shiftQr_title => 'Shift QR Code';

  @override
  String get showPassword => 'Show password';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signInWithEmail => 'Sign in with Email';

  @override
  String get signInWithLine => 'Sign in with LINE';

  @override
  String get skip => 'Skip';

  @override
  String get sortByNewest => 'Newest first';

  @override
  String get sortByPriceHigh => 'Highest pay first';

  @override
  String get startAsGuest => 'Continue as Guest';

  @override
  String get startOnboarding => 'Start Setup';

  @override
  String get statementDetail_applyButton => 'Apply for early payment';

  @override
  String statementDetail_completedDate(String date) {
    return 'Completed: $date';
  }

  @override
  String get statementDetail_earlyPaymentButton => 'Early payment';

  @override
  String statementDetail_earlyPaymentConfirm(
    String totalAmount,
    String fee,
    String payout,
  ) {
    return 'Apply for early payment? A 10% fee will be deducted. (Amount: ¥$totalAmount, Fee: ¥$fee, Payout: ¥$payout)';
  }

  @override
  String get statementDetail_earlyPaymentError =>
      'Early payment request failed';

  @override
  String get statementDetail_earlyPaymentPending => 'Early payment pending';

  @override
  String get statementDetail_earlyPaymentSuccess =>
      'Early payment request submitted';

  @override
  String get statementDetail_earlyPaymentTitle => 'Early Payment';

  @override
  String statementDetail_error(String error) {
    return 'Error: $error';
  }

  @override
  String get statementDetail_jobDetails => 'Job Details';

  @override
  String statementDetail_monthLabel(String month) {
    return '$month';
  }

  @override
  String get statementDetail_title => 'Statement Details';

  @override
  String get statusApplied => 'Applied';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusBadge_applied => 'Applied';

  @override
  String get statusBadge_assigned => 'Assigned';

  @override
  String get statusBadge_completed => 'Completed';

  @override
  String get statusBadge_done => 'Done';

  @override
  String get statusBadge_fixing => 'Fixing';

  @override
  String get statusBadge_inProgress => 'In Progress';

  @override
  String get statusBadge_inspection => 'Inspection';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusPending => 'Under Review';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get stripeOnboarding => 'Bank Account Setup';

  @override
  String get stripeOnboardingDescription =>
      'Set up your bank account to receive payments';

  @override
  String get stripeOnboarding_initFailed => 'Failed to initialize Stripe';

  @override
  String get stripeOnboarding_retry => 'Retry';

  @override
  String get stripeOnboarding_title => 'Stripe Setup';

  @override
  String get stripeOnboarding_urlFetchFailed => 'Failed to get setup URL';

  @override
  String get tabSelected => 'Selected';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get timeline_empty => 'No activity yet';

  @override
  String timeline_error(String error) {
    return 'Error: $error';
  }

  @override
  String get today => 'Today';

  @override
  String get tooManyRequests => 'Too many requests. Please try again later';

  @override
  String get totalEarnings => 'Total Earnings';

  @override
  String get typeMessage => 'Type a message';

  @override
  String unreadCount(String count) {
    return '$count unread';
  }

  @override
  String get update => 'Update';

  @override
  String get userDisabled => 'This account has been disabled';

  @override
  String get userNotFound => 'Account not found';

  @override
  String get weakPassword =>
      'Password is too weak. Please use at least 6 characters';

  @override
  String get workDetail => 'Work Details';

  @override
  String get workDetail_chat => 'Chat';

  @override
  String get workDetail_checkedIn => 'Clocked In';

  @override
  String get workDetail_checkedOut => 'Clocked Out';

  @override
  String get workDetail_completeButton => 'Complete';

  @override
  String get workDetail_jobName => 'Job Name';

  @override
  String get workDetail_jobNotFound => 'Job not found';

  @override
  String get workDetail_location => 'Location';

  @override
  String get workDetail_loginRequired => 'Login is required';

  @override
  String get workDetail_noJobIdWarning =>
      '* Cannot display original job information because jobId is not set.';

  @override
  String get workDetail_noPermission =>
      'You do not have permission to view this job';

  @override
  String get workDetail_notCheckedIn => 'Not Clocked In';

  @override
  String get workDetail_payment => 'Payment';

  @override
  String get workDetail_paymentUnconfirmed => 'Unconfirmed';

  @override
  String get workDetail_qrAttendance => 'QR Attendance';

  @override
  String get workDetail_qrClockIn => 'QR Clock In';

  @override
  String get workDetail_qrClockOut => 'QR Clock Out';

  @override
  String get workDetail_rateButton => 'Rate';

  @override
  String get workDetail_rated => 'Rated';

  @override
  String get workDetail_reinspect => 'Re-inspect';

  @override
  String get workDetail_reportRequired =>
      'Please submit at least one daily report to complete';

  @override
  String get workDetail_schedule => 'Schedule';

  @override
  String get workDetail_snackCompleteError => 'Failed to complete';

  @override
  String get workDetail_snackCompleted => 'Work completed';

  @override
  String get workDetail_snackStartError => 'Failed to start work';

  @override
  String get workDetail_snackStarted => 'Work started';

  @override
  String get workDetail_startButton => 'Start Work';

  @override
  String get workDetail_startInspection => 'Inspect';

  @override
  String workDetail_statusCompleted(String title) {
    return '$title is now \"Completed\"';
  }

  @override
  String workDetail_statusInProgress(String title) {
    return '$title is now \"In Progress\"';
  }

  @override
  String get workDetail_statusUpdate => 'Status Update';

  @override
  String get workDetail_tabDailyReport => 'Daily Report';

  @override
  String get workDetail_tabDocuments => 'Documents';

  @override
  String get workDetail_tabOverview => 'Overview';

  @override
  String get workDetail_tabPhotos => 'Photos';

  @override
  String get workDetail_timeline => 'Timeline';

  @override
  String get workDocs_add => 'Add';

  @override
  String workDocs_noDocuments(String folder) {
    return 'No documents in \"$folder\" yet';
  }

  @override
  String get workDocs_title => 'Documents';

  @override
  String workDocs_uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String workDocs_uploadSuccess(String folder) {
    return 'Uploaded to $folder';
  }

  @override
  String get workPhotos_add => 'Add';

  @override
  String get workPhotos_cancel => 'Cancel';

  @override
  String get workPhotos_delete => 'Delete';

  @override
  String get workPhotos_deleteConfirm => 'Delete this photo?';

  @override
  String get workPhotos_deleteSuccess => 'Photo deleted';

  @override
  String get workPhotos_deleteTitle => 'Delete photo';

  @override
  String get workPhotos_noPhotos => 'No photos yet';

  @override
  String get workPhotos_title => 'Site Photos';

  @override
  String workPhotos_uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get workPhotos_uploadHint => 'Upload photos using the Add button';

  @override
  String workPhotos_uploadSuccess(String count) {
    return 'Uploaded $count photos';
  }

  @override
  String get workReportCreate_contentHint => 'Describe the work done in detail';

  @override
  String get workReportCreate_contentLabel => 'Work description';

  @override
  String get workReportCreate_contentRequired =>
      'Please enter work description';

  @override
  String get workReportCreate_date => 'Date';

  @override
  String get workReportCreate_hoursLabel => 'Hours worked';

  @override
  String get workReportCreate_hoursSuffix => 'hours';

  @override
  String get workReportCreate_hoursValidation => 'Please enter hours worked';

  @override
  String workReportCreate_logSubmitted(String title) {
    return 'Daily report: $title submitted';
  }

  @override
  String get workReportCreate_notesHint => 'Enter any special notes';

  @override
  String get workReportCreate_notesLabel => 'Notes';

  @override
  String workReportCreate_saveFailed(String error) {
    return 'Failed to save report: $error';
  }

  @override
  String get workReportCreate_submit => 'Submit';

  @override
  String get workReportCreate_submitted => 'Report submitted';

  @override
  String get workReportCreate_title => 'Create Daily Report';

  @override
  String get workReports_addHint => 'Create reports using the Add button';

  @override
  String get workReports_empty => 'No reports yet';

  @override
  String workReports_error(String error) {
    return 'Error: $error';
  }

  @override
  String get workStatus => 'Work Status';

  @override
  String get workTitle => 'My Work';

  @override
  String get work_chatTooltip => 'Chat';

  @override
  String get work_emptyApplications => 'No applications';

  @override
  String get work_emptyAssigned => 'No assigned jobs';

  @override
  String get work_emptyCompleted => 'No completed jobs';

  @override
  String get work_emptyDefault => 'No matching jobs';

  @override
  String get work_emptyDone => 'No finished jobs';

  @override
  String get work_emptyFixing => 'No jobs under correction';

  @override
  String get work_emptyInProgress => 'No jobs in progress';

  @override
  String get work_emptyInspection => 'No jobs under inspection';

  @override
  String get work_featureName => 'Work Management';

  @override
  String get work_groupApplied => 'Applied';

  @override
  String get work_groupApproved => 'Approved / In Progress';

  @override
  String get work_groupCompleted => 'Completed / Inspection';

  @override
  String get work_noJobs => 'None';

  @override
  String get work_registrationRequiredDescription =>
      'Register to apply for and manage your jobs.';

  @override
  String get work_registrationRequiredTitle =>
      'Registration required to use work management';

  @override
  String get work_tabApplications => 'Applications';

  @override
  String get work_tabAssigned => 'Assigned';

  @override
  String get work_tabCompleted => 'Work Completed';

  @override
  String get work_tabDone => 'Done';

  @override
  String get work_tabFixing => 'Under Correction';

  @override
  String get work_tabInProgress => 'In Progress';

  @override
  String get work_tabInspection => 'Under Inspection';

  @override
  String get workerLabel => 'Worker';

  @override
  String get wrongPassword => 'Incorrect password';

  @override
  String get yen => 'JPY';

  @override
  String get yesterday => 'Yesterday';

  @override
  String jobList_monthNumLabel(String month) {
    return 'Month $month';
  }

  @override
  String jobList_resultCount(String count) {
    return '$count results';
  }

  @override
  String get messages_filterAll => 'All';

  @override
  String get messages_filterUnread => 'Unread';

  @override
  String get messages_noUnread => 'No unread messages';

  @override
  String get profile_totalJobs => 'Completed';

  @override
  String get profile_rating => 'Rating';

  @override
  String get profile_qualityScore => 'Score';

  @override
  String get profile_logout => 'Log out';

  @override
  String home_unreadMessages(String count) {
    return '$count unread';
  }

  @override
  String work_unreadChat(String count) {
    return '$count unread';
  }

  @override
  String get post_sectionImages => 'Images';

  @override
  String get post_sectionImagesSubtitle => 'Add job photos (up to 5)';

  @override
  String post_addImages(String current, String max) {
    return 'Add images ($current/$max)';
  }

  @override
  String get adminApproval_noName => 'No name set';

  @override
  String get adminApproval_approve => 'Approve';

  @override
  String get adminApproval_reject => 'Reject';

  @override
  String get adminApproval_rejectReasonTitle => 'Rejection reason';

  @override
  String get adminApproval_rejectReasonHint =>
      'Please enter the reason for rejection';

  @override
  String get adminApproval_rejectButton => 'Reject';

  @override
  String get adminKpi_noData => 'No data';

  @override
  String get adminNav_jobs => 'Jobs';

  @override
  String get adminNav_approvals => 'Approvals';

  @override
  String get adminNav_workers => 'Workers';

  @override
  String get adminNav_settings => 'Settings';

  @override
  String get adminNav_jobManagement => 'Job Management';

  @override
  String get adminNav_applicants => 'Applicants';

  @override
  String get adminApproval_qualifications => 'Qualifications';

  @override
  String get adminApproval_earlyPayments => 'Early Payment';

  @override
  String get adminApproval_verification => 'Verification';

  @override
  String get adminApproval_emptyTitle => 'No pending approvals';

  @override
  String get adminApproval_emptyDescription =>
      'All approvals have been processed';

  @override
  String get adminApproval_pendingReview => 'Pending Review';

  @override
  String get adminKpi_dailyTrend => 'Application Trend (Last 7 Days)';

  @override
  String get adminKpi_monthlyKpi => 'Monthly KPI';

  @override
  String get adminKpi_mau => 'MAU';

  @override
  String get adminKpi_monthlyEarnings => 'Monthly Earnings';

  @override
  String get adminKpi_jobFillRate => 'Job Fill Rate';

  @override
  String get adminWorkers_activeList => 'Active Workers';

  @override
  String get adminWorkers_reports => 'Reports';

  @override
  String get adminWorkers_inspections => 'Inspections';

  @override
  String get adminWorkers_searchHint => 'Search by worker name';

  @override
  String get adminWorkers_emptyTitle => 'No active workers';

  @override
  String get adminWorkers_emptyDescription => 'No workers currently active';

  @override
  String adminWorkers_inProgressCount(String count) {
    return 'Active $count';
  }

  @override
  String adminWorkers_assignedCount(String count) {
    return 'Assigned $count';
  }

  @override
  String get adminWorkers_jobUnit => ' jobs';

  @override
  String get adminWorkReports_emptyTitle => 'No work reports yet';

  @override
  String get adminWorkReports_emptyDescription =>
      'Work reports will appear here when submitted';

  @override
  String adminWorkReports_hours(String hours) {
    return '$hours hours';
  }

  @override
  String get adminInspections_filterAll => 'All';

  @override
  String get adminInspections_filterPassed => 'Passed';

  @override
  String get adminInspections_filterFailed => 'Failed';

  @override
  String get adminInspections_filterPartial => 'Partial';

  @override
  String get adminInspections_emptyTitle => 'No inspections';

  @override
  String get adminInspections_emptyDescription =>
      'Inspections will appear here';

  @override
  String get adminInspections_passed => 'Passed';

  @override
  String get adminInspections_failed => 'Failed';

  @override
  String get adminInspections_partial => 'Partial';

  @override
  String adminInspections_checkSummary(String total, String passed) {
    return '$passed of $total items passed';
  }

  @override
  String get adminSettings_admin => 'Administrator';

  @override
  String get adminSettings_notifications => 'Notifications';

  @override
  String get adminSettings_appVersion => 'App Version';

  @override
  String get adminSettings_legal => 'Legal';

  @override
  String get adminSettings_logout => 'Logout';

  @override
  String get adminSettings_logoutTitle => 'Logout';

  @override
  String get adminSettings_logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get adminDashboard_workReports => 'Reports';

  @override
  String adminApplicants_qualCount(String count) {
    return '$count quals';
  }

  @override
  String adminApplicants_completedCount(String count) {
    return '$count done';
  }

  @override
  String get adminApplicants_openChat => 'Open Chat';

  @override
  String get adminSettings_accountSettings => 'Account Settings';

  @override
  String get adminSettings_language => 'Language';

  @override
  String get adminSettings_dataExport => 'Data Export';

  @override
  String get adminWorker_statistics => 'Statistics';

  @override
  String get adminWorker_statCompleted => 'Completed';

  @override
  String get adminWorker_statTotalEarnings => 'Total Earnings';

  @override
  String get adminWorker_statCompletionRate => 'Completion Rate';

  @override
  String get adminWorker_memoTitle => 'Admin Notes';

  @override
  String get adminWorker_memoHint => 'Enter notes about this worker...';

  @override
  String get adminWorker_memoSave => 'Save Notes';

  @override
  String get adminWorker_memoSaved => 'Notes saved';

  @override
  String get adminWorker_memoSaveFailed => 'Failed to save notes';

  @override
  String get adminWorker_openChat => 'Open Chat';

  @override
  String get adminWorker_noChatAvailable =>
      'No applications available for chat';

  @override
  String get adminWorker_ekycApproved => 'Verified';

  @override
  String get adminWorker_ekycPending => 'Pending';

  @override
  String get adminWorker_ekycRejected => 'Rejected';

  @override
  String get post_saveDraft => 'Draft';

  @override
  String get post_draftSaved => 'Draft saved';

  @override
  String get post_draftSaveFailed => 'Failed to save draft';

  @override
  String get post_draftNeedTitle => 'Please enter a title';

  @override
  String get adminWorkReports_filterAll => 'All';

  @override
  String get adminWorkReports_filterPending => 'Pending';

  @override
  String get adminWorkReports_filterReviewed => 'Reviewed';

  @override
  String get adminWorkReports_reviewPending => 'Pending';

  @override
  String get adminWorkReports_reviewed => 'Reviewed';

  @override
  String get adminWorkReports_addFeedback => 'Add Comment';

  @override
  String get adminWorkReports_markReviewed => 'Mark Reviewed';

  @override
  String get adminWorkReports_feedbackTitle => 'Report Feedback';

  @override
  String get adminWorkReports_feedbackHint => 'Enter comment...';

  @override
  String get adminWorkReports_feedbackSubmit => 'Submit';

  @override
  String get adminWorkReports_feedbackCancel => 'Cancel';

  @override
  String get adminWorkReports_feedbackSent => 'Feedback sent';

  @override
  String get adminWorkReports_feedbackFailed => 'Failed to send feedback';

  @override
  String get adminWorkReports_markedReviewed => 'Marked as reviewed';

  @override
  String get adminWorkReports_markFailed => 'Failed to update review status';

  @override
  String get inspection_customItems => 'Custom Inspection Items';

  @override
  String get inspection_customItemsHint => 'Enter item name';

  @override
  String get inspection_addItem => 'Add Item';

  @override
  String get inspection_removeItem => 'Remove Item';

  @override
  String get inspection_defaultItems => 'Use Default Items';

  @override
  String get inspection_customItemsHelp =>
      'Set custom inspection items per job';

  @override
  String get inspection_itemPhotoAttach => 'Attach Photo';

  @override
  String inspection_itemPhotoCount(String count) {
    return '$count photos';
  }

  @override
  String get adminDrafts_title => 'Drafts';

  @override
  String get adminDrafts_empty => 'No drafts';

  @override
  String get adminDrafts_publish => 'Publish';

  @override
  String get adminDrafts_delete => 'Delete';

  @override
  String get adminDrafts_deleteConfirm => 'Delete this draft?';

  @override
  String get adminDrafts_published => 'Job published';

  @override
  String get adminDrafts_publishFailed => 'Failed to publish';

  @override
  String get adminDrafts_deleted => 'Draft deleted';

  @override
  String get adminDrafts_deleteFailed => 'Failed to delete';

  @override
  String get adminKpi_avgJobPrice => 'Avg Job Price';

  @override
  String get adminKpi_workerAnalysis => 'Worker Analysis';

  @override
  String get adminKpi_activeWorkerRate => 'Active Rate';

  @override
  String get adminKpi_repeatWorkerRate => 'Repeat Rate';

  @override
  String get adminKpi_regionDistribution => 'Regional Distribution';

  @override
  String get notifications_filterAll => 'All';

  @override
  String get notifications_filterApplications => 'Applications';

  @override
  String get notifications_filterReports => 'Reports';

  @override
  String get notifications_filterInspections => 'Inspections';

  @override
  String get guestHome_googleLogin => 'Sign in with Google';

  @override
  String get guestHome_googleLoginSuccess => 'Signed in with Google';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get profile_bankAccount => 'Bank Account';

  @override
  String get profile_bankAccountSubtitle => 'Set up your payment account';

  @override
  String get myProfile_bankAccountStatus => 'Bank Account';

  @override
  String get myProfile_bankNotConfigured =>
      'No bank account — Set up your account to receive payments';

  @override
  String myProfile_bankConfigured(String bankName, String maskedNum) {
    return '$bankName Account: $maskedNum';
  }

  @override
  String get bankAccount_title => 'Bank Account Settings';

  @override
  String get bankAccount_bankName => 'Bank Name';

  @override
  String get bankAccount_bankNameHint => 'e.g. Mizuho Bank';

  @override
  String get bankAccount_branchName => 'Branch Name';

  @override
  String get bankAccount_branchCode => 'Branch Code (3 digits)';

  @override
  String get bankAccount_branchCodeInvalid =>
      'Please enter a 3-digit branch code';

  @override
  String get bankAccount_accountType => 'Account Type';

  @override
  String get bankAccount_accountTypeOrdinary => 'Savings';

  @override
  String get bankAccount_accountTypeCurrent => 'Checking';

  @override
  String get bankAccount_accountNumber => 'Account Number (7 digits)';

  @override
  String get bankAccount_accountNumberInvalid =>
      'Please enter a 7-digit account number';

  @override
  String get bankAccount_accountHolderName => 'Account Holder Name (Katakana)';

  @override
  String get bankAccount_accountHolderHint => 'e.g. Yamada Taro';

  @override
  String get bankAccount_accountHolderInvalid =>
      'Please enter the name in Katakana';

  @override
  String get bankAccount_save => 'Save';

  @override
  String get bankAccount_saved => 'Bank account information saved';

  @override
  String get bankAccount_saveFailed =>
      'Failed to save bank account information';

  @override
  String get bankAccount_required => 'This field is required';

  @override
  String get guestHome_lineLoginLoading => 'Signing in with LINE...';

  @override
  String get guestHome_lineLoginFailed => 'LINE sign in failed';

  @override
  String get guestHome_lineLoginSuccess => 'Signed in with LINE';

  @override
  String get accountLinking_title => 'Account Linking';

  @override
  String get accountLinking_linked => 'Linked';

  @override
  String get accountLinking_linkGoogle => 'Link Google';

  @override
  String get accountLinking_linkApple => 'Link Apple';

  @override
  String get accountLinking_linkLine => 'Link LINE';

  @override
  String get accountLinking_unlink => 'Unlink';

  @override
  String get accountLinking_unlinkConfirm =>
      'Are you sure you want to unlink this account?';

  @override
  String get accountLinking_cannotUnlinkLast =>
      'You must keep at least one login method';

  @override
  String get accountLinking_alreadyInUse =>
      'This account is already linked to another user';

  @override
  String get accountMerge_title => 'Merge Accounts';

  @override
  String accountMerge_description(String email) {
    return 'Another account is linked to $email. Would you like to merge?';
  }

  @override
  String get accountMerge_warning =>
      'This action cannot be undone. The merged account will be deleted.';

  @override
  String get accountMerge_confirm => 'Merge';

  @override
  String get accountMerge_success => 'Accounts merged successfully';

  @override
  String get accountMerge_failed => 'Account merge failed';

  @override
  String get accountMerge_rateLimited => 'Merge is limited to once per hour';

  @override
  String get accountLinking_linkEmail => 'Link Email';

  @override
  String get accountLinking_linkPhone => 'Link Phone';

  @override
  String get phoneLinking_title => 'Link Phone Number';

  @override
  String get phoneLinking_success => 'Phone number linked';
}
