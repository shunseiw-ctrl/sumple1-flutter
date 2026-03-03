import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sumple1/core/router/route_paths.dart';
import 'package:sumple1/core/utils/haptic_utils.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
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
  String _selectedPref = 'tokyo';

  String? _selectedMonthKey;

  String _sortKey = 'newest';

  final _favoritesService = FavoritesService();
  final _distanceSortService = DistanceSortService();
  final Set<String> _guestFavorites = {};

  Key _refreshKey = UniqueKey();

  JobFilterState _filterState = const JobFilterState();

  List<JobWithDistance>? _sortedByDistance;
  bool _loadingLocation = false;

  static const List<String> _prefKeys = [
    'chiba',
    'tokyo',
    'kanagawa',
    'other',
  ];

  static const Map<String, String> _prefValues = {
    'chiba': '千葉県',
    'tokyo': '東京都',
    'kanagawa': '神奈川県',
    'other': 'その他',
  };

  static String _prefLabel(BuildContext context, String key) {
    switch (key) {
      case 'chiba': return context.l10n.jobList_prefChiba;
      case 'tokyo': return context.l10n.jobList_prefTokyo;
      case 'kanagawa': return context.l10n.jobList_prefKanagawa;
      case 'other': return context.l10n.jobList_prefOther;
      default: return key;
    }
  }

  String get _selectedPrefValue => _prefValues[_selectedPref] ?? _selectedPref;

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
    list.add(_MonthChip(labelKey: 'thisMonth', month: thisMonth));
    list.add(_MonthChip(labelKey: 'nextMonth', month: addMonths(thisMonth, 1)));

    for (int i = 2; i <= 6; i++) {
      final m = addMonths(thisMonth, i);
      list.add(_MonthChip(labelKey: 'month_${m.month}', month: m));
    }
    return list;
  }

  String _monthKey(DateTime month) {
    final y = month.year.toString();
    final m = month.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  String _sortLabel(BuildContext context) {
    switch (_sortKey) {
      case 'newest': return context.l10n.jobList_sortNewest;
      case 'distance': return context.l10n.jobList_sortDistance;
      case 'highestPay': return context.l10n.jobList_sortHighestPay;
      default: return context.l10n.jobList_sortNewest;
    }
  }

  void _onSortSelected(String value) {
    if (value == 'distance') {
      _loadDistanceSort();
    } else {
      setState(() {
        _sortKey = value;
        _sortedByDistance = null;
      });
    }
  }

  Future<void> _loadDistanceSort() async {
    if (_loadingLocation) return;
    setState(() {
      _loadingLocation = true;
      _sortKey = 'distance';
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
        _sortKey = 'newest';
        _sortedByDistance = null;
        _loadingLocation = false;
      });
    } catch (e) {
      Logger.error('Failed to load distance sort', tag: 'JobListPage', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.jobList_locationError)),
      );
      setState(() {
        _sortKey = 'newest';
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
        SnackBar(content: Text(context.l10n.jobList_fetchJobsError)),
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
      backgroundColor: context.appColors.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.md, AppSpacing.pagePadding, AppSpacing.sm),
            color: context.appColors.surface,
            child: Semantics(
              button: true,
              label: context.l10n.jobList_openSearchFilter,
              child: GestureDetector(
                onTap: _showFilterSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.appColors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: context.appColors.textHint, size: 20),
                      const SizedBox(width: 12),
                      Text(context.l10n.jobList_searchByAreaCondition, style: AppTextStyles.bodyMedium.copyWith(color: context.appColors.textHint)),
                      const Spacer(),
                      Icon(Icons.tune_rounded, color: context.appColors.textSecondary, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surface,
              boxShadow: AppShadows.subtle,
            ),
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.sm),
            child: Column(
              children: [
                _PrefChips(
                  prefKeys: _prefKeys,
                  labelBuilder: (key) => _prefLabel(context, key),
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
                      label: _sortLabel(context),
                      onSelected: (value) => _onSortSelected(value),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: _filterState.hasActiveFilters ? context.l10n.jobList_filterActiveLabel : context.l10n.jobList_filter,
                      child: GestureDetector(
                        onTap: _showFilterSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm + 2),
                          decoration: BoxDecoration(
                            color: _filterState.hasActiveFilters ? context.appColors.primaryPale : context.appColors.chipUnselected,
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                            border: _filterState.hasActiveFilters ? Border.all(color: context.appColors.primary.withValues(alpha: 0.3), width: 1) : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 18, color: _filterState.hasActiveFilters ? context.appColors.primary : context.appColors.textSecondary),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                context.l10n.jobList_filter,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: _filterState.hasActiveFilters ? context.appColors.primary : context.appColors.textPrimary,
                                ),
                              ),
                              if (_filterState.hasActiveFilters) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: context.appColors.primary,
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

                    if (_selectedPref != 'other') {
                      q = q.where('prefecture', isEqualTo: _selectedPrefValue);
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
                        message: context.l10n.jobList_dataLoadError,
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonList();
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return EmptyState(
                        icon: Icons.work_off_outlined,
                        title: context.l10n.jobList_noJobs,
                        description: context.l10n.jobList_noJobsDescription,
                        imagePath: 'assets/images/empty_jobs.png',
                      );
                    }

                    final rawDocs = snapshot.data!.docs;

                    const excludePrefs = {'千葉県', '東京都', '神奈川県'};

                    final docs = _selectedPref == 'other'
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

                    if (_sortKey == 'highestPay') {
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
                    if (_sortKey == 'distance' && _sortedByDistance != null) {
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
                      return EmptyState(
                        icon: Icons.search_off_rounded,
                        title: context.l10n.jobList_noMatchingJobs,
                        description: context.l10n.jobList_noMatchingJobsDescription,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() => _refreshKey = UniqueKey());
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      color: context.appColors.primary,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        cacheExtent: AppConstants.listCacheExtent,
                        padding: AppSpacing.listInsets,
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final title = data['title']?.toString() ?? context.l10n.common_noTitle;
                          final location = data['location']?.toString() ?? context.l10n.common_notSet;
                          final price = data['price']?.toString() ?? '0';
                          final date = data['date']?.toString() ?? context.l10n.common_notSet;
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
                                    SnackBar(
                                      content: Text(context.l10n.common_registerToSaveFavorites),
                                      duration: const Duration(seconds: 2),
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
        label: context.l10n.jobList_viewOnMapAccessibility,
        child: Container(
          decoration: BoxDecoration(
            gradient: context.appColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            boxShadow: AppShadows.button,
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _openMapSearch(),
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            label: Text(context.l10n.jobList_viewOnMap, style: AppTextStyles.buttonSmall.copyWith(color: Colors.white)),
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
        title: Text(context.l10n.jobList_deleteConfirmTitle, style: AppTextStyles.headingSmall),
        content: Text(context.l10n.jobList_deleteConfirmMessage, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.common_cancel, style: AppTextStyles.labelMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.common_delete, style: AppTextStyles.labelMedium.copyWith(color: context.appColors.error)),
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
      SnackBar(content: Text(context.l10n.common_deleted)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${context.l10n.jobList_deleteError}: $e')),
    );
  }
}

class _PrefChips extends StatelessWidget {
  final List<String> prefKeys;
  final String Function(String key) labelBuilder;
  final String selected;
  final ValueChanged<String> onSelected;

  const _PrefChips({
    required this.prefKeys,
    required this.labelBuilder,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: prefKeys.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final key = prefKeys[i];
          final label = labelBuilder(key);
          final isSelected = key == selected;
          return Semantics(
            button: true,
            label: '$label${isSelected ? context.l10n.common_selected : ""}',
            selected: isSelected,
            child: GestureDetector(
              onTap: () => onSelected(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? context.appColors.primary : context.appColors.chipUnselected,
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: AppTextStyles.chipText.copyWith(
                      color: isSelected ? Colors.white : context.appColors.chipTextUnselected,
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
  final String labelKey;
  final DateTime month;
  const _MonthChip({required this.labelKey, required this.month});

  String localizedLabel(BuildContext context) {
    switch (labelKey) {
      case 'thisMonth': return context.l10n.jobList_thisMonth;
      case 'nextMonth': return context.l10n.jobList_nextMonth;
      default:
        if (labelKey.startsWith('month_')) {
          final monthNum = labelKey.replaceFirst('month_', '');
          // TODO: i18n - jobList_monthLabel should be "{month}月" pattern
          return '$monthNum月';
        }
        return labelKey;
    }
  }
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
                  color: isSelected ? context.appColors.primary : context.appColors.chipUnselected,
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Center(
                  child: Text(
                    context.l10n.common_all,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 12,
                      color: isSelected ? Colors.white : context.appColors.chipTextUnselected,
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
                color: isSelected ? context.appColors.primary : context.appColors.chipUnselected,
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
              child: Center(
                child: Text(
                  m.localizedLabel(context),
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 12,
                    color: isSelected ? Colors.white : context.appColors.chipTextUnselected,
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
      tooltip: context.l10n.jobList_sortTooltip,
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.inputRadius)),
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'newest', child: Text(ctx.l10n.jobList_sortNewest, style: AppTextStyles.bodyMedium)),
        PopupMenuItem(value: 'distance', child: Text(ctx.l10n.jobList_sortDistance, style: AppTextStyles.bodyMedium)),
        PopupMenuItem(value: 'highestPay', child: Text(ctx.l10n.jobList_sortHighestPay, style: AppTextStyles.bodyMedium)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: context.appColors.chipUnselected,
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 18, color: context.appColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTextStyles.labelMedium.copyWith(color: context.appColors.textPrimary)),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.arrow_drop_down_rounded, size: 20, color: context.appColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
