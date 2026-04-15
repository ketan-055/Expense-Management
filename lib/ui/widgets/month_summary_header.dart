import 'package:flutter/material.dart';

import '../../core/month_names.dart';
import '../../utils/formatters.dart';

class MonthSummaryHeader extends StatelessWidget {
  const MonthSummaryHeader({
    super.key,
    required this.year,
    required this.monthIndex,
    required this.budgetRupees,
    required this.spentRupees,
    required this.onSetBudget,
  });

  final int year;
  final int monthIndex;
  final int budgetRupees;
  final int spentRupees;
  final VoidCallback onSetBudget;

  int get _remaining => budgetRupees - spentRupees;

  @override
  Widget build(BuildContext context) {
    final monthLabel = monthShortName(monthIndex);
    final remainingColor = _remaining >= 0
        ? const Color(0xFF4ADE80)
        : const Color(0xFFF87171);

    return Card(
      color: const Color(0xFF141414),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$monthLabel $year',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton.icon(
                  onPressed: onSetBudget,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Set budget'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly budget',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                      ),
                ),
                Text(
                  formatRupees(budgetRupees),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: remainingColor.withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Money remaining',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 0.3,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatRupees(_remaining),
                    style: TextStyle(
                      color: remainingColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Spent ${formatRupees(spentRupees)} this month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
