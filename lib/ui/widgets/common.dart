import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/enums.dart';

Color statusColor(BikeStatus s) => switch (s) {
      BikeStatus.available => Colors.green,
      BikeStatus.reserved => Colors.orange,
      BikeStatus.sold => Colors.blueGrey,
      BikeStatus.underRepair => Colors.red,
    };

Color profitColor(double v) =>
    v >= 0 ? Colors.green.shade700 : Colors.red.shade700;

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final BikeStatus status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        border: Border.all(color: c),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.label,
          style:
              TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// "Label ........ Rs 1,000" row used in summary cards.
class AmountRow extends StatelessWidget {
  const AmountRow(this.label, this.value,
      {super.key, this.bold = false, this.color});
  final String label;
  final double value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(money(value), style: style),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (action != null) action!,
          ],
        ),
      );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String friendlyError(Object e) {
  final s = e.toString();
  if (s.contains('UNIQUE')) return 'That chassis number already exists.';
  if (s.contains('FOREIGN KEY')) {
    return 'This record is still in use and cannot be removed.';
  }
  return s.replaceFirst('Bad state: ', '').replaceFirst('Invalid argument(s): ', '');
}
