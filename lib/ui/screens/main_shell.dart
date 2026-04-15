import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'add_expense_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'udhaar_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _drawerIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<UdhaarScreenState> _udhaarKey = GlobalKey<UdhaarScreenState>();

  Future<void> _openAddExpense() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const AddExpenseScreen(),
      ),
    );
    if (saved == true) {
      _homeKey.currentState?.reload();
    }
  }

  void _openAddUdhaar() {
    _udhaarKey.currentState?.openAddForCurrentTab();
  }

  String get _title {
    switch (_drawerIndex) {
      case 0:
        return AppConstants.appName;
      case 1:
        return 'History';
      case 2:
        return 'Udhaar';
      default:
        return AppConstants.appName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      drawer: NavigationDrawer(
        selectedIndex: _drawerIndex,
        onDestinationSelected: (index) {
          setState(() => _drawerIndex = index);
          Navigator.of(context).pop();
        },
        children: const [
          DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1A1A1A)),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('Home'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: Text('History'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: Text('Udhaar'),
          ),
        ],
      ),
      body: switch (_drawerIndex) {
        0 => HomeScreen(key: _homeKey),
        1 => const HistoryScreen(),
        2 => UdhaarScreen(key: _udhaarKey),
        _ => HomeScreen(key: _homeKey),
      },
      floatingActionButton: _drawerIndex == 0
          ? FloatingActionButton(
              onPressed: _openAddExpense,
              tooltip: 'Add expense',
              child: const Icon(Icons.add),
            )
          : _drawerIndex == 2
              ? FloatingActionButton(
                  onPressed: _openAddUdhaar,
                  tooltip: 'Add udhaar entry',
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }
}
