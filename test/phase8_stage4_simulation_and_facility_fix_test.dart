import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteway/core/config/ai_config.dart';
import 'package:wasteway/core/theme/app_theme.dart';
import 'package:wasteway/features/facilities/presentation/providers/facility_provider.dart';
import 'package:wasteway/features/facilities/presentation/screens/facilities_screen.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';
import 'package:wasteway/features/passport/presentation/providers/passport_provider.dart';
import 'package:wasteway/features/passport/presentation/screens/passport_detail_screen.dart';
import 'package:wasteway/features/scanner/data/services/gemini_vision_service.dart';
import 'package:wasteway/features/scanner/data/services/hybrid_ai_classification_service.dart';
import 'package:wasteway/features/scanner/data/services/mock_ai_classification_service.dart';
import 'package:wasteway/features/scanner/data/services/mock_waste_sample_image.dart';
import 'package:wasteway/features/scanner/presentation/providers/scanner_provider.dart';
import 'package:wasteway/features/scanner/presentation/screens/scanner_screen.dart';

class _FailingGeminiService extends GeminiVisionService {
  @override
  Future<WastePassportModel> classifyWasteImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    throw Exception('Gemini API quota rate limit exceeded (429).');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('Waste Identification: Simulation Labelling & Error Handling Tests', () {
    test('MockAIClassificationService marks generated passports as isSimulated = true', () async {
      final mockService = MockAIClassificationService();
      final passport = await mockService.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'camera_capture_123.jpg',
      );

      expect(passport.isSimulated, isTrue);
      expect(passport.simulationNotice, isNotNull);
      expect(passport.simulationNotice, contains('Offline Simulation'));
      expect(passport.id, startsWith('DWP-SIM-'));
    });

    test('HybridAIClassificationService does NOT silently fallback to mock when Gemini throws and API key is set', () async {
      await AIConfig.setRuntimeApiKey('test_api_key_12345');
      await AIConfig.setForceMockMode(false);

      final failingGemini = _FailingGeminiService();
      final hybridService = HybridAIClassificationService(
        geminiService: failingGemini,
        mockService: MockAIClassificationService(),
      );

      expect(
        () => hybridService.classify(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'camera_capture_123.jpg',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Live Gemini AI Vision failed'),
        )),
      );

      await AIConfig.clearRuntimeApiKey();
    });

    test('ScannerProvider runOfflineSimulation creates simulated passport on demand', () async {
      final provider = ScannerProvider();
      provider.onImageSelected(Uint8List.fromList([1, 2, 3]), 'sample.jpg');

      final passport = await provider.runOfflineSimulation();
      expect(passport, isNotNull);
      expect(passport!.isSimulated, isTrue);
      expect(provider.lastResult?.isFallback, isTrue);
      expect(provider.currentStep, ScanStep.completed);
    });

    testWidgets('PassportDetailScreen displays prominent amber Simulation banner for simulated passports', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final simulatedPassport = WastePassportModel(
        id: 'DWP-SIM-9999',
        itemName: 'Simulated Plastic Bottle',
        primaryMaterial: 'Plastic',
        subType: 'PET (Type 1)',
        confidenceScore: 0.95,
        recyclabilityGrade: RecyclabilityGrade.A,
        degradationTime: '450 years',
        estimatedCarbonKg: '0.08 kg CO2e',
        materialComposition: {'PET': 100},
        handlingInstructions: ['Rinse before recycling'],
        circularityGuidance: {'recycle': 'Blue bin'},
        createdAt: DateTime.now(),
        isSimulated: true,
        simulationNotice: 'Demonstration Record (Offline Simulation) — Generated from local sample catalog. Not classified by live AI.',
      );

      final passportProvider = PassportProvider();
      passportProvider.addPassport(simulatedPassport);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: passportProvider),
            ChangeNotifierProvider(create: (_) => FacilityProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PassportDetailScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Amber banner must be displayed prominently
      expect(find.text('Simulation / Demo Record'), findsOneWidget);
      expect(find.textContaining('Generated from local sample catalog'), findsOneWidget);

      // Must display simulated template badge and NOT show misleading real confidence score
      expect(find.text('Demo Template (Simulated)'), findsOneWidget);
      expect(find.text('Confidence: 95%'), findsNothing);

      // Verified checkmark icon should not be used for simulated passports
      expect(find.byIcon(Icons.verified), findsNothing);
      expect(find.byIcon(Icons.science_outlined), findsWidgets);
    });

    testWidgets('ScannerScreen error state provides Retry, Update API Key, and Run Offline Simulation', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final scannerProvider = ScannerProvider();
      scannerProvider.onImageSelected(MockWasteSampleImage.getSampleImageBytes('sample.jpg'), 'sample.jpg');
      scannerProvider.setError('Gemini API quota rate limit exceeded (429).');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: scannerProvider),
            ChangeNotifierProvider(create: (_) => PassportProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ScannerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Classification Failed'), findsOneWidget);
      expect(find.textContaining('quota rate limit exceeded'), findsOneWidget);
      expect(find.text('Retry Analysis'), findsOneWidget);
      expect(find.text('Update API Key'), findsOneWidget);
      expect(find.text('Run Offline Simulation'), findsOneWidget);
    });
  });

  group('Facility Directory: Contact Removal & Verification Integrity Tests', () {
    test('All seeded facilities have fictitious phone and email removed', () {
      final provider = FacilityProvider();
      final facilities = provider.allFacilities;

      expect(facilities.length, 8);
      for (final f in facilities) {
        expect(f.phone, isNull, reason: 'Facility ${f.id} has phone: ${f.phone}');
        expect(f.email, isNull, reason: 'Facility ${f.id} has email: ${f.email}');
      }
    });

    test('All seeded facilities correspond to genuine Bengaluru platforms and centres', () {
      final provider = FacilityProvider();
      final facilities = provider.allFacilities;

      for (final f in facilities) {
        expect(f.isSampleData, isFalse, reason: 'Facility ${f.id} must be genuine platform');
        expect(f.isVerified, isTrue, reason: 'Facility ${f.id} must be verified platform');
        expect(f.website, isNotNull);
      }

      // Verify doorstep platforms vs physical facilities
      final doorstepPlatforms = facilities.where((f) => f.isDoorstepPlatform).toList();
      final physicalFacilities = facilities.where((f) => !f.isDoorstepPlatform).toList();

      expect(doorstepPlatforms.length, 4); // Kabadify, KabadCart, Ecocrew, Dclutter
      expect(physicalFacilities.length, 4); // Saahas, Enviro-Hub, Hasiru Dala, Goonj
    });

    test('Authentic website portal link is preserved for KSPCB official reference', () {
      final provider = FacilityProvider();
      final eWasteFacility = provider.allFacilities.firstWhere((f) => f.id == 'FAC-BLR-06');

      expect(eWasteFacility.website, 'https://kspcb.karnataka.gov.in');
    });

    testWidgets('FacilitiesScreen renders Doorstep Platform and Directions actions properly', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final facilityProvider = FacilityProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: facilityProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FacilitiesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Call Facility button must not appear since telephone numbers are unverified
      expect(find.text('Call Facility'), findsNothing);

      // Must display Doorstep Platform badge
      expect(find.text('Doorstep Platform'), findsWidgets);

      // Book Doorstep Pickup must be available
      expect(find.text('Book Doorstep Pickup'), findsWidgets);

      // Official portal button must be available
      expect(find.text('Official Portal'), findsWidgets);
    });
  });
}
