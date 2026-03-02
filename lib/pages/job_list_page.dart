import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_constants.dart';
import 'package:sumple1/core/constants/app_shadows.dart';
import 'package:sumple1/core/services/distance_sort_service.dart';
import 'package:sumple1/core/services/favorites_service.dart';
import 'package:sumple1/core/services/location_service.dart';
import 'package:sumple1/core/utils/logger.dart';
import 'package:sumple1/presentation/widgets/skeleton_loader.dart';
import 'package:sumple1/presentation/widgets/empty_state.dart';
import 'package:sumple1/presentation/widgets/staggered_animation.dart';
import 'package:sumple1/presentation/widgets/error_retry_widget.dart';
import 'package:sumple1/core/services/analytics_service.dart';
import 'package:sumple1/presentation/widgets/job_card.dart';
import 'package:sumple1/pages/job_filter_sheet.dart';

class JobListPage extends ConsumerStatefulWidget {
  const JobListPage({super.key});

  @override
  ConsumerState<JobListPage> createState() => _JobListPageState();
}

class _JobListPageState extends ConsumerState<JobListPage> {
  String _selectedPref = '東京都';

  String? _selectedMonthKey;

  String _sortLabel = '新着順';

  final _favoritesService = FavoritesService();
  final _distanceSortService = DistanceSortService();
  final Set<String> _guestFavorites = {};

  Key _refreshKey = UniqueKey();

  JobFilterState _filterState = const JobFilterState();

  List<JobWithDistance>? _sortedByDistance;
  bool _loadingLocation = false;

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

  void _onSortSelected(String value) {
    if (value == '距離順') {
      _loadDistanceSort();
    } else {
      setState(() {
        _sortLabel = value;
        _sortedByDistance = null;
      });
    }
  }

