import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/analytics_service.dart';
import 'page_transitions.dart';
import 'route_paths.dart';

// --- ページインポート ---
import '../../main.dart' show AuthGate, navigatorKey;
import '../../pages/admin_home_page.dart';
import '../../pages/onboarding_page.dart';
import '../../presentation/pages/guest/guest_home_page.dart';
import '../../pages/email_auth_page.dart';
import '../../pages/admin_login_page.dart';
import '../../pages/job_detail_page.dart';
import '../../pages/job_edit_page.dart';
import '../../pages/post_page.dart';
import '../../pages/work_detail_page.dart';
import '../../pages/chat_room_page.dart';
import '../../pages/qr_checkin_page.dart';
import '../../pages/shift_qr_page.dart';
import '../../pages/earnings_create_page.dart';
import '../../pages/payment_detail_page.dart';
import '../../pages/my_profile_page.dart';
import '../../pages/account_settings_page.dart';
import '../../pages/identity_verification_page.dart';
import '../../pages/stripe_onboarding_page.dart';
import '../../pages/notifications_page.dart';
import '../../pages/contact_page.dart';
import '../../pages/faq_page.dart';
import '../../pages/legal_page.dart';
import '../../pages/legal_index_page.dart';
import '../../pages/map_search_page.dart';
import '../../pages/work_detail/work_report_create_page.dart';
import '../../pages/work_detail/inspection_page.dart';
import '../../pages/work_detail/timeline_tab.dart';
import '../../pages/qualifications_page.dart';
import '../../pages/qualification_add_page.dart';
import '../../pages/statement_detail_page.dart';
import '../../pages/favorites_page.dart';
import '../../pages/phone_auth_page.dart';
import '../../pages/admin/admin_qualifications_page.dart';
import '../../pages/admin/admin_early_payments_page.dart';
import '../../pages/admin/admin_identity_verification_page.dart';
import '../../pages/referral_page.dart';

