class UdhaarEntry {
  const UdhaarEntry({
    required this.id,
    required this.name,
    required this.amountRupees,
    required this.entryAt,
  });

  final int id;
  final String name;
  final int amountRupees;
  final DateTime entryAt;

  factory UdhaarEntry.fromMap(Map<String, Object?> map) {
    return UdhaarEntry(
      id: map['id']! as int,
      name: map['name']! as String,
      amountRupees: map['amount_rupees']! as int,
      entryAt: DateTime.fromMillisecondsSinceEpoch(map['entry_at']! as int),
    );
  }
}
