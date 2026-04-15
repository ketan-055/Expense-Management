/// Expense list query scoped to a calendar month ([scopeYear]/[scopeMonth]).
class ExpenseQuery {
  const ExpenseQuery({
    required this.scopeYear,
    required this.scopeMonth,
    this.limit,
    /// Single day within [scopeMonth] (1–31). When set, only that day is included.
    this.filterDay,
    this.categoryId,
    this.placeId,
    this.amountMin,
    this.amountMax,
    /// Matches [PaymentMethod.dbValue] (`cash` / `online`).
    this.paymentMethodDb,
  });

  final int scopeYear;
  final int scopeMonth;

  /// When null, no LIMIT clause (all matching rows).
  final int? limit;

  final int? filterDay;

  final int? categoryId;
  final int? placeId;
  final int? amountMin;
  final int? amountMax;
  final String? paymentMethodDb;

  bool get hasAmountFilter => amountMin != null && amountMax != null;
}
