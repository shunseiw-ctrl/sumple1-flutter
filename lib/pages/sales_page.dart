import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'earnings_create_page.dart';
import 'job_detail_page.dart';
import '../core/services/auth_service.dart';
import '../core/enums/user_role.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/presentation/widgets/registration_prompt.dart';

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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.ruriPale,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(Icons.payments_outlined, size: 40, color: AppColors.ruri),
                ),
                const SizedBox(height: 24),
                const Text(
                  '売上を確認するには\n登録が必要です',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'お仕事の報酬や支払い履歴を\nこのページで確認できます',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => RegistrationPromptModal.show(context, featureName: '売上を確認する'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ruri,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('登録して始める', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
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
          _FavoritesContent(),
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
    final q = db.collection('earnings').where('uid', isEqualTo: widget.uid);

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
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            _ShadowCard(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '今月の売上',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _yen(thisMonth),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '獲得売上',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _yen(total),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            _ShadowCard(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '月別推移',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

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

                    const SizedBox(height: 12),

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

                    const SizedBox(height: 10),
                    Text(
                      '※売上は支払い確定日に反映されます',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'データ件数: ${docs.length}件',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (widget.isAdmin) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('支払い管理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 12),
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('お気に入りはまだありません', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('案件の♡をタップして追加できます', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: jobIds.length,
          itemBuilder: (context, i) {
            final jobId = jobIds[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
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

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailPage(jobId: jobId, jobData: job),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                bottomLeft: Radius.circular(14),
                              ),
                              child: SizedBox(
                                width: 100,
                                height: 90,
                                child: imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppColors.chipUnselected,
                                          child: Icon(Icons.work, color: AppColors.textHint),
                                        ),
                                      )
                                    : Container(
                                        color: AppColors.chipUnselected,
                                        child: Icon(Icons.work, color: AppColors.textHint),
                                      ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    if (location.isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 14, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(location, style: TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (price.isNotEmpty)
                                          Text('¥$price', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ruri)),
                                        const Spacer(),
                                        if (date.isNotEmpty)
                                          Text(date, style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.ruriPale,
        borderRadius: BorderRadius.circular(14),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  monthText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: selected ? 1 : 0,
          child: Container(
            width: 18,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.ruri,
              borderRadius: BorderRadius.circular(999),
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          )
        ],
        border: Border.all(color: AppColors.divider),
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
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(child: Text('支払いデータはまだありません', style: TextStyle(color: AppColors.textSecondary))),
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
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 18, color: AppColors.ruri),
                      const SizedBox(width: 8),
                      Text(month, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('$count件', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
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
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
