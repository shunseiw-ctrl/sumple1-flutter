import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';
import '../core/services/auth_service.dart';
import '../core/enums/user_role.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/registration_prompt.dart';
import '../core/services/analytics_service.dart';
import 'package:sumple1/core/config/feature_flags.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';

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
          _SalesContent(uid: uid, isAdmin: isAdmin),
          _StatementsContent(uid: uid),
        ],
      ),
    );
  }
}

class _SalesContent extends StatefulWidget {
  final String uid;
  final bool isAdmin;
  const _SalesContent({required this.uid, required this.isAdmin});

  @override
  State<_SalesContent> createState() => _SalesContentState();
}

class _SalesContentState extends State<_SalesContent> {
  Key _refreshKey = UniqueKey();
  DateTime? _selectedMonth;

  String _two(int n) => n.toString().padLeft(2, '0');
  String _ym(DateTime m) => '${m.year}/${_two(m.month)}';

  String _yen(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    return '¥${buf.toString()}';
  }

  DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);
  DateTime _nextMonthStart(DateTime d) => DateTime(d.year, d.month + 1, 1);

  List<DateTime> _lastNMonths(int n) {
    final now = DateTime.now();
    final cur = DateTime(now.year, now.month, 1);
    final list = <DateTime>[];
    for (int i = n - 1; i >= 0; i--) {
      list.add(DateTime(cur.year, cur.month - i, 1));
    }
    return list;
  }

  String _monthLabel(BuildContext context, DateTime m) =>
      context.l10n.sales_monthLabel(m.month.toString());

  int _nextPaymentMonth() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1, 1);
    return next.month;
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final q = db.collection('earnings')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('payoutConfirmedAt', descending: true)
        .limit(200);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: _refreshKey,
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SkeletonList(itemBuilder: (_) => const SkeletonSalesCard());
        }
        if (snap.hasError) {
          return Center(child: Text('${context.l10n.common_loadError}: ${snap.error}'));
        }

        final docs = snap.data?.docs ?? [];

        final months = _lastNMonths(6);
        final monthSums = <DateTime, int>{for (final m in months) m: 0};

        int total = 0;

        final now = DateTime.now();
        final thisMonthStart = _monthStart(now);
        final nextMonthStart = _nextMonthStart(now);
        int thisMonth = 0;

        for (final d in docs) {
          final m = d.data();
          final amount = (m['amount'] is int) ? (m['amount'] as int) : 0;
          total += amount;

          DateTime? confirmedAt;
          final ts = m['payoutConfirmedAt'];
          if (ts is Timestamp) confirmedAt = ts.toDate();

          if (confirmedAt != null) {
            if (!confirmedAt.isBefore(thisMonthStart) &&
                confirmedAt.isBefore(nextMonthStart)) {
              thisMonth += amount;
            }

            final key = DateTime(confirmedAt.year, confirmedAt.month, 1);
            if (monthSums.containsKey(key)) {
              monthSums[key] = (monthSums[key] ?? 0) + amount;
            }
          }
        }

        _selectedMonth ??= DateTime(now.year, now.month, 1);

        final selectedKey = _selectedMonth!;
        final selectedValue = monthSums[selectedKey] ?? 0;

        final maxV = monthSums.values.isEmpty
            ? 0
            : monthSums.values.reduce((a, b) => a > b ? a : b);

        final bars = months.map((m) {
          final v = monthSums[m] ?? 0;
          if (maxV <= 0) return 0.0;
          return (v / maxV).clamp(0.0, 1.0);
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _refreshKey = UniqueKey());
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: context.appColors.primary,
          child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.base, AppSpacing.pagePadding, AppSpacing.xl),
          children: [
            // --- Gradient Header Card ---
            Container(
              decoration: BoxDecoration(
                gradient: context.appColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLg),
                boxShadow: AppShadows.card,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.sales_thisMonthIncome,
                      style: AppTextStyles.sectionTitle.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _yen(thisMonth),
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                      ),
                      child: Text(
                        context.l10n.sales_nextPaymentDate(_nextPaymentMonth().toString()),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.l10n.sales_totalIncome,
                          style: AppTextStyles.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _yen(total),
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // --- 未確定の報酬 ---
            _UnconfirmedEarningsSection(uid: widget.uid),

            const SizedBox(height: AppSpacing.base),

            // --- Monthly Bar Chart ---
            _ShadowCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.sales_monthlyTrend,
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    _SelectedMonthCard(
                      monthText:
                      '${_ym(selectedKey)}（${_monthLabel(context, selectedKey)}）',
                      amountText: _yen(selectedValue),
                      onResetToThisMonth: () {
                        setState(() {
                          _selectedMonth = DateTime(now.year, now.month, 1);
                        });
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    SizedBox(
                      height: 190,
                      child: CustomPaint(
                        painter: _BarChartPainter(bars: bars, gridLines: 4),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(bars.length, (i) {
                                final m = months[i];

                                final isSelected =
                                (_selectedMonth?.year == m.year &&
                                    _selectedMonth?.month == m.month);

                                final barColor = isSelected
                                    ? context.appColors.primary
                                    : context.appColors.textHint;

                                final labelColor = isSelected
                                    ? context.appColors.primary
                                    : context.appColors.textPrimary;

                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _selectedMonth = m;
                                      });
                                    },
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const SizedBox(height: 6),
                                        _Bar(
                                          value: bars[i],
                                          color: barColor,
                                          selected: isSelected,
                                        ),
                                        const SizedBox(height: 10),

                                        _MonthLabel(
                                          text: _monthLabel(context, m),
                                          selected: isSelected,
                                          color: labelColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.sales_incomeNote,
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.sales_dataCount(docs.length.toString()),
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // --- 支払い履歴 ---
            _PaymentHistorySection(docs: docs),

            if (widget.isAdmin) ...[
              const SizedBox(height: AppSpacing.sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(context.l10n.sales_paymentManagement, style: AppTextStyles.headingSmall),
              ),
              const SizedBox(height: AppSpacing.md),
              const _PaymentSummarySection(),
            ],
          ],
        ),
        );
      },
    );
  }
}

