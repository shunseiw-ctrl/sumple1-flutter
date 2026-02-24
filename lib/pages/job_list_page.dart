import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'job_detail_page.dart';
import 'job_edit_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/services/favorites_service.dart';

class JobListPage extends StatefulWidget {
  const JobListPage({super.key});

  @override
  State<JobListPage> createState() => _JobListPageState();
}

class _JobListPageState extends State<JobListPage> {
  String _selectedPref = '東京都';

  String? _selectedMonthKey;

  String _sortLabel = '新着順';

  final _favoritesService = FavoritesService();
  Set<String> _guestFavorites = {};

  RangeValues _priceRange = const RangeValues(0, 100000);
  String _areaFilter = '';
  Set<String> _qualFilter = {};
  String? _dateFromFilter;
  String? _dateToFilter;
  bool _hasActiveFilters = false;

  final List<String> _prefs = const [
    '千葉県',
    '東京都',
    '神奈川県',
    'その他',
  ];

  late final List<_MonthChip> _monthChips = _buildMonthChips();

  List<_MonthChip> _buildMonthChips() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    DateTime addMonths(DateTime base, int m) => DateTime(base.year, base.month + m);

    final list = <_MonthChip>[];
    list.add(_MonthChip(label: '今月', month: thisMonth));
    list.add(_MonthChip(label: '来月', month: addMonths(thisMonth, 1)));

