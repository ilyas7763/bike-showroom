import '../core/formatters.dart';

/// [bikeId] set  -> expense attached to a bike (affects its net profit).
/// [bikeId] null -> general daily showroom expense (rent, bills, ...).
class Expense {
  final int? id;
  final int? bikeId;
  final String category;
  final String? description;
  final double amount;
  final DateTime date;

  const Expense({
    this.id,
    this.bikeId,
    required this.category,
    this.description,
    required this.amount,
    required this.date,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'bike_id': bikeId,
        'category': category,
        'description': description,
        'amount': amount,
        'expense_date': isoDate(date),
      };

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int,
        bikeId: m['bike_id'] as int?,
        category: m['category'] as String,
        description: m['description'] as String?,
        amount: (m['amount'] as num).toDouble(),
        date: DateTime.parse(m['expense_date'] as String),
      );
}
