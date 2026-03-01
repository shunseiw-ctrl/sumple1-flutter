import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'job_detail_page.dart';
import 'job_edit_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/core/services/favorites_service.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/staggered_animation.dart';
import 'package:sumple1/presentation/widgets/scale_tap.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';
import 'package:sumple1/core/services/analytics_service.dart';

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

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('job_list');
  }

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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadiusLg)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.75,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                expand: false,
                builder: (ctx, scrollController) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.md, AppSpacing.pagePadding, AppSpacing.pagePadding),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        Row(
                          children: [
                            Text('絞り込み', style: AppTextStyles.headingMedium),
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
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.ruri,
                              ),
                              child: Text('リセット', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ruri)),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        Text('エリア（市区町村）', style: AppTextStyles.labelLarge),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: TextEditingController(text: tempArea),
                          decoration: InputDecoration(
                            hintText: '例）渋谷区、横浜市',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.ruri),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                              borderSide: const BorderSide(color: AppColors.ruri, width: 1.5),
                            ),
                          ),
                          onChanged: (v) => tempArea = v.trim(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        Text('金額範囲: ¥${tempPrice.start.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\$)'), (m) => '${m[1]},')} ~ ¥${tempPrice.end.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\$)'), (m) => '${m[1]},')}${tempPrice.end >= 100000 ? '+' : ''}',
                          style: AppTextStyles.labelLarge),
                        RangeSlider(
                          values: tempPrice,
                          min: 0,
                          max: 100000,
                          divisions: 20,
                          activeColor: AppColors.ruri,
                          inactiveColor: AppColors.ruriPale,
                          labels: RangeLabels(
                            '¥${tempPrice.start.toInt()}',
                            tempPrice.end >= 100000 ? '¥100,000+' : '¥${tempPrice.end.toInt()}',
                          ),
                          onChanged: (v) => setLocal(() => tempPrice = v),
                        ),
                        const SizedBox(height: AppSpacing.base),

                        Text('必要資格', style: AppTextStyles.labelLarge),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
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
                              backgroundColor: AppColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                                side: BorderSide(
                                  color: selected ? AppColors.ruri : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              labelStyle: AppTextStyles.chipText.copyWith(
                                color: selected ? AppColors.ruri : AppColors.textPrimary,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        Text('日付範囲', style: AppTextStyles.labelLarge),
                        const SizedBox(height: AppSpacing.sm),
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
                                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: AppColors.ruri),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(tempDateFrom ?? '開始日', style: AppTextStyles.bodyMedium.copyWith(color: tempDateFrom != null ? AppColors.textPrimary : AppColors.textHint)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              child: Text('〜', style: AppTextStyles.bodyMedium),
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
                                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: AppColors.ruri),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(tempDateTo ?? '終了日', style: AppTextStyles.bodyMedium.copyWith(color: tempDateTo != null ? AppColors.textPrimary : AppColors.textHint)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            boxShadow: AppShadows.button,
                          ),
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
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
                            ),
                            child: Text('この条件で検索', style: AppTextStyles.button.copyWith(color: Colors.white)),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.md, AppSpacing.pagePadding, AppSpacing.sm),
            color: Colors.white,
            child: GestureDetector(
              onTap: _showFilterSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textHint, size: 20),
                    const SizedBox(width: 12),
                    Text('エリア・条件で検索', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                    const Spacer(),
                    const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppShadows.subtle,
            ),
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.sm),
            child: Column(
              children: [
                _PrefChips(
                  prefs: _prefs,
                  selected: _selectedPref,
                  onSelected: (p) => setState(() => _selectedPref = p),
                ),
                const SizedBox(height: AppSpacing.md),
                _MonthChips(
                  months: _monthChips,
                  selectedMonthKey: _selectedMonthKey,
                  toKey: _monthKey,
                  onSelected: (monthKeyOrNull) {
                    setState(() => _selectedMonthKey = monthKeyOrNull);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _SortDropDown(
                      label: _sortLabel,
                      onSelected: (value) => setState(() => _sortLabel = value),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _showFilterSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm + 2),
                        decoration: BoxDecoration(
                          color: _hasActiveFilters ? AppColors.ruriPale : AppColors.chipUnselected,
                          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                          border: _hasActiveFilters ? Border.all(color: AppColors.ruri.withOpacity(0.3), width: 1) : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 18, color: _hasActiveFilters ? AppColors.ruri : AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '絞り込み',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _hasActiveFilters ? AppColors.ruri : AppColors.textPrimary,
                              ),
                            ),
                            if (_hasActiveFilters) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.ruri,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

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

                    q = q.orderBy('createdAt', descending: true).limit(100);

                    return q.snapshots();
                  })(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      final errStr = '${snapshot.error}';
                      if (errStr.contains('network') || errStr.contains('unavailable')) {
                        return ErrorRetryWidget.network(
                          onRetry: () => setState(() {}),
                        );
                      }
                      return ErrorRetryWidget.general(
                        onRetry: () => setState(() {}),
                        message: 'データの読み込みに失敗しました\nしばらく経ってからお試しください',
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonList();
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const EmptyState(
                        icon: Icons.work_off_outlined,
                        title: '案件がありません',
                        description: '現在この条件に合う案件はありません。\n別の条件で検索してみてください。',
                        imagePath: 'assets/images/empty_jobs.png',
                      );
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
                      return const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: '条件に一致する案件がありません',
                        description: 'フィルターを変更するか、\n別の条件で検索してみてください。',
                      );
                    }

                    return ListView.builder(
                      padding: AppSpacing.listInsets,
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

                        return StaggeredFadeSlide(
                          index: index,
                          child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.base),
                          child: _JobCard(
                            title: title,
                            location: location,
                            dateText: date,
                            priceText: '¥$price',
                            imageUrl: imageUrl,
                            category: category,
                            badges: badges,
                            showLegacyWarning: !hasOwnerId,
                            data: data,
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

      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          boxShadow: AppShadows.button,
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            final pref = _selectedPref == 'その他' ? '日本' : _selectedPref;

            final month = _selectedMonthKey;
            final query = (month == null) ? pref : '$pref $month';

            _openMapByQuery(query);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.map_outlined, color: Colors.white),
          label: Text('地図で見る', style: AppTextStyles.buttonSmall.copyWith(color: Colors.white)),
        ),
      ),
    );
  }
}

