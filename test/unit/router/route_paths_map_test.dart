import 'package:flutter_test/flutter_test.dart';
import 'package:sumple1/core/router/route_paths.dart';

void main() {
  group('RoutePaths - mapSearch', () {
    test("mapSearchが'/map-search'", () {
      expect(RoutePaths.mapSearch, '/map-search');
    });

    test('ルート定数の一意性確認', () {
      final allPaths = [
        RoutePaths.home,
        RoutePaths.login,
        RoutePaths.adminLogin,
        RoutePaths.onboarding,
        RoutePaths.guestHome,
        RoutePaths.jobList,
        RoutePaths.work,
        RoutePaths.messages,
        RoutePaths.sales,
        RoutePaths.profile,
        RoutePaths.jobDetail,
        RoutePaths.jobEdit,
        RoutePaths.postJob,
        RoutePaths.workDetail,
        RoutePaths.chatRoom,
        RoutePaths.qrCheckin,
        RoutePaths.shiftQr,
        RoutePaths.myProfile,
        RoutePaths.accountSettings,
        RoutePaths.identityVerification,
        RoutePaths.stripeOnboarding,
        RoutePaths.notifications,
        RoutePaths.earningsCreate,
        RoutePaths.paymentDetail,
        RoutePaths.contact,
        RoutePaths.faq,
        RoutePaths.legal,
        RoutePaths.adminHome,
        RoutePaths.mapSearch,
      ];

      final uniquePaths = allPaths.toSet();
      expect(uniquePaths.length, allPaths.length, reason: 'ルートパスに重複があります');
    });
  });
}
