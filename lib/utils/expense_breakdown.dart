import '../core/month_names.dart';
import '../data/models/expense.dart';

/// How to group expenses for the home statistics pie chart.
enum ChartBreakdownMode {
  category,
  place,
  payment,
  date,
}

extension ChartBreakdownModeLabel on ChartBreakdownMode {
  String get menuLabel => switch (this) {
        ChartBreakdownMode.category => 'Category',
        ChartBreakdownMode.place => 'Place',
        ChartBreakdownMode.payment => 'Payment Method',
        ChartBreakdownMode.date => 'Date',
      };
}

/// One slice of the expense distribution chart.
class ExpenseSlice {
  const ExpenseSlice({
    required this.label,
    required this.amountRupees,
    this.detailLine,
  });

  final String label;
  final int amountRupees;
  /// Optional second line (e.g. date range for weeks).
  final String? detailLine;
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Splits [month] into four contiguous ranges of ~equal length (by day of month).
int weekBucketForDay(int day, int year, int month) {
  final n = _daysInMonth(year, month);
  if (n <= 0) return 0;
  return (((day - 1) * 4) / n).floor().clamp(0, 3);
}

String weekDateRangeLabel(int bucket, int year, int month) {
  final n = _daysInMonth(year, month);
  final start = (bucket * n / 4).floor() + 1;
  final end = bucket == 3 ? n : ((bucket + 1) * n / 4).floor();
  final m = monthShortName(month);
  return '$start–$end $m';
}

/// Aggregates [items] (expected: one calendar month) into labeled slices.
List<ExpenseSlice> buildExpenseSlices(
  List<ExpenseItem> items,
  ChartBreakdownMode mode,
  int year,
  int month,
) {
  switch (mode) {
    case ChartBreakdownMode.category:
      return _aggregateBy(
        items,
        (e) => e.categoryName.trim().isEmpty ? 'Uncategorized' : e.categoryName,
      );
    case ChartBreakdownMode.place:
      return _aggregateBy(
        items,
        (e) => e.placeName.trim().isEmpty ? 'Unknown place' : e.placeName,
      );
    case ChartBreakdownMode.payment:
      return _aggregateBy(items, (e) => e.paymentMethod.label);
    case ChartBreakdownMode.date:
      final n = _daysInMonth(year, month);
      final buckets = List<int>.filled(4, 0);
      for (final e in items) {
        final d = e.expenseAt.day.clamp(1, n);
        final b = weekBucketForDay(d, year, month);
        buckets[b] += e.amountRupees;
      }
      final out = <ExpenseSlice>[];
      for (var i = 0; i < 4; i++) {
        if (buckets[i] <= 0) continue;
        out.add(
          ExpenseSlice(
            label: 'Week ${i + 1}',
            amountRupees: buckets[i],
            detailLine: weekDateRangeLabel(i, year, month),
          ),
        );
      }
      return out;
  }
}

List<ExpenseSlice> _aggregateBy(
  List<ExpenseItem> items,
  String Function(ExpenseItem) keyFn,
) {
  final map = <String, int>{};
  for (final e in items) {
    final k = keyFn(e);
    map[k] = (map[k] ?? 0) + e.amountRupees;
  }
  final list = map.entries
      .map(
        (e) => ExpenseSlice(label: e.key, amountRupees: e.value),
      )
      .toList();
  list.sort((a, b) => b.amountRupees.compareTo(a.amountRupees));
  return list;
}
