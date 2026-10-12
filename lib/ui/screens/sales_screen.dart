import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../state/showroom_provider.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ShowroomProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sales history')),
      body: p.sales.isEmpty
          ? const Center(child: Text('No sales yet'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bikes sold'),
                          Text('${p.sales.length}'),
                        ],
                      ),
                      AmountRow('Total revenue', p.totalRevenue),
                      AmountRow('Total net profit', p.totalNetProfit,
                          bold: true, color: profitColor(p.totalNetProfit)),
                    ]),
                  ),
                ),
                for (final r in p.sales)
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      title: Text(r.bikeTitle),
                      subtitle: Text(
                        '${r.sale.buyerName} • ${dateStr(r.sale.saleDate)}\n'
                        'Sold ${money(r.sale.salePrice)}  |  Cost ${money(r.totalCost)} '
                        '(buy ${money(r.purchasePrice)} + exp ${money(r.totalExpenses)})',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Profit',
                              style: Theme.of(context).textTheme.labelSmall),
                          Text(
                            money(r.netProfit),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: profitColor(r.netProfit)),
                          ),
                        ],
                      ),
                      onLongPress: () async {
                        if (await confirmDialog(context,
                            'Undo the sale of ${r.bikeTitle}? It returns to Available.',
                            confirmLabel: 'Undo sale')) {
                          await p.undoSale(r.sale.id!);
                        }
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
