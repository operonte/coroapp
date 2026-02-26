class Choir {
  Choir({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory Choir.fromMap(String id, Map<String, dynamic> data) {
    return Choir(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }
}

