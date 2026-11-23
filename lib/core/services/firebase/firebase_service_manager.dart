import 'package:flutter/foundation.dart';
import 'firebase_config.dart';
import 'auth/i_auth_service.dart';
import 'auth/mock_auth_service.dart';
import 'auth/firebase_auth_service.dart';
import 'database/i_cloud_database_service.dart';
import 'database/mock_cloud_database_service.dart';
import 'database/firestore_database_service.dart';
import 'storage/i_cloud_storage_service.dart';
import 'storage/mock_cloud_storage_service.dart';
import 'storage/firebase_storage_service.dart';

/// Central coordinator for WasteWay Firebase and local fallback services
class FirebaseServiceManager extends ChangeNotifier {
  static final FirebaseServiceManager _instance = FirebaseServiceManager._internal();
  factory FirebaseServiceManager() => _instance;
  FirebaseServiceManager._internal() {
    // Default to mock offline services so any uninitialized access safely falls back to local storage
    _authService = MockAuthService();
    _databaseService = MockCloudDatabaseService();
    _storageService = MockCloudStorageService();
  }

  late IAuthService _authService;
  late ICloudDatabaseService _databaseService;
  late ICloudStorageService _storageService;

  IAuthService get auth => _authService;
  ICloudDatabaseService get database => _databaseService;
  ICloudStorageService get storage => _storageService;

  BackendMode get backendMode => FirebaseConfig.currentMode;
  bool get isCloudConnected => FirebaseConfig.isCloudConnected;
  String get statusMessage => FirebaseConfig.statusMessage;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes the service layer.
  /// Seamlessly selects either live Firebase or local mock fallbacks.
  Future<void> initialize() async {
    if (_isInitialized) return;
    final mode = await FirebaseConfig.initialize();

    if (mode == BackendMode.cloudConnected) {
      _authService = FirebaseAuthService();
      _databaseService = FirestoreDatabaseService();
      _storageService = FirebaseCloudStorageService();
      debugPrint('[FirebaseServiceManager] Active services: Cloud Firebase (Live)');
    } else {
      _authService = MockAuthService();
      _databaseService = MockCloudDatabaseService();
      _storageService = MockCloudStorageService();
      debugPrint('[FirebaseServiceManager] Active services: Local Mock Storage (Offline fallback)');
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Synchronizes local offline passports and civic reports to Cloud Firestore
  /// once cloud credentials become available.
  Future<int> syncLocalDataToCloud() async {
    if (!isCloudConnected) {
      debugPrint('[FirebaseServiceManager] Cannot sync: Still in Local Mock Mode.');
      return 0;
    }

    int syncedCount = 0;
    try {
      final localDb = MockCloudDatabaseService();
      final localPassports = await localDb.fetchPassports();
      for (final p in localPassports) {
        await _databaseService.savePassport(p);
        syncedCount++;
      }

      final localReports = await localDb.fetchCivicReports();
      for (final r in localReports) {
        await _databaseService.saveCivicReport(r);
        syncedCount++;
      }

      debugPrint('[FirebaseServiceManager] Successfully synced $syncedCount items to Cloud Firestore.');
    } catch (e) {
      debugPrint('[FirebaseServiceManager] Sync failed: $e');
    }
    return syncedCount;
  }

  /// Allows manually injecting custom service implementations (for unit and widget tests)
  @visibleForTesting
  void injectServicesForTesting({
    required IAuthService auth,
    required ICloudDatabaseService database,
    required ICloudStorageService storage,
    BackendMode mode = BackendMode.localMock,
  }) {
    _authService = auth;
    _databaseService = database;
    _storageService = storage;
    FirebaseConfig.setModeForTesting(mode);
    _isInitialized = true;
    notifyListeners();
  }
}
