import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/core/utils/debouncer.dart';

/// 管理者検索バー（Debounce付き）
class AdminSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const AdminSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = '',
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debouncer.run(() => widget.onChanged(value));
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText.isEmpty ? context.l10n.adminSearch_hint : widget.hintText,
          hintStyle: TextStyle(
            color: context.appColors.textHint,
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search, color: context.appColors.textHint),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: context.appColors.textHint),
                  onPressed: _clear,
                )
              : null,
          filled: true,
          fillColor: context.appColors.chipUnselected,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }
}
