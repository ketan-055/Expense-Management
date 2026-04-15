import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/udhaar_entry.dart';
import '../../utils/formatters.dart';

/// Udhaar: money to return (borrowed) vs money owed to you (lent). Swipeable tabs.
class UdhaarScreen extends StatefulWidget {
  const UdhaarScreen({super.key});

  @override
  State<UdhaarScreen> createState() => UdhaarScreenState();
}

class UdhaarScreenState extends State<UdhaarScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late TabController _tabController;

  List<UdhaarEntry> _toOthers = [];
  List<UdhaarEntry> _fromMe = [];
  int _sumToOthers = 0;
  int _sumFromMe = 0;

  /// `null` = show all entries; otherwise filter to this name.
  String? _filterNameToOthers;
  String? _filterNameFromMe;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_loadAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final to = await _db.getUdhaarToOthers(nameAscending: true);
    final from = await _db.getUdhaarFromMe(nameAscending: true);
    final sumTo = await _db.sumUdhaarToOthers();
    final sumFrom = await _db.sumUdhaarFromMe();
    if (!mounted) return;

    final namesTo = to.map((e) => e.name).toSet();
    final namesFrom = from.map((e) => e.name).toSet();

    setState(() {
      _toOthers = to;
      _fromMe = from;
      _sumToOthers = sumTo;
      _sumFromMe = sumFrom;
      if (_filterNameToOthers != null && !namesTo.contains(_filterNameToOthers)) {
        _filterNameToOthers = null;
      }
      if (_filterNameFromMe != null && !namesFrom.contains(_filterNameFromMe)) {
        _filterNameFromMe = null;
      }
    });
  }

  List<UdhaarEntry> _visibleToOthers() {
    if (_filterNameToOthers == null) return _toOthers;
    return _toOthers.where((e) => e.name == _filterNameToOthers).toList();
  }

  List<UdhaarEntry> _visibleFromMe() {
    if (_filterNameFromMe == null) return _fromMe;
    return _fromMe.where((e) => e.name == _filterNameFromMe).toList();
  }

  int _sumEntries(List<UdhaarEntry> list) =>
      list.fold<int>(0, (s, e) => s + e.amountRupees);

  /// Called from [MainShell] FAB — add to the tab currently visible.
  void openAddForCurrentTab() {
    _showAddDialog(toOthers: _tabController.index == 0);
  }

  Future<void> _showAddDialog({required bool toOthers}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _UdhaarAddDialog(
        toOthers: toOthers,
        title: toOthers ? 'Add — To Others' : 'Add — From Me',
      ),
    );
    if (saved == true && mounted) {
      await _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7C3AED);
    final visibleTo = _visibleToOthers();
    final visibleFrom = _visibleFromMe();
    final totalToDisplay =
        _filterNameToOthers == null ? _sumToOthers : _sumEntries(visibleTo);
    final totalFromDisplay =
        _filterNameFromMe == null ? _sumFromMe : _sumEntries(visibleFrom);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0xFF0A0A0A),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: purple,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: const [
              Tab(text: 'To Others'),
              Tab(text: 'From Me'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _UdhaarTabContent(
                totalPending: totalToDisplay,
                totalLabel: 'Total to return',
                subtitle: 'Money you borrowed — you need to pay back',
                entries: visibleTo,
                allEntries: _toOthers,
                selectedName: _filterNameToOthers,
                onNameFilterChanged: (name) {
                  setState(() => _filterNameToOthers = name);
                },
                emptyMessage: 'No entries yet.\nTap + to add.',
              ),
              _UdhaarTabContent(
                totalPending: totalFromDisplay,
                totalLabel: 'Total to collect',
                subtitle: 'Money you lent — others need to return',
                entries: visibleFrom,
                allEntries: _fromMe,
                selectedName: _filterNameFromMe,
                onNameFilterChanged: (name) {
                  setState(() => _filterNameFromMe = name);
                },
                emptyMessage: 'No entries yet.\nTap + to add.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UdhaarTabContent extends StatelessWidget {
  const _UdhaarTabContent({
    required this.totalPending,
    required this.totalLabel,
    required this.subtitle,
    required this.entries,
    required this.allEntries,
    required this.selectedName,
    required this.onNameFilterChanged,
    required this.emptyMessage,
  });

  final int totalPending;
  final String totalLabel;
  final String subtitle;
  /// Entries to render (already filtered).
  final List<UdhaarEntry> entries;
  /// Full list to derive unique names for the dropdown.
  final List<UdhaarEntry> allEntries;
  final String? selectedName;
  final ValueChanged<String?> onNameFilterChanged;
  final String emptyMessage;

  List<String> _uniqueNamesSorted() {
    final set = allEntries.map((e) => e.name).toSet().toList();
    set.sort(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return set;
  }

  @override
  Widget build(BuildContext context) {
    final names = _uniqueNamesSorted();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Card(
          color: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatRupees(totalPending),
                  style: const TextStyle(
                    color: Color(0xFFE4E4E9),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              'Sort by',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                key: ValueKey<String?>(selectedName),
                initialValue: selectedName,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                hint: const Text('All'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All'),
                  ),
                  ...names.map(
                    (n) => DropdownMenuItem<String?>(
                      value: n,
                      child: Text(n),
                    ),
                  ),
                ],
                onChanged: onNameFilterChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (allEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          )
        else if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                'No entry for this name.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                color: const Color(0xFF121212),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF252525)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatExpenseDateTime(e.entryAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatRupees(e.amountRupees),
                        style: const TextStyle(
                          color: Color(0xFFE4E4E9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UdhaarAddDialog extends StatefulWidget {
  const _UdhaarAddDialog({
    required this.title,
    required this.toOthers,
  });

  final String title;
  final bool toOthers;

  @override
  State<_UdhaarAddDialog> createState() => _UdhaarAddDialogState();
}

class _UdhaarAddDialogState extends State<_UdhaarAddDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final raw = _amountController.text.trim().replaceAll(',', '');
    final amount = int.tryParse(raw);
    if (name.isEmpty || amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid name and positive amount.'),
        ),
      );
      return;
    }
    final now = DateTime.now();
    if (widget.toOthers) {
      await _db.insertUdhaarToOthers(
        name: name,
        amountRupees: amount,
        entryAt: now,
      );
    } else {
      await _db.insertUdhaarFromMe(
        name: name,
        amountRupees: amount,
        entryAt: now,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Date: ${formatExpenseDateTime(DateTime.now())}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
