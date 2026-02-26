class AppUser {
  AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.role,
    this.choirId,
    this.voice,
  });

  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String role; // 'super_admin' | 'admin_coro' | 'miembro'
  final String? choirId;
  final String? voice; // 'tenor' | 'bajo' | 'contralto' | 'soprano' | etc.

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      role: data['role'] as String? ?? 'miembro',
      choirId: data['choirId'] as String?,
      voice: data['voice'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'choirId': choirId,
      'voice': voice,
    };
  }

  bool get hasCompletedProfile => choirId != null && voice != null;
}

