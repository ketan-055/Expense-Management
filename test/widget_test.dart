import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kharcha_pani/ui/widgets/month_summary_header.dart';

void main() {
  testWidgets('Month summary shows money remaining', (WidgetTester tester) async {
    final selected = DateTime(2026, 4, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthSummaryHeader(
            selectedMonth: selected,
            monthChoices: [selected],
            budgetRupees: 10000,
            spentRupees: 3000,
            onSetBudget: () {},
            onMonthChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Money remaining'), findsOneWidget);
    expect(find.text('₹7,000'), findsOneWidget);
  });
}
