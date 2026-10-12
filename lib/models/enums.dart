enum BikeCondition {
  brandNew,
  used;

  String get dbValue => this == BikeCondition.brandNew ? 'new' : 'used';
  String get label => this == BikeCondition.brandNew ? 'New' : 'Used';

  static BikeCondition fromDb(String v) =>
      v == 'new' ? BikeCondition.brandNew : BikeCondition.used;
}

enum BikeStatus {
  available,
  reserved,
  sold,
  underRepair;

  String get dbValue => switch (this) {
        BikeStatus.available => 'available',
        BikeStatus.reserved => 'reserved',
        BikeStatus.sold => 'sold',
        BikeStatus.underRepair => 'under_repair',
      };

  String get label => switch (this) {
        BikeStatus.available => 'Available',
        BikeStatus.reserved => 'Reserved',
        BikeStatus.sold => 'Sold',
        BikeStatus.underRepair => 'Under Repair',
      };

  static BikeStatus fromDb(String v) =>
      BikeStatus.values.firstWhere((s) => s.dbValue == v);
}
