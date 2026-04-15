import 'payment_method.dart';

class ExpenseDraft {
  const ExpenseDraft({
    required this.amountRupees,
    required this.title,
    this.description,
    required this.paymentMethod,
    required this.categoryId,
    required this.expenseAt,
  });

  final int amountRupees;
  final String title;
  final String? description;
  final PaymentMethod paymentMethod;
  final int categoryId;
  final DateTime expenseAt;

  Map<String, Object?> toMap() {
    return {
      'amount_rupees': amountRupees,
      'title': title,
      'description': description,
      'payment_method': paymentMethod.dbValue,
      'category_id': categoryId,
      'expense_at': expenseAt.millisecondsSinceEpoch,
    };
  }
}

class ExpenseWithCategory {
  const ExpenseWithCategory({
    required this.id,
    required this.amountRupees,
    required this.title,
    this.description,
    required this.paymentMethod,
    required this.categoryName,
    required this.expenseAt,
  });

  final int id;
  final int amountRupees;
  final String title;
  final String? description;
  final PaymentMethod paymentMethod;
  final String categoryName;
  final DateTime expenseAt;
}
