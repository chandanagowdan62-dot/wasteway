// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteway/core/config/ai_config.dart';
import 'package:wasteway/features/facilities/domain/models/recycling_facility_model.dart';
import 'package:wasteway/features/facilities/presentation/providers/facility_provider.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';
import 'package:wasteway/features/scanner/data/services/gemini_vision_service.dart';
import 'package:wasteway/features/scanner/data/services/hybrid_ai_classification_service.dart';
import 'package:wasteway/features/scanner/data/services/mock_ai_classification_service.dart';
import 'package:wasteway/features/scanner/data/services/mock_waste_sample_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AIConfig.init();
    await AIConfig.clearRuntimeApiKey();
    await AIConfig.setForceMockMode(false);
  });

  group('A. Live AI vs Offline Simulation Dispatch & Key Transparency', () {
    test('Without Gemini API key and without allowOfflineSimulation, throws MissingApiKeyException', () async {
      expect(AIConfig.hasApiKey, isFalse);
      expect(AIConfig.isForceMockMode, isFalse);

      final hybrid = HybridAIClassificationService();
      final sampleBytes = MockWasteSampleImage.getSampleImageBytes('bottle.jpg');

      expect(
        () => hybrid.classify(
          imageBytes: sampleBytes,
          fileName: 'camera_capture.jpg',
          allowOfflineSimulation: false,
        ),
        throwsA(isA<MissingApiKeyException>()),
      );
    });

    test('Explicit offline simulation returns simulated passport with transparent demo badges', () async {
      final hybrid = HybridAIClassificationService();
      final sampleBytes = MockWasteSampleImage.getSampleImageBytes('chips_wrapper.jpg');

      final result = await hybrid.classify(
        imageBytes: sampleBytes,
        fileName: 'chips_wrapper.jpg',
        allowOfflineSimulation: true,
      );

      expect(result.isFallback, isTrue);
      expect(result.passport.isSimulated, isTrue);
      expect(result.passport.simulationNotice, isNotNull);
      expect(result.passport.simulationNotice, contains('Not classified by live AI'));
      expect(result.providerUsed, contains('Offline Simulation'));
    });

    test('Forced Mock Mode reliably executes mock service regardless of runtime API key', () async {
      await AIConfig.setRuntimeApiKey('AIzaSyFakeTestKey_MockMode01');
      await AIConfig.setForceMockMode(true);
      expect(AIConfig.hasApiKey, isTrue);
      expect(AIConfig.isForceMockMode, isTrue);

      final hybrid = HybridAIClassificationService();
      final sampleBytes = MockWasteSampleImage.getSampleImageBytes('tissue_paper.jpg');

      final result = await hybrid.classify(
        imageBytes: sampleBytes,
        fileName: 'tissue_paper.jpg',
      );

      expect(result.passport.isSimulated, isTrue);
      expect(result.passport.primaryMaterial, equals('Paper & Cardboard'));
      expect(result.passport.itemName, contains('Tissue'));
    });

    test('Live Gemini service targets gemini-3.8-flash with structured schema', () {
      final gemini = GeminiVisionService();
      expect(gemini.modelName, equals('gemini-3.8-flash'));
      expect(gemini.isOnlineService, isTrue);
      expect(gemini.providerName, contains('gemini-3.8-flash'));
    });

    test('Live Gemini client parses multimodal response correctly into non-simulated passport', () async {
      await AIConfig.setRuntimeApiKey('AIzaSyFakeTestKey_LiveMockClient02');

      final mockResponseJson = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'isIdentifiedWaste': true,
                    'itemName': 'Multi-Layer Chips & Snack Wrapper',
                    'primaryMaterial': 'Multi-Layer / Composite Materials',
                    'subType': 'Likely multilayer or metallised packaging. Exact material composition not confirmed.',
                    'confidenceScore': 0.94,
                    'recyclabilityGrade': 'C',
                    'degradationTime': '80 - 100 years',
                    'estimatedCarbonKg': '0.04 kg CO2e',
                    'materialComposition': {'BOPP Film': 85, 'Aluminium Foil': 15},
                    'handlingInstructions': [
                      'Shake out all dry food crumbs completely',
                      'Keep dry and flat; route to municipal DWCC or cement kiln coprocessing',
                      'If no specialized facility exists, segregate with municipal dry waste',
                      'Do NOT dispose in wet compost bins and do NOT incinerate in open air'
                    ],
                    'circularityGuidance': {
                      'reuse': 'Stuff into plastic bottles to create DIY eco-bricks',
                      'recycle': 'Coprocessing in cement kilns for energy recovery',
                      'safe_disposal': 'Store in designated orange/dry waste bin'
                    }
                  })
                }
              ]
            }
          }
        ]
      };

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('gemini-3.8-flash:generateContent'));
        expect(request.url.queryParameters['key'], equals('AIzaSyFakeTestKey_LiveMockClient02'));
        return http.Response(jsonEncode(mockResponseJson), 200);
      });

      final gemini = GeminiVisionService(client: mockClient);
      final passport = await gemini.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3, 4]),
        fileName: 'chips.jpg',
      );

      expect(passport.isSimulated, isFalse);
      expect(passport.confidenceScore, equals(0.94));
      expect(passport.primaryMaterial, equals('Multi-Layer / Composite Materials'));
      expect(passport.subType, equals('Likely multilayer or metallised packaging. Exact material composition not confirmed.'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.C));
      expect(passport.isHazardous, isFalse);
    });

    test('Gemini model is configurable dynamically via AIConfig without rewriting code', () async {
      await AIConfig.setModelName('gemini-3.5-flash-lite');
      final gemini = GeminiVisionService();
      expect(gemini.modelName, equals('gemini-3.5-flash-lite'));
      expect(gemini.providerName, contains('gemini-3.5-flash-lite'));

      await AIConfig.setModelName('gemini-3.8-flash');
      expect(gemini.modelName, equals('gemini-3.8-flash'));
    });

    test('Retired models auto-migrate to gemini-3.8-flash on initialization', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wasteway_gemini_model', 'gemini-2.0-flash');
      await AIConfig.init();
      expect(AIConfig.modelName, equals('gemini-3.8-flash'));

      await prefs.setString('wasteway_gemini_model', 'gemini-1.5-flash');
      await AIConfig.init();
      expect(AIConfig.modelName, equals('gemini-3.8-flash'));
    });

    test('Gemini vision service does not fallback to retired gemini-1.5-flash on 404', () async {
      await AIConfig.setRuntimeApiKey('AIzaSyFakeTestKey_NoFallback404_03');
      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        // Verify request target
        expect(request.url.toString(), contains('gemini-3.8-flash:generateContent'));
        expect(request.url.toString(), isNot(contains('gemini-1.5-flash')));
        return http.Response('Model not found', 404);
      });

      final gemini = GeminiVisionService(client: mockClient);
      await expectLater(
        gemini.classifyWasteImage(
          imageBytes: Uint8List.fromList([1, 2, 3, 4]),
          fileName: 'test.jpg',
        ),
        throwsA(predicate((e) => e.toString().contains('HTTP 404'))),
      );
      // Ensure only 1 call was made, with NO secondary fallback call to 1.5-flash
      expect(callCount, equals(1));
    });
  });

  group('B. Recognition Accuracy of Common Municipal Waste Items', () {
    final mockService = MockAIClassificationService();

    test('1. Chips packets & snack wrappers are classified as Multi-Layer / Composite Materials (NOT battery or bottle)', () async {
      final bytes = MockWasteSampleImage.getSampleImageBytes('lays_chips_packet.jpg');
      final passport = await mockService.classifyWasteImage(
        imageBytes: bytes,
        fileName: 'lays_chips_packet.jpg',
      );

      expect(passport.primaryMaterial, equals('Multi-Layer / Composite Materials'));
      expect(passport.subType, equals('Likely multilayer or metallised packaging. Exact material composition not confirmed.'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.C));
      expect(passport.isHazardous, isFalse);
      expect(passport.itemName.toLowerCase(), contains('chips'));
    });

    test('2. Paper tissues & napkins are classified as Paper & Cardboard with Grade D (non-recyclable in standard paper mills)', () async {
      final bytes = MockWasteSampleImage.getSampleImageBytes('used_tissue_napkin.jpg');
      final passport = await mockService.classifyWasteImage(
        imageBytes: bytes,
        fileName: 'used_tissue_napkin.jpg',
      );

      expect(passport.primaryMaterial, equals('Paper & Cardboard'));
      expect(passport.subType, equals('Cellulose Tissue Fiber'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.D));
      expect(passport.isHazardous, isFalse);
      expect(passport.circularityGuidance['compost'], isNotNull);
    });

    test('3. Plastic PET bottles are classified as Plastic with Grade A recyclability', () async {
      final bytes = MockWasteSampleImage.getSampleImageBytes('water_bottle.jpg');
      final passport = await mockService.classifyWasteImage(
        imageBytes: bytes,
        fileName: 'water_bottle.jpg',
      );

      expect(passport.primaryMaterial, equals('Plastic'));
      expect(passport.subType, contains('PET'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.A));
      expect(passport.isHazardous, isFalse);
    });

    test('4. Corrugated shipping boxes are classified as Paper & Cardboard with Grade A', () async {
      final bytes = MockWasteSampleImage.getSampleImageBytes('shipping_box.jpg');
      final passport = await mockService.classifyWasteImage(
        imageBytes: bytes,
        fileName: 'shipping_box.jpg',
      );

      expect(passport.primaryMaterial, equals('Paper & Cardboard'));
      expect(passport.subType, contains('Kraft'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.A));
      expect(passport.isHazardous, isFalse);
    });

    test('5. Aluminium cans are classified as Metals with Grade A', () async {
      final bytes = MockWasteSampleImage.getSampleImageBytes('soda_can.jpg');
      final passport = await mockService.classifyWasteImage(
        imageBytes: bytes,
        fileName: 'soda_can.jpg',
      );

      expect(passport.primaryMaterial, equals('Metals'));
      expect(passport.subType, contains('Aluminium'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.A));
      expect(passport.isHazardous, isFalse);
    });

    test('6. Glass jars and bottles are classified as Glass with Grade A or B', () async {
      final bytes = MockWasteSampleImage.getSampleImageBytes('glass_jar.jpg');
      final passport = await mockService.classifyWasteImage(
        imageBytes: bytes,
        fileName: 'glass_jar.jpg',
      );

      expect(passport.primaryMaterial, equals('Glass'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.B));
      expect(passport.isHazardous, isFalse);
    });

    test('7. Kitchen food scraps are classified as Biodegradable / Organic with Grade A', () async {
      final bytes = MockWasteSampleImage.getSampleImageBytes('food_scraps.jpg');
      final passport = await mockService.classifyWasteImage(
        imageBytes: bytes,
        fileName: 'food_scraps.jpg',
      );

      expect(passport.primaryMaterial, equals('Biodegradable / Organic'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.A));
      expect(passport.isHazardous, isFalse);
    });

    test('8. Textiles and garments are classified as Textiles & Fabrics with Grade B', () async {
      final bytes = MockWasteSampleImage.getSampleImageBytes('cotton_shirt.jpg');
      final passport = await mockService.classifyWasteImage(
        imageBytes: bytes,
        fileName: 'cotton_shirt.jpg',
      );

      expect(passport.primaryMaterial, equals('Textiles & Fabrics'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.B));
      expect(passport.isHazardous, isFalse);
    });

    test('9. Batteries are classified as E-Waste / Hazardous with Grade E and hazard flags', () async {
      final bytes = MockWasteSampleImage.getSampleImageBytes('lithium_battery.jpg');
      final passport = await mockService.classifyWasteImage(
        imageBytes: bytes,
        fileName: 'lithium_battery.jpg',
      );

      expect(passport.primaryMaterial, equals('Electronic Waste (E-Waste)'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.E));
      expect(passport.isHazardous, isTrue);
    });
  });

  group('C. Recycler Directory Audit & BSWML Government Authority Verification', () {
    late FacilityProvider facilityProvider;

    setUp(() {
      facilityProvider = FacilityProvider();
    });

    test('Directory contains exactly 8 verified Bengaluru recycling facilities', () {
      expect(facilityProvider.allFacilities.length, equals(8));
    });

    test('BSWML is registered as governmentAuthority with official state portal and BBMP citizen link', () {
      final bswml = facilityProvider.allFacilities.firstWhere((f) => f.id == 'FAC-BLR-04');

      expect(bswml.name, contains('Bengaluru Solid Waste Management Limited'));
      expect(bswml.name, contains('BSWML'));
      expect(bswml.facilityType, equals(FacilityType.governmentAuthority));
      expect(bswml.facilityType.label, equals('Government Waste-Management Authority'));
      expect(bswml.isDoorstepPlatform, isTrue);

      // Official URLs
      expect(bswml.website, equals('https://bswml.karnataka.gov.in/'));
      expect(bswml.portalUrl, equals('https://apps.bbmpgov.in/SWM/Home/Forms/Home.aspx'));

      // Disclaimers and drop-off instructions
      final instructions = bswml.dropOffInstructions.join(' ');
      expect(instructions, contains('state government waste management authority'));
      expect(instructions, contains('does NOT purchase scrap'));
      expect(instructions, contains('DWCC'));
    });

    test('All 8 directory facilities possess valid https URLs and verified source references', () {
      for (final facility in facilityProvider.allFacilities) {
        expect(facility.website, isNotNull, reason: '${facility.name} missing website');
        expect(facility.website!.startsWith('https://'), isTrue, reason: '${facility.name} URL not https');
        expect(facility.sourceReference, isNotNull);
        expect(facility.isVerified, isTrue);

        // Verify no fictitious fake phone numbers are displayed
        expect(facility.phone, isNull, reason: '${facility.name} should not contain unverified telephone numbers');
      }
    });

    test('Facility matching for Multi-Layer / Composite Materials correctly recommends BSWML, Ecocrew, Saahas, Hasiru Dala', () {
      facilityProvider.toggleMaterialFilter('Multi-Layer / Composite Materials');
      final matched = facilityProvider.filteredFacilities;

      final matchedIds = matched.map((f) => f.id).toList();
      expect(matchedIds.contains('FAC-BLR-04'), isTrue); // BSWML
      expect(matchedIds.contains('FAC-BLR-03'), isTrue); // Ecocrew
      expect(matchedIds.contains('FAC-BLR-05'), isTrue); // Saahas
      expect(matchedIds.contains('FAC-BLR-07'), isTrue); // Hasiru Dala
    });

    test('Facility matching for Textiles recommends Goonj', () {
      facilityProvider.toggleMaterialFilter('Textiles & Fabrics');
      final matched = facilityProvider.filteredFacilities;

      expect(matched.any((f) => f.id == 'FAC-BLR-08'), isTrue); // Goonj
    });

    test('Facility matching for E-Waste and Batteries recommends Enviro-Hub, Kabadify, KabadCart, Ecocrew', () {
      facilityProvider.toggleMaterialFilter('Electronic Waste (E-Waste)');
      final matched = facilityProvider.filteredFacilities;

      final matchedIds = matched.map((f) => f.id).toList();
      expect(matchedIds.contains('FAC-BLR-06'), isTrue); // Enviro-Hub KSPCB Authorized
      expect(matchedIds.contains('FAC-BLR-01'), isTrue); // Kabadify
      expect(matchedIds.contains('FAC-BLR-02'), isTrue); // KabadCart
    });
  });
}
