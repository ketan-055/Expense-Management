import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/budget_entry.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../data/models/expense_query.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/place.dart';
import '../widgets/expense_card.dart';
import '../widgets/month_summary_header.dart';
import 'edit_expense_screen.dart';

enum _FilterMode { recent, date, category, place, amount, payment }

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
  List<ExpenseItem> _expenses = [];

  _FilterMode _filterMode = _FilterMode.recent;
  bool _expandedList = false;

  /// First day of the month shown in the header (budget + list scope).
  late DateTime _selectedMonthFirst;

  /// Day within [_selectedMonthFirst] when using Date filter (1–31).
  int _filterDay = DateTime.now().day;

  int? _filterCategoryId;
  int? _filterPlaceId;
  PaymentMethod? _filterPaymentMethod;

  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  List<Category> _filterCategories = [];
  List<Place> _filterPlaces = [];

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _selectedMonthFirst = DateTime(n.year, n.month, 1);
    _filterDay = _clampDay(n.year, n.month, n.day);
    unawaited(_loadFilterOptions());
    unawaited(_loadAll());
  }

  /// Past five months ending at the current calendar month.
  static List<DateTime> _fiveMonthChoices() {
    final a = DateTime.now();
    return List.generate(5, (i) => DateTime(a.year, a.month - i, 1));
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    final c = await _db.getAllCategories();
    final p = await _db.getAllPlaces();
    if (!mounted) return;
    setState(() {
      _filterCategories = c;
      _filterPlaces = p;
    });
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await _refreshBudget();
    await _refreshExpenseList();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _refreshBudget() async {
    final year = _selectedMonthFirst.year;
    final month = _selectedMonthFirst.month;
    _budget = await _db.getBudgetForMonth(year, month);
    _spent = await _db.sumExpenseRupeesForMonth(year, month);
  }

  Future<void> _refreshExpenseList() async {
    final list = await _db.queryExpenses(_buildQuery());
    if (!mounted) return;
    setState(() => _expenses = list);
  }

  ExpenseQuery _buildQuery() {
    final limit = _expandedList ? null : 10;
    final sy = _selectedMonthFirst.year;
    final sm = _selectedMonthFirst.month;

    switch (_filterMode) {
      case _FilterMode.recent:
        return ExpenseQuery(
          scopeYear: sy,
          scopeMonth: sm,
          limit: limit,
        );
      case _FilterMode.date:
        return ExpenseQuery(
          scopeYear: sy,
          scopeMonth: sm,
          filterDay: _filterDay,
          limit: limit,
        );
      case _FilterMode.category:
        if (_filterCategoryId == null) {
          return ExpenseQuery(scopeYear: sy, scopeMonth: sm, limit: 0);
        }
        return ExpenseQuery(
          scopeYear: sy,
          scopeMonth: sm,
          categoryId: _filterCategoryId,
          limit: limit,
        );
      case _FilterMode.place:
        if (_filterPlaceId == null) {
          return ExpenseQuery(scopeYear: sy, scopeMonth: sm, limit: 0);
        }
        return ExpenseQuery(
          scopeYear: sy,
          scopeMonth: sm,
          placeId: _filterPlaceId,
          limit: limit,
        );
      case _FilterMode.amount:
        final minV = int.tryParse(_minAmountController.text.replaceAll(',', ''));
        final maxV = int.tryParse(_maxAmountController.text.replaceAll(',', ''));
        if (minV == null || maxV == null) {
          return ExpenseQuery(scopeYear: sy, scopeMonth: sm, limit: 0);
        }
        final lo = minV <= maxV ? minV : maxV;
        final hi = minV <= maxV ? maxV : minV;
        return ExpenseQuery(
          scopeYear: sy,
          scopeMonth: sm,
          amountMin: lo,
          amountMax: hi,
          limit: limit,
        );
      case _FilterMode.payment:
        if (_filterPaymentMethod == null) {
          return ExpenseQuery(scopeYear: sy, scopeMonth: sm, limit: 0);
        }
        return ExpenseQuery(
          scopeYear: sy,
          scopeMonth: sm,
          paymentMethodDb: _filterPaymentMethod!.dbValue,
          limit: limit,
        );
    }
  }

  void _onFilterModeChanged(_FilterMode mode) {
    setState(() {
      _filterMode = mode;
      _expandedList = false;
      if (mode == _FilterMode.date) {
        final now = DateTime.now();
        final sy = _selectedMonthFirst.year;
        final sm = _selectedMonthFirst.month;
        if (sy == now.year && sm == now.month) {
          _filterDay = _clampDay(sy, sm, now.day);
        } else {
          _filterDay = 1;
        }
      }
    });
    unawaited(_refreshExpenseList());
  }

  void _onMonthSelected(DateTime firstOfMonth) {
    final d = DateTime(firstOfMonth.year, firstOfMonth.month, 1);
    setState(() {
      _selectedMonthFirst = d;
      _expandedList = false;
      _filterDay = _clampDay(d.year, d.month, _filterDay);
    });
    unawaited(_loadAll());
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  int _clampDay(int year, int month, int day) {
    final d = _daysInMonth(year, month);
    return day.clamp(1, d);
  }

  Future<void> _applyAmountFilter() async {
    final minV = int.tryParse(_minAmountController.text.replaceAll(',', ''));
    final maxV = int.tryParse(_maxAmountController.text.replaceAll(',', ''));
    if (minV == null || maxV == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both minimum and maximum amount.')),
      );
      return;
    }
    setState(() => _expandedList = false);
    await _refreshExpenseList();
  }

  void reload() {
    unawaited(_loadAll());
    unawaited(_loadFilterOptions());
  }

  Future<void> _showBudgetDialog() async {
    final year = _selectedMonthFirst.year;
    final month = _selectedMonthFirst.month;
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
    await _loadAll();
  }

  Future<bool?> _confirmDelete(ExpenseItem e) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${e.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmEdit() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit expense?'),
        content: const Text('Open the editor for this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDismissedDelete(ExpenseItem e) async {
    await _db.deleteExpense(e.id);
    await _refreshBudget();
    await _refreshExpenseList();
  }

  Future<void> _openEdit(ExpenseItem e) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => EditExpenseScreen(expense: e),
      ),
    );
    if (changed == true && mounted) {
      await _loadFilterOptions();
      await _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final budgetAmount = _budget?.amountRupees ?? 0;

    final showFooter = _expenses.isNotEmpty &&
        (_expandedList || (!_expandedList && _expenses.length >= 10));

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: MonthSummaryHeader(
                selectedMonth: _selectedMonthFirst,
                monthChoices: _fiveMonthChoices(),
                budgetRupees: budgetAmount,
                spentRupees: _spent,
                onSetBudget: _showBudgetDialog,
                onMonthChanged: _onMonthSelected,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort / filter',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'Recent',
                        selected: _filterMode == _FilterMode.recent,
                        onTap: () => _onFilterModeChanged(_FilterMode.recent),
                      ),
                      _FilterChip(
                        label: 'Date',
                        selected: _filterMode == _FilterMode.date,
                        onTap: () => _onFilterModeChanged(_FilterMode.date),
                      ),
                      _FilterChip(
                        label: 'Category',
                        selected: _filterMode == _FilterMode.category,
                        onTap: () => _onFilterModeChanged(_FilterMode.category),
                      ),
                      _FilterChip(
                        label: 'Place',
                        selected: _filterMode == _FilterMode.place,
                        onTap: () => _onFilterModeChanged(_FilterMode.place),
                      ),
                      _FilterChip(
                        label: 'Amount',
                        selected: _filterMode == _FilterMode.amount,
                        onTap: () => _onFilterModeChanged(_FilterMode.amount),
                      ),
                      _FilterChip(
                        label: 'Payment',
                        selected: _filterMode == _FilterMode.payment,
                        onTap: () => _onFilterModeChanged(_FilterMode.payment),
                      ),
                    ],
                  ),
                  if (_filterMode == _FilterMode.date) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _filterDay, // ignore: deprecated_member_use
                      decoration: const InputDecoration(
                        labelText: 'Day',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        _daysInMonth(
                          _selectedMonthFirst.year,
                          _selectedMonthFirst.month,
                        ),
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}'),
                        ),
                      ),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _filterDay = v;
                          _expandedList = false;
                        });
                        unawaited(_refreshExpenseList());
                      },
                    ),
                  ],
                  if (_filterMode == _FilterMode.category) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _filterCategoryId, // ignore: deprecated_member_use
                      hint: const Text('Select category'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _filterCategories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _filterCategoryId = v;
                          _expandedList = false;
                        });
                        unawaited(_refreshExpenseList());
                      },
                    ),
                  ],
                  if (_filterMode == _FilterMode.place) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _filterPlaceId, // ignore: deprecated_member_use
                      hint: const Text('Select place'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Place',
                        border: OutlineInputBorder(),
                      ),
                      items: _filterPlaces
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _filterPlaceId = v;
                          _expandedList = false;
                        });
                        unawaited(_refreshExpenseList());
                      },
                    ),
                  ],
                  if (_filterMode == _FilterMode.amount) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min (₹)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max (₹)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonal(
                        onPressed: _applyAmountFilter,
                        child: const Text('Apply range'),
                      ),
                    ),
                  ],
                  if (_filterMode == _FilterMode.payment) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentMethod>(
                      value: _filterPaymentMethod, // ignore: deprecated_member_use
                      hint: const Text('Select payment method'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Payment method',
                        border: OutlineInputBorder(),
                      ),
                      items: PaymentMethod.values
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _filterPaymentMethod = v;
                          _expandedList = false;
                        });
                        unawaited(_refreshExpenseList());
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Text(
                    'Expenses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _filterSubtitle(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
                    'No expenses match.\nAdd one with + or adjust filters.',
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
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final n = _expenses.length;
                    if (index < n) {
                      final e = _expenses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: ValueKey<int>(e.id),
                          direction: DismissDirection.horizontal,
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              final ok = await _confirmDelete(e);
                              if (ok == true) {
                                await _onDismissedDelete(e);
                              }
                              return false;
                            }
                            final edit = await _confirmEdit();
                            if (edit == true) {
                              await _openEdit(e);
                            }
                            return false;
                          },
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7F1D1D),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A5F),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                            ),
                          ),
                          child: ExpenseCard(
                            title: e.title,
                            amountRupees: e.amountRupees,
                            categoryName: e.categoryName,
                            placeName: e.placeName,
                            paymentMethod: e.paymentMethod,
                            dateTime: e.expenseAt,
                          ),
                        ),
                      );
                    }
                    if (showFooter && index == n) {
                      if (_expandedList) {
                        return TextButton(
                          onPressed: () {
                            setState(() => _expandedList = false);
                            unawaited(_refreshExpenseList());
                          },
                          child: const Text('Show less'),
                        );
                      }
                      return TextButton(
                        onPressed: () {
                          setState(() => _expandedList = true);
                          unawaited(_refreshExpenseList());
                        },
                        child: const Text('View more'),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  childCount:
                      _expenses.length + (showFooter ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _filterSubtitle() {
    switch (_filterMode) {
      case _FilterMode.recent:
        return _expandedList ? 'Showing all in month' : 'Latest 10 in month';
      case _FilterMode.date:
        return 'Day $_filterDay';
      case _FilterMode.category:
        if (_filterCategoryId == null) return 'Pick a category';
        for (final c in _filterCategories) {
          if (c.id == _filterCategoryId) return c.name;
        }
        return '';
      case _FilterMode.place:
        if (_filterPlaceId == null) return 'Pick a place';
        for (final p in _filterPlaces) {
          if (p.id == _filterPlaceId) return p.name;
        }
        return '';
      case _FilterMode.amount:
        return 'Amount range';
      case _FilterMode.payment:
        if (_filterPaymentMethod == null) return 'Pick a method';
        return _filterPaymentMethod!.label;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF3B2F5C)
          : const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
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
