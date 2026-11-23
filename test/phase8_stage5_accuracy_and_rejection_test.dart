import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteway/core/config/ai_config.dart';
import 'package:wasteway/core/theme/app_theme.dart';
import 'package:wasteway/features/facilities/domain/models/recycling_facility_model.dart';
import 'package:wasteway/features/facilities/presentation/providers/facility_provider.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';
import 'package:wasteway/features/passport/presentation/providers/passport_provider.dart';
import 'package:wasteway/features/passport/presentation/screens/passport_detail_screen.dart';
import 'package:wasteway/features/scanner/data/services/gemini_vision_service.dart';
import 'package:wasteway/features/scanner/domain/services/ai_classification_service.dart';
import 'package:wasteway/features/scanner/domain/services/image_processing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AIConfig.init();
    await AIConfig.setRuntimeApiKey('test_gemini_api_key_accuracy_track');
  });

  group('Priority 1: Image Preprocessing & EXIF Orientation', () {
    test('ImageProcessingService normalizes image and applies bakeOrientation', () async {
      final service = ImageProcessingService();
      // Generate a synthetic test image
      final testImg = img.Image(width: 800, height: 600);
      img.fill(testImg, color: img.ColorRgb8(100, 200, 150));
      final encodedBytes = Uint8List.fromList(img.encodeJpg(testImg, quality: 90));

      final result = await service.preprocessImage(
        rawBytes: encodedBytes,
        maxDimension: 500,
        quality: 80,
      );

      expect(result.processedBytes, isNotEmpty);
      expect(result.width, lessThanOrEqualTo(500));
      expect(result.height, lessThanOrEqualTo(500));
      expect(result.compressionRatioPercent, greaterThanOrEqualTo(0));
    });
  });

  group('Priority 1: Gemini 3.8 Flash Vision Service Configuration', () {
    test('Default model is gemini-3.8-flash and endpoint targets v1beta generateContent', () async {
      late Uri capturedUrl;
      late Map<String, dynamic> capturedBody;

      final mockClient = MockClient((request) async {
        capturedUrl = request.url;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'isIdentifiedWaste': true,
                      'itemName': 'PET Beverage Bottle',
                      'primaryMaterial': 'Plastic',
                      'subType': 'Polyethylene Terephthalate (PET Type 1)',
                      'confidenceScore': 0.94,
                      'isAmbiguous': false,
                      'recyclabilityGrade': 'A',
                      'degradationTime': '450 years',
                      'estimatedCarbonKg': '0.08 kg CO2e',
                      'materialComposition': {'PET': 90, 'PP Cap': 10},
                      'handlingInstructions': ['Rinse clean', 'Crush flat'],
                      'circularityGuidance': {
                        'recycle': 'Deposit in Blue Dry-Waste bin',
                        'safe_disposal': 'Contain in dry stream',
                      },
                    }),
                  }
                ]
              }
            }
          ]
        };

        return http.Response(jsonEncode(responseJson), 200, headers: {'content-type': 'application/json'});
      });

      final service = GeminiVisionService(client: mockClient);
      expect(service.modelName, 'gemini-3.8-flash');
      expect(service.providerName, contains('gemini-3.8-flash'));

      final passport = await service.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3, 4]),
        fileName: 'sample_bottle.jpg',
      );

      expect(capturedUrl.toString(), contains('models/gemini-3.8-flash:generateContent'));
      expect(capturedUrl.queryParameters['key'], 'test_gemini_api_key_accuracy_track');

      // Verify prompt checks visible symbols
      final promptText = capturedBody['contents'][0]['parts'][0]['text'] as String;
      expect(promptText, contains('Resin Identification Codes'));
      expect(promptText, contains('RIC 1-7'));
      expect(promptText, contains('Textiles & Fabrics'));
      expect(promptText, contains('Multi-Layer / Composite Materials'));

      // Verify generation config specifies structured JSON output
      final genConfig = capturedBody['generationConfig'] as Map<String, dynamic>;
      expect(genConfig['responseMimeType'], 'application/json');

      expect(passport.itemName, 'PET Beverage Bottle');
      expect(passport.primaryMaterial, 'Plastic');
      expect(passport.subType, 'Polyethylene Terephthalate (PET Type 1)');
      expect(passport.confidenceScore, 0.94);
      expect(passport.isSimulated, isFalse);
    });

    test('Throws UnrecognizedWasteException when image is non-waste or unidentifiable', () async {
      final mockClient = MockClient((request) async {
        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'isIdentifiedWaste': false,
                      'nonWasteReason': 'Image depicts a domestic dog / pet rather than municipal waste.',
                      'itemName': 'Non-Waste Subject',
                      'primaryMaterial': 'Uncertain / Unknown',
                      'subType': 'Unknown',
                      'confidenceScore': 0.05,
                      'isAmbiguous': true,
                      'recyclabilityGrade': 'C',
                    }),
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(responseJson), 200, headers: {'content-type': 'application/json'});
      });

      final service = GeminiVisionService(client: mockClient);

      expect(
        () => service.classifyWasteImage(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'dog_photo.jpg',
        ),
        throwsA(isA<UnrecognizedWasteException>()),
      );
    });

    test('Throws FormatException when required fields are missing or invalid (no silent defaults)', () async {
      final mockClient = MockClient((request) async {
        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    // Malformed response missing primaryMaterial and recyclabilityGrade
                    'text': jsonEncode({
                      'isIdentifiedWaste': true,
                      'itemName': 'Broken Plastic Toy',
                      'confidenceScore': 0.85,
                    }),
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(responseJson), 200, headers: {'content-type': 'application/json'});
      });

      final service = GeminiVisionService(client: mockClient);

      expect(
        () => service.classifyWasteImage(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'toy.jpg',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('Parses ambiguous response with alternative candidate materials', () async {
      final mockClient = MockClient((request) async {
        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'isIdentifiedWaste': true,
                      'itemName': 'Clear Clamshell Container',
                      'primaryMaterial': 'Plastic',
                      'subType': 'Unmarked Transparent Polymer',
                      'confidenceScore': 0.58,
                      'isAmbiguous': true,
                      'ambiguityReason': 'No visible RIC code stamp. Could be PET thermoform or Polystyrene.',
                      'alternativeMaterials': ['PET (Type 1)', 'Polystyrene (PS Type 6)', 'PLA Bioplastic'],
                      'recyclabilityGrade': 'C',
                      'degradationTime': '400+ years',
                      'estimatedCarbonKg': '0.10 kg CO2e',
                      'materialComposition': {'Polymer': 100},
                      'handlingInstructions': ['Check bottom stamp'],
                      'circularityGuidance': {'recycle': 'Separate dry'},
                    }),
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(responseJson), 200, headers: {'content-type': 'application/json'});
      });

      final service = GeminiVisionService(client: mockClient);
      final passport = await service.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'clamshell.jpg',
      );

      expect(passport.isAmbiguous, isTrue);
      expect(passport.ambiguityReason, contains('No visible RIC code stamp'));
      expect(passport.alternativeMaterials, hasLength(3));
      expect(passport.alternativeMaterials, contains('PET (Type 1)'));
    });
  });

  group('Priority 1: Textile and Multi-Layer Streams', () {
    test('Textiles & Fabrics assigns correct yellow stream and bin color', () {
      final passport = WastePassportModel(
        id: 'DWP-TEST-TEX',
        itemName: 'Worn Cotton Garment',
        primaryMaterial: 'Textiles & Fabrics',
        subType: '100% Spun Cotton',
        confidenceScore: 0.92,
        recyclabilityGrade: RecyclabilityGrade.B,
        degradationTime: '6 months',
        estimatedCarbonKg: '2.10 kg CO2e',
        materialComposition: {'Cotton': 100},
        handlingInstructions: ['Keep dry'],
        circularityGuidance: {'recycle': 'Textile bank'},
        createdAt: DateTime.now(),
      );

      expect(passport.recommendedBinStream, contains('Yellow Segregated Textile / Donation Stream'));
      expect(passport.binColor, const Color(0xFFF57F17));
    });

    test('Multi-Layer / Composite Materials assigns orange stream and bin color', () {
      final passport = WastePassportModel(
        id: 'DWP-TEST-COMP',
        itemName: 'Multi-Layer Juice Carton',
        primaryMaterial: 'Multi-Layer / Composite Materials',
        subType: 'Tetra Pak PolyAl',
        confidenceScore: 0.90,
        recyclabilityGrade: RecyclabilityGrade.C,
        degradationTime: '30 years',
        estimatedCarbonKg: '0.12 kg CO2e',
        materialComposition: {'Paper': 75, 'LDPE': 20, 'Alu': 5},
        handlingInstructions: ['Flatten completely'],
        circularityGuidance: {'recycle': 'Special carton hydropulping'},
        createdAt: DateTime.now(),
      );

      expect(passport.recommendedBinStream, contains('Orange Multi-Layer / Special Recovery Stream'));
      expect(passport.binColor, const Color(0xFFE65100));
    });
  });

  group('Priority 2: Recycler Facility Rejection Precedence & Verification Defaults', () {
    test('RecyclingFacilityModel defaults isVerified to false in constructor and fromJson', () {
      const facility = RecyclingFacilityModel(
        id: 'FAC-TEST-01',
        name: 'Test Scrap Depot',
        facilityType: FacilityType.scrapDealer,
      );
      expect(facility.isVerified, isFalse);

      final fromJson = RecyclingFacilityModel.fromJson({
        'id': 'FAC-TEST-02',
        'name': 'Test Depot',
        'facilityType': 'recyclingCentre',
      });
      expect(fromJson.isVerified, isFalse);
    });

    test('Rejected materials strictly override accepted materials with symmetric token checks', () {
      const facility = RecyclingFacilityModel(
        id: 'FAC-PLASTIC',
        name: 'Polymer Aggregator',
        facilityType: FacilityType.recyclingCentre,
        acceptedMaterials: ['Plastic', 'PET (Type 1)', 'HDPE (Type 2)', 'PP (Type 5)'],
        rejectedMaterials: ['PVC (Type 3)', 'Thermocol', 'Hazardous Waste'],
      );

      // Accepts standard PET plastic
      expect(facility.acceptsMaterial('Plastic', 'PET (Type 1)'), isTrue);

      // Strictly rejects PVC (Type 3) even though primary material is Plastic
      expect(facility.acceptsMaterial('Plastic', 'PVC (Type 3)'), isFalse);

      // Symmetric check: subType 'PVC' is rejected by rule 'PVC (Type 3)'
      expect(facility.acceptsMaterial('Plastic', 'PVC'), isFalse);

      // Primary material rejected directly
      expect(facility.acceptsMaterial('Hazardous Waste'), isFalse);
    });
  });

  group('Priority 1 & 2: User Material Confirmation & Facility Re-matching', () {
    test('PassportProvider updatePassportMaterial clears ambiguity and updates activePassport', () async {
      final passportProvider = PassportProvider();

      final ambiguousPassport = WastePassportModel(
        id: 'DWP-AMB-01',
        itemName: 'Translucent Container',
        primaryMaterial: 'Plastic',
        subType: 'Unverified Polymer',
        confidenceScore: 0.55,
        isAmbiguous: true,
        ambiguityReason: 'Resin stamp unverified',
        alternativeMaterials: ['PET (Type 1)', 'HDPE (Type 2)', 'PP (Type 5)'],
        recyclabilityGrade: RecyclabilityGrade.C,
        degradationTime: '400 years',
        estimatedCarbonKg: '0.10 kg CO2e',
        materialComposition: {'Polymer': 100},
        handlingInstructions: ['Check markings'],
        circularityGuidance: {'recycle': 'Dry waste'},
        createdAt: DateTime.now(),
      );

      await passportProvider.addPassport(ambiguousPassport);
      expect(passportProvider.activePassport?.isAmbiguous, isTrue);

      // User confirms HDPE Type 2
      await passportProvider.updatePassportMaterial(
        passportId: 'DWP-AMB-01',
        newSubType: 'HDPE (Type 2)',
      );

      expect(passportProvider.activePassport?.subType, 'HDPE (Type 2)');
      expect(passportProvider.activePassport?.isAmbiguous, isFalse);
      expect(passportProvider.activePassport?.confidenceScore, 0.95);
    });

    testWidgets('PassportDetailScreen shows Low AI Certainty card and material confirmation chips', (tester) async {
      final passportProvider = PassportProvider();
      final facilityProvider = FacilityProvider();

      final ambiguousPassport = WastePassportModel(
        id: 'DWP-AMB-02',
        itemName: 'Translucent Bottle',
        primaryMaterial: 'Plastic',
        subType: 'Unknown Polymer',
        confidenceScore: 0.50,
        isAmbiguous: true,
        ambiguityReason: 'Could be PET #1 or HDPE #2 without visible resin code.',
        alternativeMaterials: ['PET (Type 1)', 'HDPE (Type 2)'],
        recyclabilityGrade: RecyclabilityGrade.B,
        degradationTime: '450 years',
        estimatedCarbonKg: '0.08 kg CO2e',
        materialComposition: {'Polymer': 100},
        handlingInstructions: ['Rinse before recycling'],
        circularityGuidance: {'recycle': 'Blue Dry Bin'},
        createdAt: DateTime.now(),
      );

      await passportProvider.addPassport(ambiguousPassport);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: passportProvider),
            ChangeNotifierProvider.value(value: facilityProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PassportDetailScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Low AI Certainty warning card is visible
      expect(find.text('Low AI Certainty – Please Verify Material'), findsOneWidget);
      expect(find.text('Could be PET #1 or HDPE #2 without visible resin code.'), findsOneWidget);
      expect(find.text('PET (Type 1)'), findsOneWidget);
      expect(find.text('HDPE (Type 2)'), findsOneWidget);

      // Tap confirmation chip for PET (Type 1)
      await tester.tap(find.text('PET (Type 1)'));
      await tester.pumpAndSettle();

      // Passport is now confirmed
      expect(passportProvider.activePassport?.subType, 'PET (Type 1)');
      expect(passportProvider.activePassport?.isAmbiguous, isFalse);
    });
  });
}
