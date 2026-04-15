class Place {
  const Place({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final int id;
  final String name;
  final DateTime createdAt;

  factory Place.fromMap(Map<String, Object?> map) {
    return Place(
      id: map['id']! as int,
      name: map['name']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    );
  }
}
