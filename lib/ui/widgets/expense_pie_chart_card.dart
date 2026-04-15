import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/expense.dart';
import '../../utils/expense_breakdown.dart';

const _sliceColors = <Color>[
  Color(0xFF7C3AED),
  Color(0xFF4ADE80),
  Color(0xFF60A5FA),
  Color(0xFFFBBF24),
  Color(0xFFF472B6),
  Color(0xFF2DD4BF),
  Color(0xFFA78BFA),
  Color(0xFFFB923C),
];

/// Dark card with a pie chart of expense distribution and a breakdown filter.
class ExpensePieChartCard extends StatelessWidget {
  const ExpensePieChartCard({
    super.key,
    required this.monthExpenses,
    required this.breakdownMode,
    required this.onBreakdownModeChanged,
    required this.year,
    required this.month,
  });

  final List<ExpenseItem> monthExpenses;
  final ChartBreakdownMode breakdownMode;
  final ValueChanged<ChartBreakdownMode> onBreakdownModeChanged;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    final slices = buildExpenseSlices(monthExpenses, breakdownMode, year, month);
    final total = slices.fold<int>(0, (s, e) => s + e.amountRupees);

    return Card(
      color: const Color(0xFF141414),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                DropdownButton<ChartBreakdownMode>(
                  value: breakdownMode,
                  dropdownColor: const Color(0xFF1E1E1E),
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  items: ChartBreakdownMode.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.menuLabel),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onBreakdownModeChanged(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Spending by ${breakdownMode.menuLabel.toLowerCase()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                  ),
            ),
            const SizedBox(height: 16),
            if (total <= 0 || slices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    'No expenses this month.\nAdd expenses to see the chart.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 380;
                  final chart = SizedBox(
                    width: 160,
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: List.generate(slices.length, (i) {
                          final s = slices[i];
                          final p =
                              total > 0 ? (s.amountRupees / total * 100) : 0.0;
                          final color = _sliceColors[i % _sliceColors.length];
                          return PieChartSectionData(
                            color: color,
                            value: s.amountRupees.toDouble(),
                            title: p <= 0
                                ? ''
                                : p < 1
                                    ? '<1%'
                                    : '${p.round()}%',
                            radius: 52,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }),
                      ),
                      duration: const Duration(milliseconds: 200),
                    ),
                  );
                  final legend = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < slices.length; i++)
                        _LegendRow(
                          color: _sliceColors[i % _sliceColors.length],
                          slice: slices[i],
                        ),
                    ],
                  );
                  if (narrow) {
                    return Column(
                      children: [
                        Center(child: chart),
                        const SizedBox(height: 16),
                        legend,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      chart,
                      const SizedBox(width: 12),
                      Expanded(child: legend),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.slice,
  });

  final Color color;
  final ExpenseSlice slice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4, right: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slice.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (slice.detailLine != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    slice.detailLine!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
