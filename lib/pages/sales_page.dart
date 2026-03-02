import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'earnings_create_page.dart';
import 'job_detail_page.dart';
import '../core/services/auth_service.dart';
import '../core/enums/user_role.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/registration_prompt.dart';
import '../core/services/analytics_service.dart';
import 'package:sumple1/presentation/widgets/cached_image.dart';

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
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('売上'), centerTitle: true),
        body: EmptyState(
          icon: Icons.payments_outlined,
          title: '売上を確認するには\n登録が必要です',
          description: 'お仕事の報酬や支払い履歴を\nこのページで確認できます',
          actionText: '登録して始める',
          onAction: () => RegistrationPromptModal.show(context, featureName: '売上を確認する'),
        ),
      );
    }

    final isAdmin = _isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('売上・お気に入り'),
        centerTitle: true,
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: '支払い確定を登録',
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EarningsCreatePage()),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.ruri,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.ruri,
          labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.ruri),
          unselectedLabelStyle: AppTextStyles.labelMedium,
          tabs: const [
            Tab(text: '売上'),
            Tab(icon: Icon(Icons.favorite, size: 18), text: 'お気に入り'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SalesContent(uid: uid, isAdmin: isAdmin),
          const _FavoritesContent(),
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

  String _monthLabel(DateTime m) => '${m.month}月';

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final q = db.collection('earnings')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('payoutConfirmedAt', descending: true)
        .limit(200);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('読み込みエラー: ${snap.error}'));
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

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.base, AppSpacing.pagePadding, AppSpacing.xl),
          children: [
            _ShadowCard(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '今月の売上',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _yen(thisMonth),
                      style: AppTextStyles.displayLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '獲得売上',
                          style: AppTextStyles.labelSmall,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _yen(total),
                          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            _ShadowCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '月別推移',
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    _SelectedMonthCard(
                      monthText:
                      '${_ym(selectedKey)}（${_monthLabel(selectedKey)}）',
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
                                    ? AppColors.ruri
                                    : AppColors.textHint;

                                final labelColor = isSelected
                                    ? AppColors.ruri
                                    : AppColors.textPrimary;

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
                                          text: _monthLabel(m),
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
                      '※売上は支払い確定日に反映されます',
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'データ件数: ${docs.length}件',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
            ),

            if (widget.isAdmin) ...[
              const SizedBox(height: AppSpacing.sectionGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text('支払い管理', style: AppTextStyles.headingSmall),
              ),
              const SizedBox(height: AppSpacing.md),
              const _PaymentSummarySection(),
            ],
          ],
        );
      },
    );
  }
}

class _FavoritesContent extends StatelessWidget {
  const _FavoritesContent();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return const Center(child: Text('ログインが必要です'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('favorites').doc(uid).snapshots(),
      builder: (context, favSnap) {
        if (favSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final favData = favSnap.data?.data();
        final jobIds = List<String>.from(favData?['jobIds'] ?? []);

        if (jobIds.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_border,
            title: 'お気に入りはまだありません',
            description: '案件の♡をタップして追加できます',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          itemCount: jobIds.length,
          itemBuilder: (context, i) {
            final jobId = jobIds[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('jobs').doc(jobId).snapshots(),
                builder: (context, jobSnap) {
                  if (!jobSnap.hasData || !jobSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  final job = jobSnap.data!.data() ?? {};
                  final title = (job['title'] ?? 'タイトルなし').toString();
                  final location = (job['location'] ?? '').toString();
                  final price = (job['price'] ?? '').toString();
                  final date = (job['date'] ?? '').toString();
                  final imageUrl = (job['imageUrl'] ?? '').toString();

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      boxShadow: AppShadows.card,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailPage(jobId: jobId, jobData: job),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(AppSpacing.cardRadius),
                                bottomLeft: Radius.circular(AppSpacing.cardRadius),
                              ),
                              child: SizedBox(
                                width: 100,
                                height: 90,
                                child: imageUrl.isNotEmpty
                                    ? AppCachedImage(
                                        imageUrl: imageUrl,
                                        width: 100,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: AppColors.chipUnselected,
                                        child: const Icon(Icons.work, color: AppColors.textHint),
                                      ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: AppSpacing.xs),
                                    if (location.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint),
                                          const SizedBox(width: AppSpacing.xs),
                                          Expanded(child: Text(location, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        if (price.isNotEmpty)
                                          Text('¥$price', style: AppTextStyles.salary.copyWith(fontSize: 14)),
                                        const Spacer(),
                                        if (date.isNotEmpty)
                                          Text(date, style: AppTextStyles.labelSmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.sm),
                              child: IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('favorites').doc(uid).update({
                                    'jobIds': FieldValue.arrayRemove([jobId]),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
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
        color: AppColors.ruriPale,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '選択月の売上',
                  style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  monthText,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
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
            tooltip: '今月に戻す',
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
              color: AppColors.ruri,
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
        color: Colors.white,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              boxShadow: AppShadows.subtle,
            ),
            child: Center(child: Text('支払いデータはまだありません', style: AppTextStyles.bodySmall)),
          );
        }

        final monthlyMap = <String, Map<String, dynamic>>{};
        for (final doc in docs) {
          final data = doc.data();
          final createdAt = data['createdAt'];
          String monthKey = '不明';
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18, color: AppColors.ruri),
                      const SizedBox(width: AppSpacing.sm),
                      Text(month, style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                      const Spacer(),
                      Text('$count件', style: AppTextStyles.labelMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(label: '合計', value: '¥${_formatPrice(total)}', color: AppColors.textPrimary),
                      ),
                      Expanded(
                        child: _MiniStat(label: '支払済', value: '¥${_formatPrice(paid)}', color: AppColors.success),
                      ),
                      Expanded(
                        child: _MiniStat(label: '未払い', value: '¥${_formatPrice(unpaid)}', color: AppColors.warning),
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
