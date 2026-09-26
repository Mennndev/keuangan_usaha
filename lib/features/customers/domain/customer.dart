class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.notes,
  });

  final String id;
  final String name;
  final String? phone;
  final String? notes;
}
