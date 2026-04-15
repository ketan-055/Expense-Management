import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'add_expense_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _drawerIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

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

  @override
  Widget build(BuildContext context) {
    final isHome = _drawerIndex == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(isHome ? AppConstants.appName : 'History'),
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
        ],
      ),
      body: isHome
          ? HomeScreen(key: _homeKey)
          : const HistoryScreen(),
      floatingActionButton: isHome
          ? FloatingActionButton(
              onPressed: _openAddExpense,
              tooltip: 'Add expense',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
