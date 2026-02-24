import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'earnings_create_page.dart';
import '../core/services/auth_service.dart';
import '../core/enums/user_role.dart';
import 'package:sumple1/core/constants/app_colors.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _authService = AuthService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final role = await _authService.getCurrentUserRole();
    if (mounted) {
      setState(() => _isAdmin = role.isAdmin);
    }
  }

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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('ログインしてください')));
    }

    final isAdmin = _isAdmin;

    final db = FirebaseFirestore.instance;
    final q = db.collection('earnings').where('uid', isEqualTo: uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('売上'),
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
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
            ],
          );
        },
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
