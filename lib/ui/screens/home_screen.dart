import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/budget_entry.dart';
import '../../data/models/expense.dart';
import '../widgets/expense_card.dart';
import '../widgets/month_summary_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _loading = true;
  BudgetEntry? _budget;
  int _spent = 0;
  List<ExpenseWithCategory> _expenses = [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final budget = await _db.getBudgetForMonth(year, month);
    final spent = await _db.sumExpenseRupeesForMonth(year, month);
    final list = await _db.getExpensesForMonth(year, month);
    if (!mounted) return;
    setState(() {
      _budget = budget;
      _spent = spent;
      _expenses = list;
      _loading = false;
    });
  }

  void reload() {
    unawaited(_load());
  }

  Future<void> _showBudgetDialog() async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    // Controller must live in dialog State and be disposed there — disposing it
    // right after showDialog returns triggers framework assertions while the route
    // is still unmounting its TextField.
    final amountText = await showDialog<String?>(
      context: context,
      builder: (context) => _MonthlyBudgetDialog(
        initialText: _budget == null ? '' : '${_budget!.amountRupees}',
      ),
    );
    if (amountText == null || !mounted) return;

    final raw = amountText.trim().replaceAll(',', '');
    final amount = int.tryParse(raw);
    if (amount == null || amount < 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid non-negative amount.')),
      );
      return;
    }
    await _db.upsertBudget(
      amountRupees: amount,
      year: year,
      monthIndex: month,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final budgetAmount = _budget?.amountRupees ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: MonthSummaryHeader(
                year: year,
                monthIndex: month,
                budgetRupees: budgetAmount,
                spentRupees: _spent,
                onSetBudget: _showBudgetDialog,
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'This month',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_expenses.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No expenses yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.separated(
                itemCount: _expenses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final e = _expenses[index];
                  return ExpenseCard(
                    title: e.title,
                    amountRupees: e.amountRupees,
                    categoryName: e.categoryName,
                    paymentMethod: e.paymentMethod,
                    dateTime: e.expenseAt,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthlyBudgetDialog extends StatefulWidget {
  const _MonthlyBudgetDialog({required this.initialText});

  final String initialText;

  @override
  State<_MonthlyBudgetDialog> createState() => _MonthlyBudgetDialogState();
}

class _MonthlyBudgetDialogState extends State<_MonthlyBudgetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monthly budget'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Amount (₹)',
          hintText: 'e.g. 25000',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<String?>(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop<String?>(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
