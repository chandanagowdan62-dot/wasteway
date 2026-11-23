/// Represents an authenticated or guest citizen user in WasteWay
class UserSession {
  final String id;
  final String? email;
  final String displayName;
  final bool isAnonymous;
  final DateTime createdAt;

  const UserSession({
    required this.id,
    this.email,
    required this.displayName,
    required this.isAnonymous,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String? ?? 'usr_guest',
      email: json['email'] as String?,
      displayName: json['displayName'] as String? ?? 'Citizen User',
      isAnonymous: json['isAnonymous'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Abstract contract for Authentication in WasteWay
abstract class IAuthService {
  Stream<UserSession?> get authStateChanges;
  UserSession? get currentUser;
  bool get isCloudConnected;

  Future<UserSession> signInAnonymously();
  Future<UserSession> signInWithEmailPassword(String email, String password);
  Future<UserSession> registerWithEmailPassword(String email, String password, {String? displayName});
  Future<void> signOut();
}
