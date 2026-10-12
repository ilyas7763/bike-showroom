import 'package:flutter/material.dart';

import 'expenses_screen.dart';
import 'inventory_screen.dart';
import 'partners_screen.dart';
import 'sales_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _pages = <Widget>[
    InventoryScreen(),
    SalesScreen(),
    PartnersScreen(),
    ExpensesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.two_wheeler), label: 'Inventory'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long), label: 'Sales'),
          NavigationDestination(
              icon: Icon(Icons.groups), label: 'Partners'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet), label: 'Expenses'),
        ],
      ),
    );
  }
}
