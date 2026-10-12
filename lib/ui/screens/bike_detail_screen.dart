import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/bike.dart';
import '../../models/contribution.dart';
import '../../models/enums.dart';
import '../../models/expense.dart';
import '../../state/showroom_provider.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import 'bike_form_screen.dart';

class BikeDetailScreen extends StatefulWidget {
  const BikeDetailScreen({super.key, required this.bikeId});
  final int bikeId;

  @override
  State<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends State<BikeDetailScreen> {
  BikeSummary? _bike;
  List<Expense> _expenses = [];
  List<Contribution> _contribs = [];

  ShowroomProvider get _p => context.read<ShowroomProvider>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = _p.repo;
    final bike = await repo.getBike(widget.bikeId);
    if (bike == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final expenses = await repo.getBikeExpenses(widget.bikeId);
    final contribs = await repo.getBikeContributions(widget.bikeId);
    if (!mounted) return;
    setState(() {
      _bike = bike;
      _expenses = expenses;
      _contribs = contribs;
    });
  }

  /// Runs a mutation, refreshes this screen, and surfaces any error.
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  Future<void> _addExpense() async {
    final e = await showExpenseDialog(context, bikeId: widget.bikeId);
    if (e != null) await _run(() => _p.addExpense(e));
  }

  Future<void> _addContribution() async {
    final partners = _p.partners;
    if (partners.isEmpty) {
      showSnack(context, 'Add a partner first (Partners tab).');
      return;
    }
    final c = await showContributionDialog(context,
        partners: partners, bikeId: widget.bikeId);
    if (c != null) await _run(() => _p.addContribution(c));
  }

  Future<void> _sell() async {
    final sale = await showSaleDialog(context, _bike!);
    if (sale != null) await _run(() => _p.recordSale(sale));
  }

  Future<void> _undoSale() async {
    final saleId = _p.sales
        .firstWhere((s) => s.sale.bikeId == widget.bikeId)
        .sale
        .id!;
    if (await confirmDialog(context,
        'Undo this sale? The bike returns to Available.',
        confirmLabel: 'Undo sale')) {
      await _run(() => _p.undoSale(saleId));
    }
  }

  Future<void> _delete() async {
    if (!await confirmDialog(context,
        'Delete this bike with its expenses, contributions and sale record?')) {
      return;
    }
    await _p.deleteBike(widget.bikeId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = _bike;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final b = s.bike;
    final profit = s.netProfit;
    final funded = _contribs.fold<double>(0, (a, c) => a + c.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(b.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BikeFormScreen(existing: b)));
              if (mounted) _load();
            },
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    StatusChip(b.status),
                    const SizedBox(width: 8),
                    Text(b.condition.label),
                  ]),
                  const SizedBox(height: 8),
                  if (b.registrationNo != null) Text('Reg: ${b.registrationNo}'),
                  if (b.chassisNo != null) Text('Chassis: ${b.chassisNo}'),
                  if (b.color != null) Text('Color: ${b.color}'),
                  if (b.mileageKm != null) Text('Mileage: ${b.mileageKm} km'),
                  Text('Purchased: ${dateStr(b.purchaseDate)}'),
                  if (b.notes != null) Text('Notes: ${b.notes}'),
                  const Divider(height: 24),
                  AmountRow('Purchase price', b.purchasePrice),
                  AmountRow('Expenses', s.totalExpenses),
                  AmountRow('Total cost', s.totalCost, bold: true),
                  if (s.salePrice != null) AmountRow('Sale price', s.salePrice!),
                  if (profit != null)
                    AmountRow('Net profit', profit,
                        bold: true, color: profitColor(profit)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: b.status == BikeStatus.sold
                ? OutlinedButton.icon(
                    onPressed: _undoSale,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo sale'),
                  )
                : Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<BikeStatus>(
                        value: b.status,
                        decoration: const InputDecoration(
                            labelText: 'Status', border: OutlineInputBorder()),
                        items: [
                          for (final st in BikeStatus.values
                              .where((st) => st != BikeStatus.sold))
                            DropdownMenuItem(value: st, child: Text(st.label)),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            _run(() => _p.changeStatus(widget.bikeId, v));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _sell,
                      icon: const Icon(Icons.sell),
                      label: const Text('Sell'),
                    ),
                  ]),
          ),
          SectionHeader(
            'Expenses (${money(s.totalExpenses)})',
            action: TextButton.icon(
                onPressed: _addExpense,
                icon: const Icon(Icons.add),
                label: const Text('Add')),
          ),
          if (_expenses.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No expenses recorded.')),
          for (final e in _expenses)
            ListTile(
              dense: true,
              title: Text(e.category),
              subtitle: Text(
                  [if (e.description != null) e.description!, dateStr(e.date)]
                      .join(' • ')),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(money(e.amount)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () async {
                    if (await confirmDialog(context, 'Delete this expense?')) {
                      _run(() => _p.deleteExpense(e.id!));
                    }
                  },
                ),
              ]),
            ),
          SectionHeader(
            'Partner funding (${money(funded)} of ${money(b.purchasePrice)})',
            action: TextButton.icon(
                onPressed: _addContribution,
                icon: const Icon(Icons.add),
                label: const Text('Add')),
          ),
          if (_contribs.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No partner contributions recorded.')),
          for (final c in _contribs)
            ListTile(
              dense: true,
              title: Text(c.partnerName ?? 'Partner'),
              subtitle: Text(
                  [if (c.note != null) c.note!, dateStr(c.date)].join(' • ')),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(money(c.amount)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () async {
                    if (await confirmDialog(
                        context, 'Delete this contribution?')) {
                      _run(() => _p.deleteContribution(c.id!));
                    }
                  },
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