/// 未確定の報酬セクション
class _UnconfirmedEarningsSection extends StatelessWidget {
  final String uid;
  const _UnconfirmedEarningsSection({required this.uid});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('applications')
          .where('applicantUid', isEqualTo: uid)
          .where('status', whereIn: ['completed', 'done'])
          .snapshots(),
      builder: (context, appSnap) {
        if (appSnap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final appDocs = appSnap.data?.docs ?? [];
        if (appDocs.isEmpty) return const SizedBox.shrink();

        // earningsからapplicationIdで確認
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('earnings')
              .where('uid', isEqualTo: uid)
              .snapshots(),
          builder: (context, earningsSnap) {
            if (earningsSnap.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            final earningsDocs = earningsSnap.data?.docs ?? [];
            final earningsAppIds = <String>{};
            for (final doc in earningsDocs) {
              final appId = (doc.data()['applicationId'] ?? '').toString();
              if (appId.isNotEmpty) earningsAppIds.add(appId);
            }

            // earningsが無いapplication = 未確定
            final unconfirmed = appDocs.where((d) => !earningsAppIds.contains(d.id)).toList();
            if (unconfirmed.isEmpty) return const SizedBox.shrink();

            return _ShadowCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pending_actions, size: 20, color: context.appColors.warning),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          context.l10n.sales_unconfirmedEarnings,
                          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.appColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                          ),
                          child: Text(
                            '${unconfirmed.length}${context.l10n.common_itemsCount}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: context.appColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...unconfirmed.map((doc) {
                      final data = doc.data();
                      final jobTitle = (data['jobTitleSnapshot'] ?? context.l10n.common_job).toString();
                      final status = (data['status'] ?? '').toString();
                      final statusLabel = status == 'done' ? context.l10n.common_completed : context.l10n.sales_constructionCompleted;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                jobTitle,
                                style: AppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.appColors.chipUnselected,
                                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                              ),
                              child: Text(
                                statusLabel,
                                style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.sales_earningsNote,
                      style: AppTextStyles.labelSmall.copyWith(color: context.appColors.textHint),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 支払い履歴セクション
class _PaymentHistorySection extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  const _PaymentHistorySection({required this.docs});

  String _formatYen(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return '¥${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) return const SizedBox.shrink();

    return _ShadowCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, size: 20, color: context.appColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.l10n.sales_paymentHistory,
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...docs.take(20).map((doc) {
              final data = doc.data();
              final amount = (data['amount'] is int) ? (data['amount'] as int) : 0;
              final paymentStatus = (data['paymentStatus'] ?? '').toString();
              final paymentId = (data['paymentId'] ?? '').toString();
              final isPaid = paymentStatus == 'paid';

              DateTime? confirmedAt;
              final ts = data['payoutConfirmedAt'];
              if (ts is Timestamp) confirmedAt = ts.toDate();

              final dateText = confirmedAt != null
                  ? '${confirmedAt.year}/${confirmedAt.month.toString().padLeft(2, '0')}/${confirmedAt.day.toString().padLeft(2, '0')}'
                  : '';

              final canNavigate = paymentId.isNotEmpty && FeatureFlags.enableStripePayments;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  onTap: canNavigate
                      ? () {
                          context.push(RoutePaths.paymentDetailPath(paymentId));
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatYen(amount),
                                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (dateText.isNotEmpty)
                                Text(
                                  dateText,
                                  style: AppTextStyles.labelSmall.copyWith(color: context.appColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? context.appColors.success.withValues(alpha: 0.1)
                                : context.appColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                          ),
                          child: Text(
                            isPaid ? '${context.l10n.common_transferred} ✓' : context.l10n.common_confirmed,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isPaid ? context.appColors.success : context.appColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (canNavigate)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.chevron_right, size: 18, color: context.appColors.textHint),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SelectedMonthCard extends StatelessWidget {
  final String monthText;
  final String amountText;
  final VoidCallback onResetToThisMonth;

  const _SelectedMonthCard({
    required this.monthText,
    required this.amountText,
    required this.onResetToThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.appColors.primaryPale,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.sales_selectedMonthIncome,
                  style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  monthText,
                  style: AppTextStyles.labelSmall.copyWith(color: context.appColors.textSecondary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Text(
            amountText,
            style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: context.l10n.sales_resetToThisMonth,
            onPressed: onResetToThisMonth,
            icon: const Icon(Icons.refresh, size: 18),
          ),
        ],
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  final String text;
  final bool selected;
  final Color color;

  const _MonthLabel({
    required this.text,
    required this.selected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: selected ? 1 : 0,
          child: Container(
            width: 18,
            height: 4,
            decoration: BoxDecoration(
              color: context.appColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShadowCard extends StatelessWidget {
  final Widget child;
  const _ShadowCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusLg),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final Color color;
  final bool selected;

  const _Bar({
    required this.value,
    required this.color,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    const maxH = 110.0;
    final h = (maxH * v);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 18,
      height: maxH,
      alignment: Alignment.bottomCenter,
      child: Container(
        height: h,
        width: selected ? 16 : 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> bars;
  final int gridLines;

  _BarChartPainter({required this.bars, this.gridLines = 4});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE9EBF2)
      ..strokeWidth = 1;

    final h = size.height;
    final w = size.width;

    for (int i = 0; i <= gridLines; i++) {
      final y = (h - 26) * (i / gridLines) + 6;
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }

    final vPaint = Paint()
      ..color = const Color(0xFFF0F1F6)
      ..strokeWidth = 1;

    final cols = bars.isEmpty ? 6 : bars.length;
    for (int i = 0; i < cols; i++) {
      final x = w * ((i + 0.5) / cols);
      canvas.drawLine(Offset(x, 10), Offset(x, h - 30), vPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.bars != bars || oldDelegate.gridLines != gridLines;
  }
}

class _PaymentSummarySection extends StatelessWidget {
  const _PaymentSummarySection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('earnings')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.base), child: CircularProgressIndicator()));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              boxShadow: AppShadows.subtle,
            ),
            child: Center(child: Text(context.l10n.sales_noPaymentData, style: AppTextStyles.bodySmall)),
          );
        }

        final monthlyMap = <String, Map<String, dynamic>>{};
        for (final doc in docs) {
          final data = doc.data();
          final createdAt = data['createdAt'];
          String monthKey = context.l10n.common_unknown;
          if (createdAt is Timestamp) {
            final d = createdAt.toDate();
            monthKey = '${d.year}/${d.month.toString().padLeft(2, '0')}';
          }

          if (!monthlyMap.containsKey(monthKey)) {
            monthlyMap[monthKey] = {'total': 0, 'count': 0, 'paid': 0, 'unpaid': 0};
          }

          final amount = int.tryParse((data['amount'] ?? '0').toString()) ?? 0;
          final isPaid = data['paymentStatus'] == 'paid';

          monthlyMap[monthKey]!['total'] = (monthlyMap[monthKey]!['total'] as int) + amount;
          monthlyMap[monthKey]!['count'] = (monthlyMap[monthKey]!['count'] as int) + 1;
          if (isPaid) {
            monthlyMap[monthKey]!['paid'] = (monthlyMap[monthKey]!['paid'] as int) + amount;
          } else {
            monthlyMap[monthKey]!['unpaid'] = (monthlyMap[monthKey]!['unpaid'] as int) + amount;
          }
        }

        final sortedMonths = monthlyMap.keys.toList()..sort((a, b) => b.compareTo(a));

        return Column(
          children: sortedMonths.map((month) {
            final info = monthlyMap[month]!;
            final total = info['total'] as int;
            final count = info['count'] as int;
            final paid = info['paid'] as int;
            final unpaid = info['unpaid'] as int;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 18, color: context.appColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(month, style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                      const Spacer(),
                      Text('$count${context.l10n.common_itemsCount}', style: AppTextStyles.labelMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(label: context.l10n.sales_total, value: '¥${_formatPrice(total)}', color: context.appColors.textPrimary),
                      ),
                      Expanded(
                        child: _MiniStat(label: context.l10n.sales_paid, value: '¥${_formatPrice(paid)}', color: context.appColors.success),
                      ),
                      Expanded(
                        child: _MiniStat(label: context.l10n.sales_unpaid, value: '¥${_formatPrice(unpaid)}', color: context.appColors.warning),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatPrice(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _StatementsContent extends StatelessWidget {
  final String uid;
  const _StatementsContent({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('monthly_statements')
          .where('workerUid', isEqualTo: uid)
          .orderBy('month', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SkeletonList();
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: context.l10n.sales_noStatements,
            description: context.l10n.sales_noStatementsDescription,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final month = (data['month'] ?? '').toString();
            final total = int.tryParse((data['totalAmount'] ?? '0').toString()) ?? 0;
            final status = (data['status'] ?? 'draft').toString();
            final statusLabel = switch (status) {
              'draft' => context.l10n.sales_statusDraft,
              'confirmed' => context.l10n.common_confirmed,
              'paid' => context.l10n.sales_statusPaid,
              _ => status,
            };
            final statusColor = switch (status) {
              'paid' => context.appColors.success,
              'confirmed' => context.appColors.primary,
              _ => context.appColors.textSecondary,
            };

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: Icon(Icons.receipt_long, color: context.appColors.primary),
                title: Text(context.l10n.sales_monthStatement(month),
                    style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('${context.l10n.sales_total}: ¥${_formatAmount(total)}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                onTap: () {
                  context.push(RoutePaths.statementDetailPath(docs[i].id));
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatAmount(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}
