import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';
import '../core/services/auth_service.dart';
import '../core/enums/user_role.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/registration_prompt.dart';
import '../core/services/analytics_service.dart';
import 'package:sumple1/core/config/feature_flags.dart';
import 'sales/sales_content.dart';
import 'sales/statements_content.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _isAdmin = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('sales');
    _checkAdminRole();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminRole() async {
    final role = await _authService.getCurrentUserRole();
    if (mounted) {
      setState(() => _isAdmin = role.isAdmin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isAnonymous = FirebaseAuth.instance.currentUser?.isAnonymous ?? true;
    if (uid.isEmpty || isAnonymous) {
      return Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(title: Text(context.l10n.sales_salesTitle), centerTitle: true),
        body: EmptyState(
          icon: Icons.payments_outlined,
          title: context.l10n.sales_registrationRequired,
          description: context.l10n.sales_registrationDescription,
          actionText: context.l10n.sales_registerToStart,
          onAction: () => RegistrationPromptModal.show(context, featureName: context.l10n.sales_checkSales),
        ),
      );
    }

    final isAdmin = _isAdmin;

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(context.l10n.sales_incomeAndStatements),
        centerTitle: true,
        actions: [
          if (isAdmin && FeatureFlags.enableStripePayments)
            IconButton(
              tooltip: context.l10n.sales_registerPayment,
              icon: const Icon(Icons.add),
              onPressed: () {
                context.push(RoutePaths.earningsCreate);
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.appColors.primary,
          unselectedLabelColor: context.appColors.textSecondary,
          indicatorColor: context.appColors.primary,
          labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: context.appColors.primary),
          unselectedLabelStyle: AppTextStyles.labelMedium,
          tabs: [
            Tab(text: context.l10n.sales_tabIncome),
            Tab(text: context.l10n.sales_tabStatements),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SalesContent(uid: uid, isAdmin: isAdmin),
          StatementsContent(uid: uid),
        ],
      ),
    );
  }
}
