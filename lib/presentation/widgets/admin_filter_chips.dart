import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_colors.dart';

/// 汎用フィルタチップ行
class AdminFilterChips extends StatelessWidget {
  final String selectedKey;
  final Map<String, String> options;
  final ValueChanged<String> onSelected;

  const AdminFilterChips({
    super.key,
    required this.selectedKey,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.entries.map((entry) {
            final isSelected = selectedKey == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (_) => onSelected(entry.key),
                selectedColor: AppColors.ruri,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
                backgroundColor: AppColors.chipUnselected,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                side: BorderSide.none,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
