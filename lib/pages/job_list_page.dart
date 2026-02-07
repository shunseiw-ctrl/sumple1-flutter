import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'job_detail_page.dart';
import 'job_edit_page.dart';
import 'package:url_launcher/url_launcher.dart';

class JobListPage extends StatefulWidget {
  const JobListPage({super.key});

  @override
  State<JobListPage> createState() => _JobListPageState();
}

class _JobListPageState extends State<JobListPage> {
  String _selectedPref = '東京都';

  /// null = すべて（＝月で絞り込まない）
  String? _selectedMonthKey;

  String _sortLabel = '新着順'; // 今回は新着順固定（UIは残す）

  final List<String> _prefs = const [
    '千葉県',
    '東京都',
    '神奈川県',
    'その他',
  ];

  // 先頭に「今月」「来月」＋その後に数ヶ月を並べる
  late final List<_MonthChip> _monthChips = _buildMonthChips();

  List<_MonthChip> _buildMonthChips() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    DateTime addMonths(DateTime base, int m) => DateTime(base.year, base.month + m);

    // 例：今月/来月/4月/5月/6月… の雰囲気
    // 「今月」「来月」はラベル固定、以降は "{n}月"
    final list = <_MonthChip>[];
    list.add(_MonthChip(label: '今月', month: thisMonth));
    list.add(_MonthChip(label: '来月', month: addMonths(thisMonth, 1)));

    // 追加で先の4ヶ月分
    for (int i = 2; i <= 6; i++) {
      final m = addMonths(thisMonth, i);
      list.add(_MonthChip(label: '${m.month}月', month: m));
    }
    return list;
  }

  String _monthKey(DateTime month) {
    final y = month.year.toString();
    final m = month.month.toString().padLeft(2, '0');
    return '$y-$m'; // YYYY-MM
  }

  Future<void> _openMapByQuery(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open: $url')),
      );

      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('launchUrl result: $ok')),
      );

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('地図アプリを開けませんでした（launchUrl=false）')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('地図エラー: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Column(
        children: [
          // ===== 上部：勤務地チップ =====
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: _PrefChips(
              prefs: _prefs,
              selected: _selectedPref,
              onSelected: (p) => setState(() => _selectedPref = p),
            ),
          ),

          // ===== 月チップ + 並び替え =====
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              children: [
                _MonthChips(
                  months: _monthChips,
                  selectedMonthKey: _selectedMonthKey,
                  toKey: _monthKey,
                  onSelected: (monthKeyOrNull) {
                    setState(() => _selectedMonthKey = monthKeyOrNull);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _SortDropDown(
                      label: _sortLabel,
                      onSelected: (value) => setState(() => _sortLabel = value),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('絞り込みは一部のみ実装（都道府県＋月）')),
                        );
                      },
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('絞り込み'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        backgroundColor: const Color(0xFFF2F3F5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ===== 本文：Firestoreの案件カード =====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: (() {
                Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('jobs');

                // 地域
                if (_selectedPref != 'その他') {
                  q = q.where('prefecture', isEqualTo: _selectedPref);
                }

                // ✅ 月（workMonthKey: 'YYYY-MM'）で絞り込み
                // null は「すべて」
                if (_selectedMonthKey != null) {
                  q = q.where('workMonthKey', isEqualTo: _selectedMonthKey);
                }

                // ✅ 新着順固定
                q = q.orderBy('createdAt', descending: true);

                return q.snapshots();
              })(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _CenterMessage(text: 'エラー: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const _CenterMessage(text: '案件がありません');
                }

                final rawDocs = snapshot.data!.docs;

                // 「その他」＝ 千葉/東京/神奈川以外 ＋ prefecture未設定（旧データ）も表示
                const excludePrefs = {'千葉県', '東京都', '神奈川県'};

                final docs = _selectedPref == 'その他'
                    ? rawDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final pref = data['prefecture']?.toString();

                  if (pref == null || pref.isEmpty || pref == '未設定') return true;
                  return !excludePrefs.contains(pref);
                }).toList()
                    : rawDocs;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final title = data['title']?.toString() ?? 'タイトルなし';
                    final location = data['location']?.toString() ?? '未設定';
                    final price = data['price']?.toString() ?? '0';
                    final date = data['date']?.toString() ?? '未設定';

                    final ownerId = data['ownerId']?.toString();
                    final isOwner = currentUser != null &&
                        ownerId != null &&
                        ownerId.isNotEmpty &&
                        ownerId == currentUser.uid;

                    final hasOwnerId = ownerId != null && ownerId.isNotEmpty;

                    final badges = <_BadgeSpec>[]; // 将来復活用

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _JobCard(
                        title: title,
                        location: location,
                        dateText: date,
                        priceText: '¥$price',
                        badges: badges,
                        showLegacyWarning: !hasOwnerId,
                        isOwner: isOwner,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailPage(jobId: doc.id, jobData: data),
                            ),
                          );
                        },
                        onEdit: isOwner
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobEditPage(jobId: doc.id, jobData: data),
                            ),
                          );
                        }
                            : null,
                        onDelete: isOwner ? () => _showDeleteDialog(context, doc.id) : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final pref = _selectedPref == 'その他' ? '日本' : _selectedPref;

          // 月で地図検索（例：東京都 2026-02）
          final month = _selectedMonthKey;
          final query = (month == null) ? pref : '$pref $month';

          _openMapByQuery(query);
        },
        backgroundColor: Colors.black,
        icon: const Icon(Icons.map_outlined, color: Colors.white),
        label: const Text('地図で見る', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

/// 削除確認ダイアログ
Future<void> _showDeleteDialog(BuildContext context, String jobId) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この案件を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );

  if (ok != true) return;

  try {
    await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('削除しました')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('削除できませんでした: $e')),
    );
  }
}

