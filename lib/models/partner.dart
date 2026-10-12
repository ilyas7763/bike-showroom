class Partner {
  final int? id;
  final String name;
  final String? phone;

  const Partner({this.id, required this.name, this.phone});

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
      };

  factory Partner.fromMap(Map<String, Object?> m) => Partner(
        id: m['id'] as int,
        name: m['name'] as String,
        phone: m['phone'] as String?,
      );
}
