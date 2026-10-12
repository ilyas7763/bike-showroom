import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/bike.dart';
import '../../models/enums.dart';
import '../../models/partner.dart';
import '../../state/showroom_provider.dart';
import '../widgets/common.dart';

/// Add a new bike (with partner funding split) or edit an existing one.
class BikeFormScreen extends StatefulWidget {
  const BikeFormScreen({super.key, this.existing});
  final Bike? existing;

  @override
  State<BikeFormScreen> createState() => _BikeFormScreenState();
}

class _BikeFormScreenState extends State<BikeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _make, _model, _year, _reg, _chassis,
      _color, _mileage, _price, _notes;
  final Map<int, TextEditingController> _contribCtrls = {};
  late List<Partner> _partners;

  late BikeCondition _condition;
  late BikeStatus _status;
  late DateTime _purchaseDate;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _make = TextEditingController(text: b?.make);
    _model = TextEditingController(text: b?.model);
    _year = TextEditingController(text: b?.year.toString());
    _reg = TextEditingController(text: b?.registrationNo);
    _chassis = TextEditingController(text: b?.chassisNo);
    _color = TextEditingController(text: b?.color);
    _mileage = TextEditingController(text: b?.mileageKm?.toString());
    _price = TextEditingController(
        text: b == null ? '' : b.purchasePrice.toStringAsFixed(0));
    _notes = TextEditingController(text: b?.notes);
    _condition = b?.condition ?? BikeCondition.used;
    _status = b?.status ?? BikeStatus.available;
    _purchaseDate = b?.purchaseDate ?? DateTime.now();

    _partners = context.read<ShowroomProvider>().partners;
    if (!_isEdit) {
      for (final p in _partners) {
        _contribCtrls[p.id!] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _make, _model, _year, _reg, _chassis, _color, _mileage, _price, _notes,
      ..._contribCtrls.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _splitEqually() {
    final price = parseAmount(_price.text);
    if (price == null || price <= 0 || _partners.isEmpty) {
      showSnack(context, 'Enter the purchase price first.');
      return;
    }
    final share = roundMoney(price / _partners.length);
    var allocated = 0.0;
    for (var i = 0; i < _partners.length; i++) {
      // Last partner absorbs the rounding remainder so the total is exact.
      final amt = i == _partners.length - 1 ? roundMoney(price - allocated) : share;
      allocated += amt;
      _contribCtrls[_partners[i].id!]!.text = amt.toString();
    }
    setState(() {});
  }

  double get _funded => _contribCtrls.values
      .fold(0.0, (a, c) => a + (parseAmount(c.text) ?? 0));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final price = parseAmount(_price.text)!;

    final contributions = <int, double>{};
    _contribCtrls.forEach((pid, c) {
      final v = parseAmount(c.text);
      if (v != null && v > 0) contributions[pid] = v;
    });
    final funded = contributions.values.fold(0.0, (a, b) => a + b);
    if (contributions.isNotEmpty && (funded - price).abs() > 0.01) {
      showSnack(
        context,
        'Partner contributions (${money(funded)}) must equal the '
        'purchase price (${money(price)}).',
      );
      return;
    }

    final bike = Bike(
      id: widget.existing?.id,
      make: _make.text.trim(),
      model: _model.text.trim(),
      year: int.parse(_year.text.trim()),
      condition: _condition,
      registrationNo: nullIfBlank(_reg.text),
      chassisNo: nullIfBlank(_chassis.text),
      color: nullIfBlank(_color.text),
      mileageKm: int.tryParse(_mileage.text.trim()),
      purchasePrice: price,
      purchaseDate: _purchaseDate,
      status: _status,
      notes: nullIfBlank(_notes.text),
    );

    setState(() => _saving = true);
    try {
      await context.read<ShowroomProvider>().saveBike(bike, contributions);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Could not save: ${friendlyError(e)}');
      }
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit bike' : 'Add bike')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<BikeCondition>(
              segments: [
                for (final c in BikeCondition.values)
                  ButtonSegment(value: c, label: Text(c.label)),
              ],
              selected: {_condition},
              onSelectionChanged: (s) => setState(() => _condition = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _make,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Make'),
              validator: _required,
            ),
            TextFormField(
              controller: _model,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Model'),
              validator: _required,
            ),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Year'),
                  validator: (v) {
                    final y = int.tryParse(v ?? '');
                    return (y == null || y < 1950 || y > DateTime.now().year + 1)
                        ? 'Invalid year'
                        : null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _mileage,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Mileage (km)'),
                ),
              ),
            ]),
            TextFormField(
              controller: _reg,
              textCapitalization: TextCapitalization.characters,
              decoration:
                  const InputDecoration(labelText: 'Registration no. (optional)'),
            ),
            TextFormField(
              controller: _chassis,
              textCapitalization: TextCapitalization.characters,
              decoration:
                  const InputDecoration(labelText: 'Chassis no. (optional)'),
            ),
            TextFormField(
              controller: _color,
              decoration: const InputDecoration(labelText: 'Color (optional)'),
            ),
            TextFormField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Purchase price'),
              validator: validateAmount,
              onChanged: (_) => setState(() {}),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Purchase date: ${dateStr(_purchaseDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _purchaseDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _purchaseDate = d);
              },
            ),
            if (_status != BikeStatus.sold)
              DropdownButtonFormField<BikeStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  for (final s in BikeStatus.values.where((s) => s != BikeStatus.sold))
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            if (!_isEdit) ...[
              const SectionHeader('Partner funding'),
              if (_partners.isEmpty)
                const Text(
                    'No partners yet. Add partners in the Partners tab to record who funded this bike.')
              else ...[
                for (final p in _partners)
                  TextFormField(
                    controller: _contribCtrls[p.id!],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: '${p.name} paid'),
                    onChanged: (_) => setState(() {}),
                  ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Text(
                      'Funded ${money(_funded)} of ${money(parseAmount(_price.text) ?? 0)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                      onPressed: _splitEqually, child: const Text('Split equally')),
                ]),
              ],
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
