import '../core/formatters.dart';
import 'enums.dart';

class Bike {
  final int? id;
  final String make;
  final String model;
  final int year;
  final BikeCondition condition;
  final String? registrationNo;
  final String? chassisNo;
  final String? color;
  final int? mileageKm;
  final double purchasePrice;
  final DateTime purchaseDate;
  final BikeStatus status;
  final String? notes;

  const Bike({
    this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.condition,
    this.registrationNo,
    this.chassisNo,
    this.color,
    this.mileageKm,
    required this.purchasePrice,
    required this.purchaseDate,
    this.status = BikeStatus.available,
    this.notes,
  });

  String get title => '$year $make $model';

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'make': make,
        'model': model,
        'year': year,
        'condition': condition.dbValue,
        'registration_no': registrationNo,
        'chassis_no': chassisNo,
        'color': color,
        'mileage_km': mileageKm,
        'purchase_price': purchasePrice,
        'purchase_date': isoDate(purchaseDate),
        'status': status.dbValue,
        'notes': notes,
      };

  factory Bike.fromMap(Map<String, Object?> m) => Bike(
        id: m['id'] as int,
        make: m['make'] as String,
        model: m['model'] as String,
        year: m['year'] as int,
        condition: BikeCondition.fromDb(m['condition'] as String),
        registrationNo: m['registration_no'] as String?,
        chassisNo: m['chassis_no'] as String?,
        color: m['color'] as String?,
        mileageKm: m['mileage_km'] as int?,
        purchasePrice: (m['purchase_price'] as num).toDouble(),
        purchaseDate: DateTime.parse(m['purchase_date'] as String),
        status: BikeStatus.fromDb(m['status'] as String),
        notes: m['notes'] as String?,
      );
}

/// A bike plus its aggregated costs (and sale price once sold).
class BikeSummary {
  final Bike bike;
  final double totalExpenses;
  final double? salePrice;

  const BikeSummary({
    required this.bike,
    required this.totalExpenses,
    this.salePrice,
  });

  double get totalCost => bike.purchasePrice + totalExpenses;

  /// Net profit = Sale Price - (Purchase Price + Bike Expenses). Null until sold.
  double? get netProfit => salePrice == null ? null : salePrice! - totalCost;

  factory BikeSummary.fromMap(Map<String, Object?> m) => BikeSummary(
        bike: Bike.fromMap(m),
        totalExpenses: (m['total_expenses'] as num).toDouble(),
        salePrice: (m['sale_price'] as num?)?.toDouble(),
      );
}
