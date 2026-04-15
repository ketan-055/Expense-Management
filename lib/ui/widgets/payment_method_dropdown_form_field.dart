import 'package:flutter/material.dart';

import '../../data/models/payment_method.dart';
import 'anchored_dropdown_form_field.dart';

/// Payment method picker — uses [AnchoredDropdownFormField] styling.
class PaymentMethodDropdownFormField extends StatelessWidget {
  const PaymentMethodDropdownFormField({
    super.key,
    required this.selected,
    required this.onSelected,
    this.validator,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod?> onSelected;
  final String? Function(PaymentMethod?)? validator;

  @override
  Widget build(BuildContext context) {
    return AnchoredDropdownFormField<PaymentMethod>(
      label: const Text('Payment method'),
      hintText: 'Select payment method',
      selected: selected,
      dropdownMenuEntries: [
        for (final p in PaymentMethod.values)
          DropdownMenuEntry<PaymentMethod>(
            value: p,
            label: p.label,
          ),
      ],
      onSelected: onSelected,
      validator: validator,
    );
  }
}
