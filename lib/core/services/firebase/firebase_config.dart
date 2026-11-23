import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Operational mode for WasteWay backend services
enum BackendMode {
  /// Local offline fallback mode using SharedPreferences and in-memory mock services.
  /// Active when Firebase credentials/configuration have not yet been provided.
  localMock,

  /// Live Cloud Firebase mode using Firebase Auth, Cloud Firestore, and Firebase Storage.
  cloudConnected,
}

/// Manages Firebase initialization and detects whether live cloud credentials exist.
class FirebaseConfig {
  FirebaseConfig._();

  static BackendMode _currentMode = BackendMode.localMock;
  static String? _initializationMessage;
  static bool _hasAttemptedInit = false;

  static BackendMode get currentMode => _currentMode;
  static bool get isCloudConnected => _currentMode == BackendMode.cloudConnected;
  static String get statusMessage => _initializationMessage ?? 'Operating in Local Offline Storage Mode';

  /// Attempts to initialize Firebase gracefully.
  /// If no Firebase configuration files or credentials are provided,
  /// it safely falls back to [BackendMode.localMock] without crashing.
  static Future<BackendMode> initialize() async {
    if (_hasAttemptedInit) return _currentMode;
    _hasAttemptedInit = true;
    try {
      // Check if default app is already initialized
      if (Firebase.apps.isNotEmpty) {
        _currentMode = BackendMode.cloudConnected;
        _initializationMessage = 'Connected to Cloud Firebase (${Firebase.app().name})';
        debugPrint('[WasteWay Firebase] $_initializationMessage');
        return _currentMode;
      }

      // Attempt initialization with a 1-second timeout to prevent deadlocks
      // when running without native platform plugins or configuration files.
      final app = await Firebase.initializeApp().timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw TimeoutException('Firebase initialization timed out (no cloud config).'),
      );
      _currentMode = BackendMode.cloudConnected;
      _initializationMessage = 'Connected to Cloud Firebase (${app.name})';
      debugPrint('[WasteWay Firebase] $_initializationMessage');
      return _currentMode;
    } catch (e) {
      _currentMode = BackendMode.localMock;
      _initializationMessage =
          'Local Offline Fallback Mode active. (Cloud Firebase not yet configured)';
      debugPrint('[WasteWay Firebase] $statusMessage');
      return _currentMode;
    }
  }

  /// Manually set the backend mode (for testing and mock simulations)
  static void setModeForTesting(BackendMode mode) {
    _currentMode = mode;
  }
}
