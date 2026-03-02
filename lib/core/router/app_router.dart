import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/analytics_service.dart';
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
        builder: (context, state) => const EmailAuthPage(),
      ),
      GoRoute(
        path: RoutePaths.adminLogin,
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RoutePaths.guestHome,
        builder: (context, state) => const GuestHomePage(),
      ),

      // --- 管理者 ---
      GoRoute(
        path: RoutePaths.adminHome,
        builder: (context, state) => const AdminHomePage(),
      ),

      // --- 案件系 ---
      GoRoute(
        path: RoutePaths.postJob,
        builder: (context, state) => const PostPage(),
      ),
      GoRoute(
        path: RoutePaths.jobDetail,
        builder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          final extra = state.extra;
          final jobData = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
          return JobDetailPage(jobId: jobId, jobData: jobData);
        },
      ),
      GoRoute(
        path: RoutePaths.jobEdit,
        builder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          final extra = state.extra;
          final jobData = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
          return JobEditPage(jobId: jobId, jobData: jobData);
        },
      ),

      // --- 応募・作業系 ---
      GoRoute(
        path: RoutePaths.workDetail,
        builder: (context, state) {
          final applicationId = state.pathParameters['applicationId'] ?? '';
          return WorkDetailPage(applicationId: applicationId);
        },
      ),
      GoRoute(
        path: RoutePaths.chatRoom,
        builder: (context, state) {
          final applicationId = state.pathParameters['applicationId'] ?? '';
          return ChatRoomPage(applicationId: applicationId);
        },
      ),
      GoRoute(
        path: RoutePaths.qrCheckin,
        builder: (context, state) {
          final applicationId = state.pathParameters['applicationId'] ?? '';
          final extra = state.extra;
          final isCheckOut = extra is Map && extra['isCheckOut'] == true;
          return QrCheckinPage(applicationId: applicationId, isCheckOut: isCheckOut);
        },
      ),
      GoRoute(
        path: RoutePaths.shiftQr,
        builder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          final extra = state.extra;
          final jobTitle = extra is Map ? (extra['jobTitle'] ?? '').toString() : '';
          return ShiftQrPage(jobId: jobId, jobTitle: jobTitle);
        },
      ),

      // --- プロフィール・設定 ---
      GoRoute(
        path: RoutePaths.myProfile,
        builder: (context, state) => const MyProfilePage(),
      ),
      GoRoute(
        path: RoutePaths.accountSettings,
        builder: (context, state) => const AccountSettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.identityVerification,
        builder: (context, state) => const IdentityVerificationPage(),
      ),
      GoRoute(
        path: RoutePaths.stripeOnboarding,
        builder: (context, state) {
          final extra = state.extra;
          final email = extra is Map ? extra['email'] as String? : null;
          return StripeOnboardingPage(email: email);
        },
      ),

      // --- 通知 ---
      GoRoute(
        path: RoutePaths.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),

      // --- 売上 ---
      GoRoute(
        path: RoutePaths.earningsCreate,
        builder: (context, state) => const EarningsCreatePage(),
      ),
      GoRoute(
        path: RoutePaths.paymentDetail,
        builder: (context, state) {
          final paymentId = state.pathParameters['paymentId'] ?? '';
          return PaymentDetailPage(paymentId: paymentId);
        },
      ),

      // --- その他 ---
      GoRoute(
        path: RoutePaths.contact,
        builder: (context, state) => const ContactPage(),
      ),
      GoRoute(
        path: RoutePaths.faq,
        builder: (context, state) => const FaqPage(),
      ),
      GoRoute(
        path: RoutePaths.legal,
        builder: (context, state) {
          final extra = state.extra;
          final title = extra is Map ? (extra['title'] ?? '').toString() : '';
          final htmlContent = extra is Map ? (extra['htmlContent'] ?? '').toString() : '';
          return LegalPage(title: title, htmlContent: htmlContent);
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
