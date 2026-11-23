import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteway/core/services/firebase/firebase_config.dart';
import 'package:wasteway/core/services/firebase/firebase_service_manager.dart';
import 'package:wasteway/core/services/firebase/auth/mock_auth_service.dart';
import 'package:wasteway/core/services/firebase/database/mock_cloud_database_service.dart';
import 'package:wasteway/core/services/firebase/storage/mock_cloud_storage_service.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';
import 'package:wasteway/features/passport/presentation/providers/passport_provider.dart';
import 'package:wasteway/features/civic_reports/domain/models/civic_report_model.dart';
import 'package:wasteway/features/civic_reports/presentation/providers/civic_report_provider.dart';
import 'package:wasteway/features/home/presentation/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 7: FirebaseConfig & Service Mode Tests', () {
    test('Default mode is localMock when no cloud credentials exist', () {
      expect(FirebaseConfig.currentMode, BackendMode.localMock);
      expect(FirebaseConfig.isCloudConnected, isFalse);
      expect(FirebaseConfig.statusMessage, contains('Local'));
    });

    test('FirebaseServiceManager initializes local mock services cleanly', () async {
      final manager = FirebaseServiceManager();
      await manager.initialize();

      expect(manager.isInitialized, isTrue);
      expect(manager.backendMode, BackendMode.localMock);
      expect(manager.isCloudConnected, isFalse);
      expect(manager.auth, isA<MockAuthService>());
      expect(manager.database, isA<MockCloudDatabaseService>());
      expect(manager.storage, isA<MockCloudStorageService>());
    });
  });

  group('Phase 7: Mock Authentication Service Tests', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService(autoSignInGuest: false);
    });

    tearDown(() {
      authService.dispose();
    });

    test('Signs in anonymously and broadcasts user session on stream', () async {
      expect(authService.currentUser, isNull);

      final expectation = expectLater(
        authService.authStateChanges,
        emits(predicate<dynamic>((user) => user != null && user.isAnonymous == true)),
      );

      final user = await authService.signInAnonymously();
      expect(user.isAnonymous, isTrue);
      expect(user.displayName, contains('Citizen'));
      expect(authService.currentUser?.id, user.id);

      await expectation;
    });

    test('Registers and signs in with email/password', () async {
      final registered = await authService.registerWithEmailPassword(
        'student@college.edu',
        'securePass123',
        displayName: 'Eco Pioneer',
      );

      expect(registered.email, 'student@college.edu');
      expect(registered.displayName, 'Eco Pioneer');
      expect(registered.isAnonymous, isFalse);
      expect(authService.currentUser?.email, 'student@college.edu');

      // Sign out
      await authService.signOut();
      expect(authService.currentUser, isNull);

      // Sign in with email
      final loggedIn = await authService.signInWithEmailPassword(
        'student@college.edu',
        'securePass123',
      );
      expect(loggedIn.email, 'student@college.edu');
      expect(authService.currentUser?.email, 'student@college.edu');
    });
  });

  group('Phase 7: Mock Cloud Database & Local Storage Tests', () {
    late MockCloudDatabaseService dbService;

    setUp(() {
      dbService = MockCloudDatabaseService();
    });

    test('Saves and fetches waste passports from local storage', () async {
      final passport = WastePassportModel(
        id: 'DWP-FB-TEST-01',
        itemName: 'Recycled Aluminum Can',
        primaryMaterial: 'Metal',
        subType: 'Aluminum Alloy',
        confidenceScore: 0.95,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '200-500 years',
        estimatedCarbonKg: '0.12 kg CO2e',
        materialComposition: {'Aluminum': 100},
        handlingInstructions: ['Rinse and crush.'],
        circularityGuidance: {'recycle': 'Indefinitely recyclable.'},
        createdAt: DateTime.now(),
      );

      await dbService.savePassport(passport);
      final fetched = await dbService.fetchPassports();

      expect(fetched.any((p) => p.id == 'DWP-FB-TEST-01'), isTrue);

      // Delete
      await dbService.deletePassport('DWP-FB-TEST-01');
      final afterDelete = await dbService.fetchPassports();
      expect(afterDelete.any((p) => p.id == 'DWP-FB-TEST-01'), isFalse);
    });

    test('Saves, updates, and deletes civic reports from local storage', () async {
      final report = CivicReportModel(
        id: 'CR-FB-TEST-01',
        title: 'Overflowing Plastic Bin',
        issueCategory: 'Overflowing Public Bins',
        severity: IssueSeverity.moderate,
        description: 'Trash container overfilled at transit stop.',
        locationAddress: 'South Bus Terminal Gate 2',
        status: ReportStatus.submitted,
        createdAt: DateTime.now(),
      );

      await dbService.saveCivicReport(report);
      final fetched = await dbService.fetchCivicReports();
      expect(fetched.any((r) => r.id == 'CR-FB-TEST-01'), isTrue);

      // Update status
      await dbService.updateCivicReportStatus(
        'CR-FB-TEST-01',
        ReportStatus.underReview,
        statusNote: 'Ward supervisor notified.',
      );

      final updatedList = await dbService.fetchCivicReports();
      final updatedReport = updatedList.firstWhere((r) => r.id == 'CR-FB-TEST-01');
      expect(updatedReport.status, ReportStatus.underReview);
      expect(updatedReport.statusNote, 'Ward supervisor notified.');

      // Delete
      await dbService.deleteCivicReport('CR-FB-TEST-01');
      final afterDelete = await dbService.fetchCivicReports();
      expect(afterDelete.any((r) => r.id == 'CR-FB-TEST-01'), isFalse);
    });
  });

  group('Phase 7: Mock Storage Service Tests', () {
    test('Encodes raw bytes to accessible data URI', () async {
      final storage = MockCloudStorageService();
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final uri = await storage.uploadImage(sampleBytes, 'evidence/test.jpg');
      expect(uri, isNotNull);
      expect(uri!, startsWith('data:image/jpeg;base64,'));
    });
  });

  group('Phase 7: Provider Integration with Firebase Service Layer', () {
    test('PassportProvider delegates to FirebaseServiceManager without crashing', () async {
      await FirebaseServiceManager().initialize();
      final provider = PassportProvider();

      final newPassport = WastePassportModel(
        id: 'DWP-FB-INTEG-01',
        itemName: 'Glass Bottle',
        primaryMaterial: 'Glass',
        subType: 'Flint Glass',
        confidenceScore: 0.98,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '1,000,000+ years',
        estimatedCarbonKg: '0.20 kg CO2e',
        materialComposition: {'Silica': 70, 'Soda Ash': 15, 'Limestone': 15},
        handlingInstructions: ['Rinse thoroughly.'],
        circularityGuidance: {'reuse': 'Wash and refill.'},
        createdAt: DateTime.now(),
      );

      await provider.addPassport(newPassport);
      expect(provider.passports.first.id, 'DWP-FB-INTEG-01');

      await provider.deletePassport('DWP-FB-INTEG-01');
      expect(provider.passports.any((p) => p.id == 'DWP-FB-INTEG-01'), isFalse);
    });

    test('CivicReportProvider delegates to FirebaseServiceManager without crashing', () async {
      await FirebaseServiceManager().initialize();
      final provider = CivicReportProvider();

      final report = await provider.submitReport(
        title: 'Unattended Construction Rubble',
        issueCategory: 'Illegal Dumping',
        severity: IssueSeverity.high,
        description: 'Blocks footway completely.',
        locationAddress: 'Corner of 14th Cross',
      );

      expect(report.id, startsWith('CR-2026-'));
      expect(provider.reports.first.id, report.id);

      // Status update
      await provider.updateReportStatus(report.id, ReportStatus.resolved);
      expect(provider.reports.first.status, ReportStatus.resolved);
    });
  });

  group('Phase 7: UI & Backend Status Indicator Widget Tests', () {
    testWidgets('HomeScreen renders BackendStatusChip and opens info dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await FirebaseServiceManager().initialize();

      await tester.pumpWidget(
        ChangeNotifierProvider<FirebaseServiceManager>.value(
          value: FirebaseServiceManager(),
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: BackendStatusChip(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that the backend status chip is visible
      expect(find.text('Local Storage'), findsOneWidget);

      // Tap on the chip to open dialog
      await tester.tap(find.text('Local Storage'));
      await tester.pumpAndSettle();

      // Verify dialog contents
      expect(find.text('Local Offline Fallback Mode'), findsOneWidget);
      expect(find.textContaining('SharedPreferences'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Local Offline Fallback Mode'), findsNothing);
    });
  });
}