Future<void> _showDeleteDialog(BuildContext context, String jobId) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        title: Text('削除確認', style: AppTextStyles.headingSmall),
        content: Text('この案件を削除してもよろしいですか？', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル', style: AppTextStyles.labelMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('削除', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
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
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: prefs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final p = prefs[i];
          final isSelected = p == selected;
          return GestureDetector(
            onTap: () => onSelected(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.ruri : AppColors.chipUnselected,
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Center(
                child: Text(
                  p,
                  style: AppTextStyles.chipText.copyWith(
                    color: isSelected ? Colors.white : AppColors.chipTextUnselected,
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
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: months.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          if (i == 0) {
            final isSelected = selectedMonthKey == null;
            return GestureDetector(
              onTap: () => onSelected(null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ruri : AppColors.chipUnselected,
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Center(
                  child: Text(
                    'すべて',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppColors.chipTextUnselected,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }

          final m = months[i - 1];
          final key = toKey(m.month);
          final isSelected = selectedMonthKey == key;

          return GestureDetector(
            onTap: () => onSelected(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.ruri : AppColors.chipUnselected,
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Center(
                child: Text(
                  m.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.chipTextUnselected,
                    fontWeight: FontWeight.w600,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.inputRadius)),
      itemBuilder: (_) => [
        PopupMenuItem(value: '新着順', child: Text('新着順', style: AppTextStyles.bodyMedium)),
        PopupMenuItem(value: '現在地から近い順', child: Text('現在地から近い順（UIのみ）', style: AppTextStyles.bodyMedium)),
        PopupMenuItem(value: '金額が高い順', child: Text('金額が高い順（UIのみ）', style: AppTextStyles.bodyMedium)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: AppColors.chipUnselected,
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary)),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.arrow_drop_down_rounded, size: 20, color: AppColors.textSecondary),
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
  final Map<String, dynamic> data;

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
    required this.data,
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

    return ScaleTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
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
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (category != null && category!.isNotEmpty)
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_categoryIcon(category), size: 14, color: AppColors.ruri),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              category!,
                              style: AppTextStyles.badgeText.copyWith(color: AppColors.ruri),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: GestureDetector(
                      onTap: onToggleFavorite,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.subtle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavorite ? AppColors.error : AppColors.textHint,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  if (isOwner)
                    Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md + 44,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.subtle,
                        ),
                        child: PopupMenuButton<String>(
                          tooltip: '操作',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                          iconSize: 20,
                          icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary, size: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.inputRadius)),
                          onSelected: (v) {
                            if (v == 'edit') onEdit?.call();
                            if (v == 'delete') onDelete?.call();
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'edit', child: Text('編集', style: AppTextStyles.bodyMedium)),
                            PopupMenuItem(value: 'delete', child: Text('削除', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
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
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: b.bg,
                              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                            ),
                            child: Text(
                              b.label,
                              style: AppTextStyles.badgeText.copyWith(color: b.fg),
                            ),
                          ),
                        if (showLegacyWarning)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.warningLight,
                              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                            ),
                            child: Text(
                              'ownerIdなし',
                              style: AppTextStyles.badgeText.copyWith(color: const Color(0xFFE65100)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Builder(
                    builder: (context) {
                      final totalSlots = int.tryParse((data['slots'] ?? '5').toString()) ?? 5;
                      final applicantCount = int.tryParse((data['applicantCount'] ?? '0').toString()) ?? 0;
                      final remaining = (totalSlots - applicantCount).clamp(1, totalSlots);
                      final isUrgent = remaining <= 2;
                      final dateDiff = DateTime.tryParse(data['date'] ?? '')?.difference(DateTime.now()).inDays ?? 999;
                      final showQuickStart = (data['quickStart'] ?? false) == true || dateDiff.abs() <= 3;

                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUrgent ? AppColors.errorLight : AppColors.warningLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUrgent ? Icons.local_fire_department : Icons.people_outline,
                                  size: 12,
                                  color: isUrgent ? AppColors.error : AppColors.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '残り${remaining}枠',
                                  style: AppTextStyles.badgeText.copyWith(
                                    color: isUrgent ? AppColors.error : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (showQuickStart)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '即日勤務OK',
                                style: AppTextStyles.badgeText.copyWith(color: AppColors.success),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        priceText,
                        style: AppTextStyles.salary,
                      ),
                      Text(' /日', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: AppColors.ruri),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          location,
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textHint),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        dateText,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.ruriPale, Color(0xFFE0E7F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(category),
          size: 48,
          color: AppColors.ruri.withOpacity(0.3),
        ),
      ),
    );
  }
}
