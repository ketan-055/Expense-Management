import 'package:flutter/material.dart';

/// [DropdownMenuFormField] with the same anchored layout and styling as
/// [AddableEntityDropdownFormField] / add-expense pickers: menu under the field,
/// full width, no search, dark menu.
class AnchoredDropdownFormField<T> extends StatelessWidget {
  const AnchoredDropdownFormField({
    super.key,
    required this.label,
    required this.hintText,
    required this.selected,
    required this.dropdownMenuEntries,
    required this.onSelected,
    this.validator,
  });

  final Widget label;
  final String hintText;
  final T? selected;
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;
  final ValueChanged<T?> onSelected;
  final String? Function(T?)? validator;

  static const _menuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll(Color(0xFF1E1E1E)),
    elevation: WidgetStatePropertyAll(8),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  static const _inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Color(0xFF0D0D0D),
  );

  @override
  Widget build(BuildContext context) {
    return DropdownMenuFormField<T>(
      initialSelection: selected,
      label: label,
      hintText: hintText,
      enableFilter: false,
      enableSearch: false,
      expandedInsets: EdgeInsets.zero,
      alignmentOffset: Offset.zero,
      inputDecorationTheme: _inputDecorationTheme,
      menuStyle: _menuStyle,
      dropdownMenuEntries: dropdownMenuEntries,
      onSelected: onSelected,
      validator: validator,
    );
  }
}
