import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';
import 'package:sumple1/core/constants/app_text_styles.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/constants/app_shadows.dart';

/// Immutable data class representing the state of the job filter sheet.
class JobFilterState {
  final RangeValues priceRange;
  final String areaFilter;
  final Set<String> qualFilter;
  final String? dateFromFilter;
  final String? dateToFilter;

  const JobFilterState({
    this.priceRange = const RangeValues(0, 100000),
    this.areaFilter = '',
    this.qualFilter = const {},
    this.dateFromFilter,
    this.dateToFilter,
  });

  /// Whether any filter is active (i.e. differs from defaults).
  bool get hasActiveFilters =>
      areaFilter.isNotEmpty ||
      qualFilter.isNotEmpty ||
      dateFromFilter != null ||
      dateToFilter != null ||
      priceRange.start > 0 ||
      priceRange.end < 100000;

  /// Returns a new [JobFilterState] with all filters reset to defaults.
  JobFilterState reset() => const JobFilterState();

  /// Creates a copy with the given fields replaced.
  JobFilterState copyWith({
    RangeValues? priceRange,
    String? areaFilter,
    Set<String>? qualFilter,
    String? dateFromFilter,
    String? dateToFilter,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return JobFilterState(
      priceRange: priceRange ?? this.priceRange,
      areaFilter: areaFilter ?? this.areaFilter,
      qualFilter: qualFilter ?? this.qualFilter,
      dateFromFilter: clearDateFrom ? null : (dateFromFilter ?? this.dateFromFilter),
      dateToFilter: clearDateTo ? null : (dateToFilter ?? this.dateToFilter),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobFilterState &&
          runtimeType == other.runtimeType &&
          priceRange == other.priceRange &&
          areaFilter == other.areaFilter &&
          qualFilter.length == other.qualFilter.length &&
          qualFilter.containsAll(other.qualFilter) &&
          dateFromFilter == other.dateFromFilter &&
          dateToFilter == other.dateToFilter;

  @override
  int get hashCode => Object.hash(
        priceRange,
        areaFilter,
        Object.hashAll(qualFilter.toList()..sort()),
        dateFromFilter,
        dateToFilter,
      );
}

/// Available qualification filter options.
const List<String> qualificationOptions = [
  '足場組立',
  '玉掛け',
  'フォークリフト',
  '電気工事士',
  '溶接',
  '危険物取扱者',
  '土木施工管理',
  '建築施工管理',
];

/// Shows the job filter bottom sheet.
///
/// Returns the selected [JobFilterState] or `null` if the user dismisses
/// the sheet without applying.
Future<JobFilterState?> showJobFilterSheet(
  BuildContext context, {
  required JobFilterState current,
}) {
  JobFilterState? result;

  return showModalBottomSheet<JobFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      var tempPrice = current.priceRange;
      var tempArea = current.areaFilter;
      var tempQuals = Set<String>.from(current.qualFilter);
      var tempDateFrom = current.dateFromFilter;
      var tempDateTo = current.dateToFilter;

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
                        children: qualificationOptions.map((q) {
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
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.ruri),
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
                                    const Icon(Icons.calendar_today, size: 16, color: AppColors.ruri),
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
                            result = JobFilterState(
                              priceRange: tempPrice,
                              areaFilter: tempArea,
                              qualFilter: tempQuals,
                              dateFromFilter: tempDateFrom,
                              dateToFilter: tempDateTo,
                            );
                            Navigator.pop(ctx, result);
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