/// GoRouter インスタンスプロバイダー
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RoutePaths.home,
    observers: [AnalyticsService.observer],
    routes: [
      // --- メインページ（AuthGateで認証状態に応じてルーティング） ---
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const AuthGate(),
      ),

      // --- 認証 ---
      GoRoute(
        path: RoutePaths.login,
        pageBuilder: (context, state) => fadeThroughTransition(
          key: state.pageKey,
          child: const EmailAuthPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminLogin,
        pageBuilder: (context, state) => fadeThroughTransition(
          key: state.pageKey,
          child: const AdminLoginPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        pageBuilder: (context, state) => fadeThroughTransition(
          key: state.pageKey,
          child: const OnboardingPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.guestHome,
        pageBuilder: (context, state) => fadeThroughTransition(
          key: state.pageKey,
          child: const GuestHomePage(),
        ),
      ),

      // --- 管理者 ---
      GoRoute(
        path: RoutePaths.adminHome,
        pageBuilder: (context, state) => fadeThroughTransition(
          key: state.pageKey,
          child: const AdminHomePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminQualifications,
        pageBuilder: (context, state) => slideRightTransition(
          key: state.pageKey,
          child: const AdminQualificationsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminEarlyPayments,
        pageBuilder: (context, state) => slideRightTransition(
          key: state.pageKey,
          child: const AdminEarlyPaymentsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.adminIdentityVerification,
        pageBuilder: (context, state) => slideRightTransition(
          key: state.pageKey,
          child: const AdminIdentityVerificationPage(),
        ),
      ),

      // --- 案件系 ---
      GoRoute(
        path: RoutePaths.postJob,
        pageBuilder: (context, state) => slideUpTransition(
          key: state.pageKey,
          child: const PostPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.jobDetail,
        pageBuilder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          final extra = state.extra;
          final jobData = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
          return slideUpTransition(
            key: state.pageKey,
            child: JobDetailPage(jobId: jobId, jobData: jobData),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.jobEdit,
        pageBuilder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          final extra = state.extra;
          final jobData = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
          return slideRightTransition(
            key: state.pageKey,
            child: JobEditPage(jobId: jobId, jobData: jobData),
          );
        },
      ),

      // --- 応募・作業系 ---
      GoRoute(
        path: RoutePaths.workDetail,
        pageBuilder: (context, state) {
          final applicationId = state.pathParameters['applicationId'] ?? '';
          return slideUpTransition(
            key: state.pageKey,
            child: WorkDetailPage(applicationId: applicationId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.chatRoom,
        pageBuilder: (context, state) {
          final applicationId = state.pathParameters['applicationId'] ?? '';
          return slideUpTransition(
            key: state.pageKey,
            child: ChatRoomPage(applicationId: applicationId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.qrCheckin,
        pageBuilder: (context, state) {
          final applicationId = state.pathParameters['applicationId'] ?? '';
          final extra = state.extra;
          final isCheckOut = extra is Map && extra['isCheckOut'] == true;
          return slideUpTransition(
            key: state.pageKey,
            child: QrCheckinPage(applicationId: applicationId, isCheckOut: isCheckOut),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.shiftQr,
        pageBuilder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          final extra = state.extra;
          final jobTitle = extra is Map ? (extra['jobTitle'] ?? '').toString() : '';
          return slideUpTransition(
            key: state.pageKey,
            child: ShiftQrPage(jobId: jobId, jobTitle: jobTitle),
          );
        },
      ),

      // --- プロフィール・設定 ---
      GoRoute(
        path: RoutePaths.myProfile,
        pageBuilder: (context, state) => slideRightTransition(
          key: state.pageKey,
          child: const MyProfilePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.accountSettings,
        pageBuilder: (context, state) => slideRightTransition(
          key: state.pageKey,
          child: const AccountSettingsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.identityVerification,
        pageBuilder: (context, state) => slideRightTransition(
          key: state.pageKey,
          child: const IdentityVerificationPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.stripeOnboarding,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final email = extra is Map ? extra['email'] as String? : null;
          return slideRightTransition(
            key: state.pageKey,
            child: StripeOnboardingPage(email: email),
          );
        },
      ),

      // --- 通知 ---
      GoRoute(
        path: RoutePaths.notifications,
        pageBuilder: (context, state) => slideRightTransition(
          key: state.pageKey,
          child: const NotificationsPage(),
        ),
      ),

      // --- 売上 ---
      GoRoute(
        path: RoutePaths.earningsCreate,
        pageBuilder: (context, state) => slideUpTransition(
          key: state.pageKey,
          child: const EarningsCreatePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.paymentDetail,
        pageBuilder: (context, state) {
          final paymentId = state.pathParameters['paymentId'] ?? '';
          return slideUpTransition(
            key: state.pageKey,
            child: PaymentDetailPage(paymentId: paymentId),
          );
        },
      ),

      // --- 日報・検査・タイムライン ---
      GoRoute(
        path: RoutePaths.workReportCreate,
        pageBuilder: (context, state) {
          final applicationId = state.pathParameters['applicationId'] ?? '';
          return slideUpTransition(
            key: state.pageKey,
            child: WorkReportCreatePage(applicationId: applicationId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.workInspection,
        pageBuilder: (context, state) {
          final applicationId = state.pathParameters['applicationId'] ?? '';
          return slideUpTransition(
            key: state.pageKey,
            child: InspectionPage(applicationId: applicationId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.workTimeline,
        pageBuilder: (context, state) {
          final applicationId = state.pathParameters['applicationId'] ?? '';
          return slideUpTransition(
            key: state.pageKey,
            child: Scaffold(
              appBar: AppBar(title: const Text('工程タイムライン')),
              body: TimelineTab(applicationId: applicationId),
            ),
          );
        },
      ),

      // --- 資格 ---
      GoRoute(
        path: RoutePaths.qualifications,
        pageBuilder: (context, state) => slideRightTransition(
          key: state.pageKey,
          child: const QualificationsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.qualificationAdd,
        pageBuilder: (context, state) => slideUpTransition(
          key: state.pageKey,
          child: const QualificationAddPage(),
        ),
      ),

      // --- 明細 ---
      GoRoute(
        path: RoutePaths.statements,
        pageBuilder: (context, state) => slideRightTransition(
          key: state.pageKey,
          child: const Scaffold(body: Center(child: Text('明細一覧'))),
        ),
      ),
      GoRoute(
        path: RoutePaths.statementDetail,
        pageBuilder: (context, state) {
          final statementId = state.pathParameters['statementId'] ?? '';
          return slideUpTransition(
            key: state.pageKey,
            child: StatementDetailPage(statementId: statementId),
          );
        },
      ),

      // --- お気に入り ---
      GoRoute(
        path: RoutePaths.favorites,
        pageBuilder: (context, state) => slideRightTransition(
          key: state.pageKey,
          child: const FavoritesPage(),
        ),
      ),

      // --- 紹介 ---
      GoRoute(
        path: RoutePaths.referral,
        pageBuilder: (context, state) => slideRightTransition(
          key: state.pageKey,
          child: const ReferralPage(),
        ),
      ),

      // --- 電話認証 ---
      GoRoute(
        path: RoutePaths.phoneAuth,
        pageBuilder: (context, state) => fadeThroughTransition(
          key: state.pageKey,
          child: const PhoneAuthPage(),
        ),
      ),

      // --- マップ検索 ---
      GoRoute(
        path: RoutePaths.mapSearch,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final initialJobs = extra is List<Map<String, dynamic>> ? extra : null;
          return slideUpTransition(
            key: state.pageKey,
            child: MapSearchPage(initialJobs: initialJobs),
          );
        },
      ),

      // --- その他 ---
      GoRoute(
        path: RoutePaths.contact,
        pageBuilder: (context, state) => fadeThroughTransition(
          key: state.pageKey,
          child: const ContactPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.faq,
        pageBuilder: (context, state) => fadeThroughTransition(
          key: state.pageKey,
          child: const FaqPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.legalIndex,
        pageBuilder: (context, state) => fadeThroughTransition(
          key: state.pageKey,
          child: const LegalIndexPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.legal,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final title = extra is Map ? (extra['title'] ?? '').toString() : '';
          final htmlContent = extra is Map ? (extra['htmlContent'] ?? '').toString() : '';
          return fadeThroughTransition(
            key: state.pageKey,
            child: LegalPage(title: title, htmlContent: htmlContent),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('ページが見つかりません')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('${state.uri} は存在しません'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    ),
  );
});
