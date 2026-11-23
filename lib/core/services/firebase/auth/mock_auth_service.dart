import 'dart:async';
import 'i_auth_service.dart';

/// Local offline fallback authentication service
class MockAuthService implements IAuthService {
  final _controller = StreamController<UserSession?>.broadcast();
  UserSession? _currentUser;

  @override
  Stream<UserSession?> get authStateChanges => _controller.stream;

  @override
  UserSession? get currentUser => _currentUser;

  @override
  bool get isCloudConnected => false;

  MockAuthService({bool autoSignInGuest = true}) {
    if (autoSignInGuest) {
      _currentUser = UserSession(
        id: 'usr_mock_citizen_01',
        email: 'citizen@wasteway.local',
        displayName: 'Guest Eco-Citizen',
        isAnonymous: true,
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Future<UserSession> signInAnonymously() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = UserSession(
      id: 'usr_mock_anon_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Anonymous Eco-Citizen',
      isAnonymous: true,
      createdAt: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserSession> signInWithEmailPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = UserSession(
      id: 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: email,
      displayName: email.split('@').first,
      isAnonymous: false,
      createdAt: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserSession> registerWithEmailPassword(String email, String password, {String? displayName}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _currentUser = UserSession(
      id: 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: email,
      displayName: displayName ?? email.split('@').first,
      isAnonymous: false,
      createdAt: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
