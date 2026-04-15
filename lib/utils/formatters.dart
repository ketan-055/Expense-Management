import 'package:intl/intl.dart';

final NumberFormat _rupees = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String formatRupees(int amount) => _rupees.format(amount);

String formatExpenseDateTime(DateTime dt) {
  return DateFormat('d MMM y, h:mm a').format(dt);
}
