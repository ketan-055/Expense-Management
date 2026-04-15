import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/place.dart';
import '../../utils/formatters.dart';
import '../widgets/name_input_dialog.dart';

class EditExpenseScreen extends StatefulWidget {
  const EditExpenseScreen({super.key, required this.expense});

  final ExpenseItem expense;

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _amountController;

  final DatabaseHelper _db = DatabaseHelper.instance;

  late PaymentMethod _payment;
  List<Category> _categories = [];
  List<Place> _places = [];
  int? _categoryId;
  int? _placeId;
  late DateTime _expenseAt;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _titleController = TextEditingController(text: e.title);
    _descController = TextEditingController(text: e.description ?? '');
    _amountController = TextEditingController(text: '${e.amountRupees}');
    _payment = e.paymentMethod;
    _categoryId = e.categoryId;
    _placeId = e.placeId;
    _expenseAt = e.expenseAt;
    unawaited(_loadLists());
  }

  Future<void> _loadLists() async {
    final cats = await _db.getAllCategories();
    final pls = await _db.getAllPlaces();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _places = pls;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expenseAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expenseAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _expenseAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _addCategory() async {
    final name = await showDialog<String?>(
      context: context,
      builder: (context) => const NameInputDialog(
        title: 'New category',
        label: 'Name',
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    try {
      final id = await _db.insertCategory(name);
      await _loadLists();
      setState(() => _categoryId = id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That category already exists. Pick another name.'),
        ),
      );
    }
  }

  Future<void> _addPlace() async {
    final name = await showDialog<String?>(
      context: context,
      builder: (context) => const NameInputDialog(
        title: 'New place',
        label: 'Name',
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    try {
      final id = await _db.insertPlace(name);
      await _loadLists();
      setState(() => _placeId = id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That place already exists. Pick another name.'),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null || _placeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select both category and place.'),
        ),
      );
      return;
    }
    final raw = _amountController.text.trim().replaceAll(',', '');
    final amount = int.tryParse(raw);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount.')),
      );
      return;
    }
    final draft = ExpenseDraft(
      amountRupees: amount,
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      paymentMethod: _payment,
      categoryId: _categoryId!,
      placeId: _placeId!,
      expenseAt: _expenseAt,
    );
    await _db.updateExpense(widget.expense.id, draft);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = int.tryParse(v.trim().replaceAll(',', ''));
                if (n == null || n <= 0) return 'Enter a positive amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              value: _payment, // ignore: deprecated_member_use
              decoration: const InputDecoration(
                labelText: 'Payment method',
                border: OutlineInputBorder(),
              ),
              items: PaymentMethod.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _payment = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _categoryId, // ignore: deprecated_member_use
              hint: const Text('Select category'),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                ..._categories.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  ),
                ),
                const DropdownMenuItem<int>(
                  value: -1,
                  child: Text('+ Add category'),
                ),
              ],
              onChanged: (v) async {
                if (v == null) return;
                if (v == -1) {
                  await _addCategory();
                  return;
                }
                setState(() => _categoryId = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _placeId, // ignore: deprecated_member_use
              hint: const Text('Select place'),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Place',
                border: OutlineInputBorder(),
              ),
              items: [
                ..._places.map(
                  (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name),
                  ),
                ),
                const DropdownMenuItem<int>(
                  value: -1,
                  child: Text('+ Add place'),
                ),
              ],
              onChanged: (v) async {
                if (v == null) return;
                if (v == -1) {
                  await _addPlace();
                  return;
                }
                setState(() => _placeId = v);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date & time'),
              subtitle: Text(formatExpenseDateTime(_expenseAt)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
