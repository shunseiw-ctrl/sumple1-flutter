import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/utils/currency_utils.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'sales_shared.dart';
import 'unconfirmed_earnings_section.dart';
import 'payment_history_section.dart';
import 'payment_summary_section.dart';

/// 収入タブメイン
class SalesContent extends StatefulWidget {
  final String uid;
  final bool isAdmin;
  const SalesContent({super.key, required this.uid, required this.isAdmin});

  @override
  State<SalesContent> createState() => _SalesContentState();
}

class _SalesContentState extends State<SalesContent> {
  Key _refreshKey = UniqueKey();
  DateTime? _selectedMonth;

  String _two(int n) => n.toString().padLeft(2, '0');
  String _ym(DateTime m) => '${m.year}/${_two(m.month)}';

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
          return ErrorRetryWidget.general(
            onRetry: () => setState(() => _refreshKey = UniqueKey()),
            message: '${context.l10n.common_loadError}: ${snap.error}',
          );
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
                      CurrencyUtils.formatYen(thisMonth),
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
                          CurrencyUtils.formatYen(total),
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
            UnconfirmedEarningsSection(uid: widget.uid),

            const SizedBox(height: AppSpacing.base),

            // --- Monthly Bar Chart ---
            SalesShadowCard(
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
                      amountText: CurrencyUtils.formatYen(selectedValue),
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
            PaymentHistorySection(docs: docs),

            if (widget.isAdmin) ...[
              const SizedBox(height: AppSpacing.sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(context.l10n.sales_paymentManagement, style: AppTextStyles.headingSmall),
              ),
              const SizedBox(height: AppSpacing.md),
              const PaymentSummarySection(),
            ],
          ],
        ),
        );
      },
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