  Future<void> _loadDistanceSort() async {
    if (_loadingLocation) return;
    setState(() {
      _loadingLocation = true;
      _sortLabel = '距離順';
    });

    try {
      final pos = await _distanceSortService.getCurrentPosition();

      // 現在のFirestoreデータから距離を計算
      final snapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final jobMaps = snapshot.docs.map((d) => {
        'data': d.data(),
        'docId': d.id,
      }).toList();

      final withDistance = _distanceSortService.calculateDistances(
        jobMaps,
        pos.lat,
        pos.lng,
      );
      final sorted = _distanceSortService.sortByDistance(withDistance);

      if (!mounted) return;
      setState(() {
        _sortedByDistance = sorted;
        _loadingLocation = false;
      });
    } on LocationException catch (e) {
      Logger.warning('Location permission denied', tag: 'JobListPage', data: {'error': e.message});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      setState(() {
        _sortLabel = '新着順';
        _sortedByDistance = null;
        _loadingLocation = false;
      });
    } catch (e) {
      Logger.error('Failed to load distance sort', tag: 'JobListPage', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('位置情報の取得に失敗しました')),
      );
      setState(() {
        _sortLabel = '新着順';
        _sortedByDistance = null;
        _loadingLocation = false;
      });
    }
  }

  void _openMapSearch() {
    // 現在のFirestoreから最新のjobsを取得してMapSearchPageへ渡す
    FirebaseFirestore.instance
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get()
        .then((snapshot) {
      if (!mounted) return;
      final jobMaps = snapshot.docs.map((d) => <String, dynamic>{
        'data': d.data(),
        'docId': d.id,
      }).toList();
      context.push(RoutePaths.mapSearch, extra: jobMaps);
    }).catchError((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('案件データの取得に失敗しました')),
      );
    });
  }

  Future<void> _showFilterSheet() async {
    final result = await showJobFilterSheet(
      context,
      current: _filterState,
    );
    if (result != null) {
      setState(() {
        _filterState = result;
      });
    }
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
            child: Semantics(
              button: true,
              label: '検索フィルターを開く',
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
                  onSelected: (p) {
                    AppHaptics.selection();
                    setState(() => _selectedPref = p);
                  },
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
                      onSelected: (value) => _onSortSelected(value),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: _filterState.hasActiveFilters ? '絞り込み、フィルター適用中' : '絞り込み',
                      child: GestureDetector(
                        onTap: _showFilterSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm + 2),
                          decoration: BoxDecoration(
                            color: _filterState.hasActiveFilters ? AppColors.ruriPale : AppColors.chipUnselected,
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                            border: _filterState.hasActiveFilters ? Border.all(color: AppColors.ruri.withValues(alpha: 0.3), width: 1) : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 18, color: _filterState.hasActiveFilters ? AppColors.ruri : AppColors.textSecondary),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '絞り込み',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: _filterState.hasActiveFilters ? AppColors.ruri : AppColors.textPrimary,
                                ),
                              ),
                              if (_filterState.hasActiveFilters) ...[
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
                  key: _refreshKey,
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

                      if (_filterState.areaFilter.isNotEmpty) {
                        final location = (data['location'] ?? '').toString().toLowerCase();
                        if (!location.contains(_filterState.areaFilter.toLowerCase())) return false;
                      }

                      if (_filterState.priceRange.start > 0 || _filterState.priceRange.end < 100000) {
                        final price = int.tryParse(data['price']?.toString() ?? '0') ?? 0;
                        if (price < _filterState.priceRange.start) return false;
                        if (_filterState.priceRange.end < 100000 && price > _filterState.priceRange.end) return false;
                      }

                      if (_filterState.dateFromFilter != null || _filterState.dateToFilter != null) {
                        final dateStr = (data['date'] ?? '').toString();
                        if (dateStr.isNotEmpty) {
                          if (_filterState.dateFromFilter != null && dateStr.compareTo(_filterState.dateFromFilter!) < 0) return false;
                          if (_filterState.dateToFilter != null && dateStr.compareTo(_filterState.dateToFilter!) > 0) return false;
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

                    // 距離ソート結果のマップ（docId → distanceLabel）
                    final distanceLabels = <String, String>{};
                    if (_sortLabel == '距離順' && _sortedByDistance != null) {
                      for (final jwd in _sortedByDistance!) {
                        if (jwd.distanceLabel != null) {
                          distanceLabels[jwd.docId] = jwd.distanceLabel!;
                        }
                      }
                      // 距離ソート順にfilteredDocsを並べ替え
                      final orderMap = <String, int>{};
                      for (int i = 0; i < _sortedByDistance!.length; i++) {
                        orderMap[_sortedByDistance![i].docId] = i;
                      }
                      filteredDocs.sort((a, b) {
                        final aIdx = orderMap[a.id] ?? 99999;
                        final bIdx = orderMap[b.id] ?? 99999;
                        return aIdx.compareTo(bIdx);
                      });
                    }

                    if (filteredDocs.isEmpty) {
                      return const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: '条件に一致する案件がありません',
                        description: 'フィルターを変更するか、\n別の条件で検索してみてください。',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() => _refreshKey = UniqueKey());
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      color: AppColors.ruri,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        cacheExtent: AppConstants.listCacheExtent,
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

                          final badges = <BadgeSpec>[];

                          final isFav = _favoritesService.isRegistered
                              ? firestoreFavs.contains(doc.id)
                              : _guestFavorites.contains(doc.id);

                          return StaggeredFadeSlide(
                            index: index,
                            child: Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.base),
                            child: JobCard(
                              title: title,
                              location: location,
                              dateText: date,
                              priceText: '¥$price',
                              imageUrl: imageUrl,
                              heroTag: imageUrl != null ? 'hero-job-image-${doc.id}' : null,
                              category: category,
                              badges: badges,
                              showLegacyWarning: !hasOwnerId,
                              data: data,
                              isOwner: isOwner,
                              isFavorite: isFav,
                              distanceLabel: distanceLabels[doc.id],
                              onToggleFavorite: () {
                                AppHaptics.tap();
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
                                context.push(RoutePaths.jobDetailPath(doc.id), extra: data);
                              },
                              onEdit: isOwner
                                  ? () {
                                context.push(RoutePaths.jobEditPath(doc.id), extra: data);
                              }
                                  : null,
                              onDelete: isOwner ? () => _showDeleteDialog(context, doc.id) : null,
                            ),
                          ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: Semantics(
        button: true,
        label: '地図で現場を確認する',
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            boxShadow: AppShadows.button,
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _openMapSearch(),
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            label: Text('地図で見る', style: AppTextStyles.buttonSmall.copyWith(color: Colors.white)),
          ),
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
          return Semantics(
            button: true,
            label: '$p${isSelected ? "、選択中" : ""}',
            selected: isSelected,
            child: GestureDetector(
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
        PopupMenuItem(value: '距離順', child: Text('距離順', style: AppTextStyles.bodyMedium)),
        PopupMenuItem(value: '金額が高い順', child: Text('金額が高い順', style: AppTextStyles.bodyMedium)),
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
