class Choir {
  Choir({
    required this.id,
    required this.name,
    this.description,
    this.leaderPassword,
  });

  final String id;
  final String name;
  final String? description;
  /// Contraseña para que un miembro se convierta en jefe de grupo (admin_coro).
  /// Se guarda en Firestore; no hardcodear en la app.
  final String? leaderPassword;

  factory Choir.fromMap(String id, Map<String, dynamic> data) {
    return Choir(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      leaderPassword: data['leaderPassword'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      if (leaderPassword != null) 'leaderPassword': leaderPassword,
    };
  }
}