// ===== UI Parts =====

class _CenterMessage extends StatelessWidget {
  final String text;
  const _CenterMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: Colors.black54, fontSize: 14),
      ),
    );
  }
}

class _PrefChips extends StatelessWidget {
  final List<String> prefs;
  final String selected;
  final ValueChanged<String> onSelected;

  const _PrefChips({
    required this.prefs,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: prefs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = prefs[i];
          final isSelected = p == selected;
          return ChoiceChip(
            label: Text(p),
            selected: isSelected,
            onSelected: (_) => onSelected(p),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            selectedColor: Colors.black,
            backgroundColor: const Color(0xFFF2F3F5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }
}

class _MonthChip {
  final String label;
  final DateTime month; // year/month のみ使う
  const _MonthChip({required this.label, required this.month});
}

class _MonthChips extends StatelessWidget {
  final List<_MonthChip> months;
  final String? selectedMonthKey; // null = すべて
  final String Function(DateTime month) toKey;
  final ValueChanged<String?> onSelected;

  const _MonthChips({
    required this.months,
    required this.selectedMonthKey,
    required this.toKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: months.length + 1, // ★先頭に「すべて」
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            final isSelected = selectedMonthKey == null;
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelected(null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : const Color(0xFFF2F3F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'すべて',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }

          final m = months[i - 1];
          final key = toKey(m.month);
          final isSelected = selectedMonthKey == key;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelected(key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  m.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SortDropDown extends StatelessWidget {
  final String label;
  final ValueChanged<String> onSelected;

  const _SortDropDown({required this.label, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '並び替え',
      onSelected: onSelected,
      itemBuilder: (_) => const [
        PopupMenuItem(value: '新着順', child: Text('新着順')),
        PopupMenuItem(value: '現在地から近い順', child: Text('現在地から近い順（UIのみ）')),
        PopupMenuItem(value: '金額が高い順', child: Text('金額が高い順（UIのみ）')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_vert, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _BadgeSpec {
  final String label;
  final Color bg;
  final Color fg;
  const _BadgeSpec({required this.label, required this.bg, required this.fg});
}

class _JobCard extends StatelessWidget {
  final String title;
  final String location;
  final String dateText;
  final String priceText;
  final List<_BadgeSpec> badges;
  final bool showLegacyWarning;

  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _JobCard({
    required this.title,
    required this.location,
    required this.dateText,
    required this.priceText,
    required this.badges,
    required this.showLegacyWarning,
    required this.isOwner,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E8EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF1F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo, color: Colors.black38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final b in badges)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: b.bg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              b.label,
                              style: TextStyle(
                                color: b.fg,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (showLegacyWarning)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'ownerIdなし',
                              style: TextStyle(
                                color: Color(0xFFE65100),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Colors.black45),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateText,
                            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (isOwner)
                    PopupMenuButton<String>(
                      tooltip: '操作',
                      onSelected: (v) {
                        if (v == 'edit') onEdit?.call();
                        if (v == 'delete') onDelete?.call();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('編集')),
                        PopupMenuItem(value: 'delete', child: Text('削除')),
                      ],
                      icon: const Icon(Icons.more_vert, color: Colors.black54),
                    )
                  else
                    const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
