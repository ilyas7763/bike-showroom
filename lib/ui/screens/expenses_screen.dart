import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../state/showroom_provider.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

/// Daily showroom running costs (rent, bills, salaries…) – not tied to a bike.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ShowroomProvider>();
    final now = DateTime.now();
    final monthTotal = p.showroomExpenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (a, e) => a + e.amount);
    final allTotal = p.showroomExpenses.fold<double>(0, (a, e) => a + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Showroom expenses')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
        onPressed: () async {
          final e = await showExpenseDialog(context);
          if (e != null) await p.addExpense(e);
        },
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                AmountRow('This month', monthTotal, bold: true),
                AmountRow('All time', allTotal),
              ]),
            ),
          ),
          if (p.showroomExpenses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No showroom expenses yet')),
            ),
          for (final e in p.showroomExpenses)
            Dismissible(
              key: ValueKey('expense-${e.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) => confirmDialog(context, 'Delete this expense?'),
              onDismissed: (_) => p.deleteExpense(e.id!),
              child: ListTile(
                title: Text(e.category),
                subtitle: Text(
                    [if (e.description != null) e.description!, dateStr(e.date)]
                        .join(' • ')),
                trailing: Text(money(e.amount),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}
