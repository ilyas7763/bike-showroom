import '../core/formatters.dart';

class Sale {
  final int? id;
  final int bikeId;
  final String buyerName;
  final String? buyerPhone;
  final double salePrice;
  final DateTime saleDate;
  final String? notes;

  const Sale({
    this.id,
    required this.bikeId,
    required this.buyerName,
    this.buyerPhone,
    required this.salePrice,
    required this.saleDate,
    this.notes,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'bike_id': bikeId,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'sale_price': salePrice,
        'sale_date': isoDate(saleDate),
        'notes': notes,
      };

  factory Sale.fromMap(Map<String, Object?> m) => Sale(
        id: m['id'] as int,
        bikeId: m['bike_id'] as int,
        buyerName: m['buyer_name'] as String,
        buyerPhone: m['buyer_phone'] as String?,
        salePrice: (m['sale_price'] as num).toDouble(),
        saleDate: DateTime.parse(m['sale_date'] as String),
        notes: m['notes'] as String?,
      );
}

/// A sale joined with its bike's cost data for the sales-history screen.
class SaleRecord {
  final Sale sale;
  final String bikeTitle;
  final double purchasePrice;
  final double totalExpenses;

  const SaleRecord({
    required this.sale,
    required this.bikeTitle,
    required this.purchasePrice,
    required this.totalExpenses,
  });

  double get totalCost => purchasePrice + totalExpenses;
  double get netProfit => sale.salePrice - totalCost;

  factory SaleRecord.fromMap(Map<String, Object?> m) => SaleRecord(
        sale: Sale.fromMap(m),
        bikeTitle: '${m['year']} ${m['make']} ${m['model']}',
        purchasePrice: (m['purchase_price'] as num).toDouble(),
        totalExpenses: (m['total_expenses'] as num).toDouble(),
      );
}
