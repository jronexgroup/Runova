/// Wholesaler / Distributor / Supplier entity for inventory management.
class Supplier {
  final String id;
  final String name;
  final String phone;
  final String category;
  final String address;
  final DateTime createdAt;

  const Supplier({
    required this.id,
    required this.name,
    this.phone = '',
    this.category = 'General',
    this.address = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'category': category,
    'address': address,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Supplier.fromMap(Map<String, dynamic> map) => Supplier(
    id: map['id'] as String,
    name: map['name'] as String,
    phone: (map['phone'] ?? '') as String,
    category: (map['category'] ?? 'General') as String,
    address: (map['address'] ?? '') as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}
