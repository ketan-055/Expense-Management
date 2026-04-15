/// Parameters for loading a filtered expense list (all optional = recent only).
class ExpenseQuery {
  const ExpenseQuery({
    this.limit,
    this.filterYear,
    this.filterMonth,
    this.filterDay,
    this.categoryId,
    this.placeId,
    this.amountMin,
    this.amountMax,
  });

  /// When null, no LIMIT clause (all matching rows).
  final int? limit;

  /// Exact calendar day filter (all required when using date filter).
  final int? filterYear;
  final int? filterMonth;
  final int? filterDay;

  final int? categoryId;
  final int? placeId;
  final int? amountMin;
  final int? amountMax;

  bool get hasDateFilter =>
      filterYear != null &&
      filterMonth != null &&
      filterDay != null;

  bool get hasAmountFilter => amountMin != null && amountMax != null;
}
