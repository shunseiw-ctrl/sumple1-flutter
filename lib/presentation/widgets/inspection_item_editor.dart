import 'package:flutter/material.dart';
import 'package:sumple1/core/constants/app_spacing.dart';
import 'package:sumple1/core/extensions/build_context_extensions.dart';
import 'package:sumple1/data/models/inspection_model.dart';

/// カスタム検査項目の追加・削除・並替ウィジェット
class InspectionItemEditor extends StatefulWidget {
  final List<String> items;
  final ValueChanged<List<String>> onChanged;

  const InspectionItemEditor({
    super.key,
    required this.items,
    required this.onChanged,
  });

  @override
  State<InspectionItemEditor> createState() => _InspectionItemEditorState();
}

class _InspectionItemEditorState extends State<InspectionItemEditor> {
  late List<String> _items;
  final _newItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _newItemController.text.trim();
    if (text.isEmpty || _items.length >= 20) return;
    setState(() {
      _items.add(text);
      _newItemController.clear();
    });
    widget.onChanged(_items);
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    widget.onChanged(_items);
  }

  void _useDefaults() {
    setState(() {
      _items = List.from(InspectionModel.defaultCheckItems);
    });
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.inspection_customItems,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _useDefaults,
              icon: const Icon(Icons.restore, size: 16),
              label: Text(context.l10n.inspection_defaultItems, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.inspection_customItemsHelp,
          style: TextStyle(fontSize: 12, color: context.appColors.textHint),
        ),
        const SizedBox(height: AppSpacing.sm),
        // 既存項目リスト
        ...List.generate(_items.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.drag_handle, size: 18, color: context.appColors.textHint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _items[i],
                    style: TextStyle(fontSize: 14, color: context.appColors.textPrimary),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: context.appColors.error),
                  onPressed: () => _removeItem(i),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: context.l10n.inspection_removeItem,
                ),
              ],
            ),
          );
        }),
        // 新規項目追加
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newItemController,
                decoration: InputDecoration(
                  hintText: context.l10n.inspection_customItemsHint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.add_circle, color: context.appColors.primary),
              onPressed: _addItem,
              tooltip: context.l10n.inspection_addItem,
            ),
          ],
        ),
      ],
    );
  }
}
