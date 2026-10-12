import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../models/bike.dart';
import '../../models/contribution.dart';
import '../../models/expense.dart';
import '../../models/partner.dart';
import '../../models/sale.dart';

Future<bool> confirmDialog(BuildContext context, String message,
    {String confirmLabel = 'Delete'}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel)),
      ],
    ),
  );
  return ok ?? false;
}

Future<DateTime?> _pickDate(BuildContext ctx, DateTime initial) =>
    showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

Widget _dateTile(BuildContext ctx, String label, DateTime date,
        ValueChanged<DateTime> onPicked) =>
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$label: ${dateStr(date)}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final d = await _pickDate(ctx, date);
        if (d != null) onPicked(d);
      },
    );

/// Bike expense when [bikeId] != null, otherwise a general showroom expense.
Future<Expense?> showExpenseDialog(BuildContext context, {int? bikeId}) {
  final categories =
      bikeId == null ? kShowroomExpenseCategories : kBikeExpenseCategories;
  final formKey = GlobalKey<FormState>();
  final desc = TextEditingController();
  final amount = TextEditingController();
  var category = categories.first;
  var date = DateTime.now();

  return showDialog<Expense>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(bikeId == null ? 'Showroom expense' : 'Bike expense'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => category = v!),
              ),
              TextFormField(
                controller: desc,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: amount,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: validateAmount,
              ),
              _dateTile(ctx, 'Date', date, (d) => setState(() => date = d)),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                ctx,
                Expense(
                  bikeId: bikeId,
                  category: category,
                  description: nullIfBlank(desc.text),
                  amount: parseAmount(amount.text)!,
                  date: date,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<Partner?> showPartnerDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  return showDialog<Partner>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Add partner'),
      content: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          TextFormField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)'),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(ctx,
                Partner(name: name.text.trim(), phone: nullIfBlank(phone.text)));
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

/// Record capital from a partner. [bikeId] null = general business capital.
Future<Contribution?> showContributionDialog(
  BuildContext context, {
  required List<Partner> partners,
  int? bikeId,
  int? initialPartnerId,
}) {
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  var partnerId = initialPartnerId ?? partners.first.id!;
  var date = DateTime.now();

  return showDialog<Contribution>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(bikeId == null ? 'Add capital' : 'Add contribution'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                value: partnerId,
                decoration: const InputDecoration(labelText: 'Partner'),
                items: [
                  for (final p in partners)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() => partnerId = v!),
              ),
              TextFormField(
                controller: amount,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: validateAmount,
              ),
              TextFormField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              _dateTile(ctx, 'Date', date, (d) => setState(() => date = d)),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                ctx,
                Contribution(
                  partnerId: partnerId,
                  bikeId: bikeId,
                  amount: parseAmount(amount.text)!,
                  date: date,
                  note: nullIfBlank(note.text),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<Sale?> showSaleDialog(BuildContext context, BikeSummary bike) {
  final formKey = GlobalKey<FormState>();
  final buyer = TextEditingController();
  final phone = TextEditingController();
  final price = TextEditingController();
  final notes = TextEditingController();
  var date = DateTime.now();

  return showDialog<Sale>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Sell ${bike.bike.title}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Total cost so far: ${money(bike.totalCost)}',
                    style: Theme.of(ctx).textTheme.bodySmall),
              ),
              TextFormField(
                controller: buyer,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Buyer name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Buyer phone (optional)'),
              ),
              TextFormField(
                controller: price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Sale price'),
                validator: validateAmount,
              ),
              TextFormField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              _dateTile(ctx, 'Sale date', date, (d) => setState(() => date = d)),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                ctx,
                Sale(
                  bikeId: bike.bike.id!,
                  buyerName: buyer.text.trim(),
                  buyerPhone: nullIfBlank(phone.text),
                  salePrice: parseAmount(price.text)!,
                  saleDate: date,
                  notes: nullIfBlank(notes.text),
                ),
              );
            },
            child: const Text('Confirm sale'),
          ),
        ],
      ),
    ),
  );
}
