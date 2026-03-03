import 'package:flutter/material.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';

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
      color: context.appColors.surface,
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
                selectedColor: context.appColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : context.appColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
                backgroundColor: context.appColors.chipUnselected,
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
