import 'package:flutter/material.dart';

/// Category/place picker using [DropdownMenuFormField]: menu anchors to the field,
/// full width, no search. Long-press a row (not "+ Add") to delete after confirmation.
class AddableEntityDropdownFormField extends StatelessWidget {
  const AddableEntityDropdownFormField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.hintText,
    required this.entityKindLabel,
    required this.selectedId,
    required this.rows,
    required this.addLabel,
    this.addSentinelValue = -1,
    required this.onSelected,
    required this.tryDelete,
    required this.onDeleted,
    this.validator,
  });

  final Key fieldKey;
  final Widget label;
  final String hintText;
  /// Short name for dialogs, e.g. "category" or "place".
  final String entityKindLabel;
  final int? selectedId;
  final List<({int id, String name})> rows;
  final String addLabel;
  final int addSentinelValue;
  final ValueChanged<int?> onSelected;
  final Future<String?> Function(int id) tryDelete;
  final void Function(int deletedId) onDeleted;
  final String? Function(int?)? validator;

  Future<void> _onLongPressDelete(
    BuildContext itemContext,
    BuildContext scaffoldContext,
    int id,
    String name,
  ) async {
    MenuController.maybeOf(itemContext)?.close();
    await Future<void>.delayed(Duration.zero);
    if (!scaffoldContext.mounted) return;
    final ok = await showDialog<bool>(
      context: scaffoldContext,
      builder: (context) => AlertDialog(
        title: Text('Delete $entityKindLabel?'),
        content: Text('Remove "$name" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !scaffoldContext.mounted) return;
    final err = await tryDelete(id);
    if (!scaffoldContext.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }
    onDeleted(id);
  }

  @override
  Widget build(BuildContext context) {
    final entries = <DropdownMenuEntry<int>>[
      ...rows.map((r) {
        return DropdownMenuEntry<int>(
          value: r.id,
          label: r.name,
          labelWidget: Builder(
            builder: (itemCtx) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => _onLongPressDelete(
                  itemCtx,
                  context,
                  r.id,
                  r.name,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    r.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        );
      }),
      DropdownMenuEntry<int>(
        value: addSentinelValue,
        label: addLabel,
      ),
    ];

    return DropdownMenuFormField<int>(
      key: fieldKey,
      initialSelection: selectedId,
      label: label,
      hintText: hintText,
      enableFilter: false,
      enableSearch: false,
      expandedInsets: EdgeInsets.zero,
      alignmentOffset: Offset.zero,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Color(0xFF0D0D0D),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      dropdownMenuEntries: entries,
      validator: validator,
      onSelected: onSelected,
    );
  }
}
