import 'package:flutter/material.dart';

import '../../data/models/payment_method.dart';
import '../../utils/formatters.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.title,
    required this.amountRupees,
    required this.categoryName,
    required this.paymentMethod,
    required this.dateTime,
  });

  final String title;
  final int amountRupees;
  final String categoryName;
  final PaymentMethod paymentMethod;
  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF121212),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF252525)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  formatRupees(amountRupees),
                  style: const TextStyle(
                    color: Color(0xFFE4E4E9),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(
                  icon: Icons.category_outlined,
                  label: categoryName,
                ),
                _Chip(
                  icon: paymentMethod == PaymentMethod.cash
                      ? Icons.payments_outlined
                      : Icons.account_balance_wallet_outlined,
                  label: paymentMethod.label,
                ),
                _Chip(
                  icon: Icons.schedule_outlined,
                  label: formatExpenseDateTime(dateTime),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white54),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
