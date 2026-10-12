import '../core/formatters.dart';

/// Money a partner put in. [bikeId] == null means general business capital.
class Contribution {
  final int? id;
  final int partnerId;
  final int? bikeId;
  final double amount;
  final DateTime date;
  final String? note;
  final String? partnerName; // populated by joined queries only

  const Contribution({
    this.id,
    required this.partnerId,
    this.bikeId,
    required this.amount,
    required this.date,
    this.note,
    this.partnerName,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'partner_id': partnerId,
        'bike_id': bikeId,
        'amount': amount,
        'contribution_date': isoDate(date),
        'note': note,
      };

  factory Contribution.fromMap(Map<String, Object?> m) => Contribution(
        id: m['id'] as int,
        partnerId: m['partner_id'] as int,
        bikeId: m['bike_id'] as int?,
        amount: (m['amount'] as num).toDouble(),
        date: DateTime.parse(m['contribution_date'] as String),
        note: m['note'] as String?,
        partnerName: m['partner_name'] as String?,
      );
}
