import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../models/enums.dart';
import '../../state/showroom_provider.dart';
import '../widgets/common.dart';
import 'bike_detail_screen.dart';
import 'bike_form_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ShowroomProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add bike'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BikeFormScreen()),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search make, model, reg. or chassis no.',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: p.setSearch,
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _FilterChip(
                  label: 'All (${p.totalBikeCount})',
                  selected: p.statusFilter == null,
                  onTap: () => p.setStatusFilter(null),
                ),
                for (final s in BikeStatus.values)
                  _FilterChip(
                    label: '${s.label} (${p.statusCounts[s] ?? 0})',
                    selected: p.statusFilter == s,
                    onTap: () => p.setStatusFilter(s),
                  ),
              ],
            ),
          ),
          Expanded(
            child: p.bikes.isEmpty
                ? Center(
                    child: Text(p.loading ? 'Loading…' : 'No bikes found'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: p.bikes.length,
                    itemBuilder: (_, i) => _BikeCard(p.bikes[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}

class _BikeCard extends StatelessWidget {
  const _BikeCard(this.s);
  final BikeSummary s;

  @override
  Widget build(BuildContext context) {
    final b = s.bike;
    final profit = s.netProfit;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BikeDetailScreen(bikeId: b.id!)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(b.title,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  StatusChip(b.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                [
                  b.condition.label,
                  if (b.registrationNo != null) b.registrationNo!,
                  if (b.mileageKm != null) '${b.mileageKm} km',
                ].join(' • '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              AmountRow('Purchase', b.purchasePrice),
              AmountRow('Expenses', s.totalExpenses),
              AmountRow('Total cost', s.totalCost, bold: true),
              if (profit != null)
                AmountRow('Net profit', profit,
                    bold: true, color: profitColor(profit)),
            ],
          ),
        ),
      ),
    );
  }
}
