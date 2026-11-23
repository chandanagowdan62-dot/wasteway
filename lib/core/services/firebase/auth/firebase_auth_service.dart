import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'i_auth_service.dart';

/// Live Firebase Authentication service implementation
class FirebaseAuthService implements IAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  @override
  bool get isCloudConnected => true;

  @override
  Stream<UserSession?> get authStateChanges {
    return _auth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  UserSession? get currentUser {
    return _mapFirebaseUser(_auth.currentUser);
  }

  @override
  Future<UserSession> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        throw Exception('Firebase anonymous sign in returned a null user.');
      }
      return _mapFirebaseUser(user)!;
    } catch (e) {
      debugPrint('[FirebaseAuthService] signInAnonymously failed: $e');
      rethrow;
    }
  }

  @override
  Future<UserSession> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Firebase sign in returned a null user.');
      }
      return _mapFirebaseUser(user)!;
    } catch (e) {
      debugPrint('[FirebaseAuthService] signInWithEmailPassword failed: $e');
      rethrow;
    }
  }

  @override
  Future<UserSession> registerWithEmailPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Firebase registration returned a null user.');
      }

      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      return _mapFirebaseUser(user)!;
    } catch (e) {
      debugPrint('[FirebaseAuthService] registerWithEmailPassword failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  UserSession? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return UserSession(
      id: user.uid,
      email: user.email,
      displayName: user.displayName ?? (user.isAnonymous ? 'Anonymous Citizen' : (user.email?.split('@').first ?? 'Citizen')),
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }
}