    for (int i = 2; i <= 6; i++) {
      final m = addMonths(thisMonth, i);
      list.add(_MonthChip(label: '${m.month}月', month: m));
    }
    return list;
  }

  String _monthKey(DateTime month) {
    final y = month.year.toString();
    final m = month.month.toString().padLeft(2, '0');
    return '$y-$m';
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

  void _showFilterSheet() {
    var tempPrice = _priceRange;
    var tempArea = _areaFilter;
    var tempQuals = Set<String>.from(_qualFilter);
    var tempDateFrom = _dateFromFilter;
    var tempDateTo = _dateToFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (ctx, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textHint,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('絞り込み', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setLocal(() {
                                tempPrice = const RangeValues(0, 100000);
                                tempArea = '';
                                tempQuals = {};
                                tempDateFrom = null;
                                tempDateTo = null;
                              });
                            },
                            child: const Text('リセット'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text('エリア（市区町村）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: tempArea),
                        decoration: InputDecoration(
                          hintText: '例）渋谷区、横浜市',
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (v) => tempArea = v.trim(),
                      ),
                      const SizedBox(height: 20),

                      Text('金額範囲: ¥${tempPrice.start.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\$)'), (m) => '${m[1]},')} ~ ¥${tempPrice.end.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\$)'), (m) => '${m[1]},')}${tempPrice.end >= 100000 ? '+' : ''}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      RangeSlider(
                        values: tempPrice,
                        min: 0,
                        max: 100000,
                        divisions: 20,
                        activeColor: AppColors.ruri,
                        labels: RangeLabels(
                          '¥${tempPrice.start.toInt()}',
                          tempPrice.end >= 100000 ? '¥100,000+' : '¥${tempPrice.end.toInt()}',
                        ),
                        onChanged: (v) => setLocal(() => tempPrice = v),
                      ),
                      const SizedBox(height: 16),

                      const Text('必要資格', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: ['足場組立', '玉掛け', 'フォークリフト', '電気工事士', '溶接', '危険物取扱者', '土木施工管理', '建築施工管理'].map((q) {
                          final selected = tempQuals.contains(q);
                          return FilterChip(
                            label: Text(q),
                            selected: selected,
                            onSelected: (v) {
                              setLocal(() {
                                if (v) { tempQuals.add(q); } else { tempQuals.remove(q); }
                              });
                            },
                            selectedColor: AppColors.ruriPale,
                            checkmarkColor: AppColors.ruri,
                            labelStyle: TextStyle(
                              color: selected ? AppColors.ruri : AppColors.textPrimary,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      const Text('日付範囲', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setLocal(() => tempDateFrom = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Text(tempDateFrom ?? '開始日', style: TextStyle(color: tempDateFrom != null ? AppColors.textPrimary : AppColors.textHint)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('〜'),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setLocal(() => tempDateTo = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Text(tempDateTo ?? '終了日', style: TextStyle(color: tempDateTo != null ? AppColors.textPrimary : AppColors.textHint)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _priceRange = tempPrice;
                              _areaFilter = tempArea;
                              _qualFilter = tempQuals;
                              _dateFromFilter = tempDateFrom;
                              _dateToFilter = tempDateTo;
                              _hasActiveFilters = tempArea.isNotEmpty || tempQuals.isNotEmpty || tempDateFrom != null || tempDateTo != null || tempPrice.start > 0 || tempPrice.end < 100000;
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ruri,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('この条件で検索', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: _PrefChips(
              prefs: _prefs,
              selected: _selectedPref,
              onSelected: (p) => setState(() => _selectedPref = p),
            ),
          ),

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
                      onPressed: _showFilterSheet,
                      icon: Badge(
                        isLabelVisible: _hasActiveFilters,
                        smallSize: 8,
                        child: const Icon(Icons.tune, size: 18),
                      ),
                      label: const Text('絞り込み'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        backgroundColor: AppColors.chipUnselected,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<List<String>>(
              stream: _favoritesService.favoritesStream(),
              builder: (context, favSnap) {
                final firestoreFavs = favSnap.data ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream: (() {
                    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('jobs');

                    if (_selectedPref != 'その他') {
                      q = q.where('prefecture', isEqualTo: _selectedPref);
                    }

                    if (_selectedMonthKey != null) {
                      q = q.where('workMonthKey', isEqualTo: _selectedMonthKey);
                    }

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

                    const excludePrefs = {'千葉県', '東京都', '神奈川県'};

                    final docs = _selectedPref == 'その他'
                        ? rawDocs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final pref = data['prefecture']?.toString();

                      if (pref == null || pref.isEmpty || pref == '未設定') return true;
                      return !excludePrefs.contains(pref);
                    }).toList()
                        : rawDocs;

                    final filteredDocs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;

                      if (_areaFilter.isNotEmpty) {
                        final location = (data['location'] ?? '').toString().toLowerCase();
                        if (!location.contains(_areaFilter.toLowerCase())) return false;
                      }

                      if (_priceRange.start > 0 || _priceRange.end < 100000) {
                        final price = int.tryParse(data['price']?.toString() ?? '0') ?? 0;
                        if (price < _priceRange.start) return false;
                        if (_priceRange.end < 100000 && price > _priceRange.end) return false;
                      }

                      if (_dateFromFilter != null || _dateToFilter != null) {
                        final dateStr = (data['date'] ?? '').toString();
                        if (dateStr.isNotEmpty) {
                          if (_dateFromFilter != null && dateStr.compareTo(_dateFromFilter!) < 0) return false;
                          if (_dateToFilter != null && dateStr.compareTo(_dateToFilter!) > 0) return false;
                        }
                      }

                      return true;
                    }).toList();

                    if (_sortLabel == '金額が高い順') {
                      filteredDocs.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aPrice = int.tryParse(aData['price']?.toString() ?? '0') ?? 0;
                        final bPrice = int.tryParse(bData['price']?.toString() ?? '0') ?? 0;
                        return bPrice.compareTo(aPrice);
                      });
                    }

                    if (filteredDocs.isEmpty) {
                      return const _CenterMessage(text: '条件に一致する案件がありません');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final title = data['title']?.toString() ?? 'タイトルなし';
                        final location = data['location']?.toString() ?? '未設定';
                        final price = data['price']?.toString() ?? '0';
                        final date = data['date']?.toString() ?? '未設定';
                        final imageUrl = data['imageUrl']?.toString();
                        final category = data['category']?.toString();

                        final ownerId = data['ownerId']?.toString();
                        final isOwner = currentUser != null &&
                            ownerId != null &&
                            ownerId.isNotEmpty &&
                            ownerId == currentUser.uid;

                        final hasOwnerId = ownerId != null && ownerId.isNotEmpty;

                        final badges = <_BadgeSpec>[];

                        final isFav = _favoritesService.isRegistered
                            ? firestoreFavs.contains(doc.id)
                            : _guestFavorites.contains(doc.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _JobCard(
                            title: title,
                            location: location,
                            dateText: date,
                            priceText: '¥$price',
                            imageUrl: imageUrl,
                            category: category,
                            badges: badges,
                            showLegacyWarning: !hasOwnerId,
                            isOwner: isOwner,
                            isFavorite: isFav,
                            onToggleFavorite: () {
                              if (_favoritesService.isRegistered) {
                                _favoritesService.toggleFavorite(doc.id);
                              } else {
                                setState(() {
                                  if (_guestFavorites.contains(doc.id)) {
                                    _guestFavorites.remove(doc.id);
                                  } else {
                                    _guestFavorites.add(doc.id);
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('登録するとお気に入りが保存されます'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
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
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final pref = _selectedPref == 'その他' ? '日本' : _selectedPref;

          final month = _selectedMonthKey;
          final query = (month == null) ? pref : '$pref $month';

          _openMapByQuery(query);
        },
        backgroundColor: AppColors.ruri,
        icon: const Icon(Icons.map_outlined, color: Colors.white),
        label: const Text('地図で見る', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

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
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
              color: isSelected ? AppColors.chipTextSelected : AppColors.chipTextUnselected,
            ),
            selectedColor: AppColors.chipSelected,
            backgroundColor: AppColors.chipUnselected,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }
}

class _MonthChip {
  final String label;
  final DateTime month;
  const _MonthChip({required this.label, required this.month});
}

class _MonthChips extends StatelessWidget {
  final List<_MonthChip> months;
  final String? selectedMonthKey;
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
        itemCount: months.length + 1,
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
                  color: isSelected ? AppColors.chipSelected : AppColors.chipUnselected,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'すべて',
                    style: TextStyle(
                      color: isSelected ? AppColors.chipTextSelected : AppColors.chipTextUnselected,
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
                color: isSelected ? AppColors.chipSelected : AppColors.chipUnselected,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  m.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.chipTextSelected : AppColors.chipTextUnselected,
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
          color: AppColors.chipUnselected,
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
  final String? imageUrl;
  final String? category;
  final List<_BadgeSpec> badges;
  final bool showLegacyWarning;

  final bool isOwner;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;

  const _JobCard({
    required this.title,
    required this.location,
    required this.dateText,
    required this.priceText,
    this.imageUrl,
    this.category,
    required this.badges,
    required this.showLegacyWarning,
    required this.isOwner,
    this.isFavorite = false,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onToggleFavorite,
  });

  IconData _categoryIcon(String? cat) {
    switch (cat) {
      case '解体':
        return Icons.handyman;
      case '内装':
        return Icons.format_paint;
      case '外壁':
        return Icons.home_work;
      case '電気':
        return Icons.electrical_services;
      case '配管':
        return Icons.plumbing;
      case '土木':
        return Icons.landscape;
      case '塗装':
        return Icons.brush;
      default:
        return Icons.construction;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImage(),
                      )
                    else
                      _placeholderImage(),

                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.ruri,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          priceText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: onToggleFavorite,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    if (isOwner)
                      Positioned(
                        top: 8,
                        left: 48,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          child: PopupMenuButton<String>(
                            tooltip: '操作',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            iconSize: 20,
                            onSelected: (v) {
                              if (v == 'edit') onEdit?.call();
                              if (v == 'delete') onDelete?.call();
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('編集')),
                              PopupMenuItem(value: 'delete', child: Text('削除')),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badges.isNotEmpty || showLegacyWarning) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final b in badges)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: b.bg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                b.label,
                                style: TextStyle(
                                  color: b.fg,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (showLegacyWarning)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ownerIdなし',
                                style: TextStyle(
                                  color: Color(0xFFE65100),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 15, color: AppColors.ruri),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            dateText,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppColors.ruriPale,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcon(category),
              size: 40,
              color: AppColors.ruri.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 4),
            Text(
              category ?? '建設',
              style: TextStyle(
                color: AppColors.ruri.withValues(alpha: 0.45),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
