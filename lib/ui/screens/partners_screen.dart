import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/partner_summary.dart';
import '../../state/showroom_provider.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ShowroomProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Partners & capital')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Add partner'),
        onPressed: () async {
          final partner = await showPartnerDialog(context);
          if (partner != null) await p.addPartner(partner);
        },
      ),
      body: p.partnerSummaries.isEmpty
          ? const Center(child: Text('Add your partners to begin'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final s in p.partnerSummaries) _PartnerCard(s),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    'Profit share = each sold bike\'s net profit split in proportion '
                    'to what each partner contributed to that bike. General showroom '
                    'expenses are tracked separately and not deducted here.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard(this.s);
  final PartnerSummary s;

  @override
  Widget build(BuildContext context) {
    final p = context.read<ShowroomProvider>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(s.partner.name,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add capital'),
                onPressed: () async {
                  final c = await showContributionDialog(
                    context,
                    partners: p.partners,
                    initialPartnerId: s.partner.id,
                  );
                  if (c != null) await p.addContribution(c);
                },
              ),
            ]),
            if (s.partner.phone != null)
              Text(s.partner.phone!,
                  style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 20),
            AmountRow('Total invested', s.totalInvested, bold: true),
            AmountRow('  General capital', s.generalCapital),
            AmountRow('  In unsold bikes', s.capitalInStock),
            AmountRow('  In sold bikes', s.investedInSoldBikes),
            const Divider(height: 20),
            AmountRow('Profit share (sold bikes)', s.profitShare,
                color: profitColor(s.profitShare)),
            AmountRow('Payout due (capital + profit)', s.payoutDue, bold: true),
          ],
        ),
      ),
    );
  }
}
