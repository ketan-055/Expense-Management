class BudgetEntry {
  const BudgetEntry({
    required this.id,
    required this.amountRupees,
    required this.monthName,
    required this.monthIndex,
    required this.year,
    required this.updatedAt,
  });

  final int id;
  final int amountRupees;
  final String monthName;
  final int monthIndex;
  final int year;
  final DateTime updatedAt;

  factory BudgetEntry.fromMap(Map<String, Object?> map) {
    return BudgetEntry(
      id: map['id']! as int,
      amountRupees: map['amount_rupees']! as int,
      monthName: map['month_name']! as String,
      monthIndex: map['month_index']! as int,
      year: map['year']! as int,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }
}
