enum PaymentMethod {
  cash,
  online;

  String get dbValue => name;

  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.online => 'Online',
      };

  static PaymentMethod fromDb(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}
