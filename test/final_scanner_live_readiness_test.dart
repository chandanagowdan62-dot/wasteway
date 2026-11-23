import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wasteway/core/config/ai_config.dart';
import 'package:wasteway/features/scanner/domain/services/image_processing_service.dart';
import 'package:wasteway/features/scanner/data/services/gemini_vision_service.dart';
import 'package:wasteway/features/scanner/data/services/mock_ai_classification_service.dart';
import 'package:wasteway/features/scanner/data/services/hybrid_ai_classification_service.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';
import 'package:wasteway/features/facilities/presentation/providers/facility_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AIConfig.init();
    await AIConfig.clearRuntimeApiKey();
  });

  group('1. Image Validation & Preprocessing Pipeline Tests', () {
    final imageService = ImageProcessingService();

    test('Empty image bytes throws descriptive ArgumentError', () async {
      expect(
        () => imageService.preprocessImage(rawBytes: Uint8List(0)),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('cannot be empty'),
        )),
      );
    });

    test('Oversized image (>25MB) throws ArgumentError before memory allocation', () async {
      // 26 MB synthetic byte buffer
      final oversizedBytes = Uint8List(26 * 1024 * 1024);
      expect(
        () => imageService.preprocessImage(rawBytes: oversizedBytes),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('exceeds maximum allowed limit of 25MB'),
        )),
      );
    });

    test('Corrupted or unsupported format throws descriptive exception', () async {
      final garbageBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      expect(
        () => imageService.preprocessImage(rawBytes: garbageBytes),
        throwsA(predicate((e) =>
            e.toString().contains('Failed to decode image') &&
            e.toString().contains('JPEG, PNG, or WebP'))),
      );
    });

    test('Valid uncompressed image bakes orientation, downscales and outputs optimized JPEG', () async {
      // Create a 1600x1200 test image in memory
      final testImg = img.Image(width: 1600, height: 1200);
      img.fill(testImg, color: img.ColorRgb8(100, 200, 100));
      final pngBytes = Uint8List.fromList(img.encodePng(testImg));

      final result = await imageService.preprocessImage(
        rawBytes: pngBytes,
        maxDimension: 1024,
        quality: 80,
      );

      expect(result.width, lessThanOrEqualTo(1024));
      expect(result.height, lessThanOrEqualTo(1024));
      expect(result.processedSizeBytes, greaterThan(0));
      expect(result.originalSizeBytes, equals(pngBytes.lengthInBytes));

      // Verify the output is valid JPEG
      final decoded = img.decodeJpg(result.processedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(1024));
    });
  });

  group('2. Gemini Request Construction & Accuracy Schema Tests', () {
    test('Constructs accurate multimodal payload with configured model and image data', () async {
      const syntheticApiKey = 'AIzaSyFakeTestKey_ReadinessPayload01';
      await AIConfig.setRuntimeApiKey(syntheticApiKey);
      await AIConfig.setModelName('gemini-3.8-flash');

      final sampleImage = img.Image(width: 100, height: 100);
      img.fill(sampleImage, color: img.ColorRgb8(250, 150, 50));
      final testJpgBytes = Uint8List.fromList(img.encodeJpg(sampleImage));

      Uri? sentUri;
      Map<String, dynamic>? sentBody;

      final mockClient = MockClient((request) async {
        sentUri = request.url;
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;

        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'isIdentifiedWaste': true,
                      'itemName': 'Aluminium Beverage Can',
                      'primaryMaterial': 'Metals',
                      'subType': 'Aluminium Alloy 3004',
                      'confidenceScore': 0.98,
                      'visualEvidence': 'Cylindrical beverage can body, concave base with stay-on tab and ALU 41 stamp',
                      'recyclabilityGrade': 'A',
                      'degradationTime': '200 - 500 years',
                      'estimatedCarbonKg': '0.04 kg CO2e',
                      'materialComposition': {'Aluminium Alloy': 100},
                      'handlingInstructions': [
                        'Rinse residual liquids',
                        'Crush flat to conserve bin space',
                        'Deposit in blue dry-waste collection'
                      ],
                      'circularityGuidance': {
                        'reuse': 'Upcycle into desk pencil holder or planters',
                        'recycle': 'Deposit in dry-waste stream for metal smelter reprocessing',
                        'safe_disposal': 'Keep clean and dry'
                      }
                    })
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(responseJson), 200);
      });

      final service = GeminiVisionService(client: mockClient);
      final passport = await service.classifyWasteImage(
        imageBytes: testJpgBytes,
        fileName: 'beverage_can.jpg',
      );

      // Verify endpoint and method
      expect(sentUri.toString(), contains('models/gemini-3.8-flash:generateContent'));
      expect(sentUri!.queryParameters['key'], equals(syntheticApiKey));

      // Verify image part
      final contents = sentBody!['contents'] as List;
      final parts = contents[0]['parts'] as List;
      final inlineData = parts[1]['inlineData'] as Map<String, dynamic>;
      expect(inlineData['mimeType'], equals('image/jpeg'));
      expect(inlineData['data'], equals(base64Encode(testJpgBytes)));

      // Verify prompt rules
      final prompt = parts[0]['text'] as String;
      expect(prompt, contains('Medical & Sanitary Waste'));
      expect(prompt, contains('Furniture & Bulky Goods'));
      expect(prompt, contains('Construction & Demolition Waste'));
      expect(prompt, contains('visualEvidence'));
      expect(prompt, contains('STRICT BATTERY / E-WASTE RESTRICTION'));
      expect(prompt, contains('Likely multilayer or metallised packaging. Exact material composition not confirmed.'));

      // Verify passport parsed result
      expect(passport.itemName, equals('Aluminium Beverage Can'));
      expect(passport.primaryMaterial, equals('Metals'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.A));
      expect(passport.visualEvidence, contains('ALU 41 stamp'));
      expect(passport.isSimulated, isFalse);
    });

    test('classifyWasteImage rejects empty image payload immediately', () async {
      await AIConfig.setRuntimeApiKey('AIzaSyFakeTestKey_EmptyPayload02');
      final service = GeminiVisionService();
      expect(
        () => service.classifyWasteImage(imageBytes: Uint8List(0), fileName: 'empty.jpg'),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('cannot be empty'))),
      );
    });
  });

  group('3. API Key Security & Redaction Tests', () {
    test('API key is strictly redacted from error messages on network or server failures', () async {
      const secretKey = 'AIzaSyFakeTestKey_Redaction03';
      await AIConfig.setRuntimeApiKey(secretKey);

      final mockClient = MockClient((request) async {
        // Return 500 containing the raw url or body with the key
        return http.Response('Internal error on key $secretKey at endpoint', 500);
      });

      final service = GeminiVisionService(client: mockClient);
      try {
        await service.classifyWasteImage(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'test.jpg',
        );
        fail('Should have thrown an exception');
      } catch (e) {
        final errorMsg = e.toString();
        expect(errorMsg, isNot(contains(secretKey)));
        expect(errorMsg, contains('[REDACTED_API_KEY]'));
      }
    });

    test('HTTP 400 rejection produces clear action guidance without leaking key', () async {
      const secretKey = 'AIzaSyFakeTestKey_Http400_04';
      await AIConfig.setRuntimeApiKey(secretKey);

      final mockClient = MockClient((request) async {
        return http.Response('{"error": {"message": "Invalid argument: $secretKey"}}', 400);
      });

      final service = GeminiVisionService(client: mockClient);
      try {
        await service.classifyWasteImage(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'test.jpg',
        );
        fail('Should have thrown');
      } catch (e) {
        expect(e.toString(), contains('Gemini API request rejected (400)'));
        expect(e.toString(), isNot(contains(secretKey)));
      }
    });

    test('HTTP 403 invalid key produces clear authorization error without leaking key', () async {
      const secretKey = 'AIzaSyFakeTestKey_Http403_05';
      await AIConfig.setRuntimeApiKey(secretKey);

      final mockClient = MockClient((request) async {
        return http.Response('Forbidden for $secretKey', 403);
      });

      final service = GeminiVisionService(client: mockClient);
      try {
        await service.classifyWasteImage(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'test.jpg',
        );
        fail('Should have thrown');
      } catch (e) {
        expect(e.toString(), contains('Gemini API key is invalid or unauthorized (403)'));
        expect(e.toString(), isNot(contains(secretKey)));
      }
    });

    test('HTTP 429 rate limit produces user-friendly quota exceeded guidance', () async {
      await AIConfig.setRuntimeApiKey('AIzaSyFakeTestKey_Http429_06');

      final mockClient = MockClient((request) async {
        return http.Response('Quota exceeded', 429);
      });

      final service = GeminiVisionService(client: mockClient);
      expect(
        () => service.classifyWasteImage(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'test.jpg',
        ),
        throwsA(predicate((e) => e.toString().contains('quota rate limit exceeded (429)'))),
      );
    });

    test('HTTP 404 model not found reports exact model name without fallback', () async {
      await AIConfig.setRuntimeApiKey('AIzaSyFakeTestKey_Http404_07');
      await AIConfig.setModelName('gemini-3.8-flash');

      final mockClient = MockClient((request) async {
        return http.Response('Model not found', 404);
      });

      final service = GeminiVisionService(client: mockClient);
      expect(
        () => service.classifyWasteImage(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'test.jpg',
        ),
        throwsA(predicate((e) =>
            e.toString().contains('HTTP 404') && e.toString().contains('gemini-3.8-flash'))),
      );
    });
  });

  group('4. Scientific Accuracy & Cross-Contamination Prevention Tests', () {
    test('Snack wrapper response strictly santizes any accidental battery or lithium guidance', () async {
      await AIConfig.setRuntimeApiKey('AIzaSyFakeTestKey_ChipsSanitize08');

      final mockClient = MockClient((request) async {
        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'isIdentifiedWaste': true,
                      'itemName': 'Potato Chips Metallized Wrapper',
                      'primaryMaterial': 'Multi-Layer / Composite Materials',
                      'subType': 'Metallized BOPP / Foil', // Intentionally unverified string
                      'confidenceScore': 0.91,
                      'visualEvidence': 'Metallized heat-sealed snack packaging with crimped ends',
                      'recyclabilityGrade': 'C',
                      'degradationTime': 'Estimated degradation time unavailable',
                      'estimatedCarbonKg': 'Embodied carbon estimate unavailable',
                      'materialComposition': {'BOPP': 85, 'Aluminium': 15},
                      'handlingInstructions': [
                        'Empty food crumbs and wipe dry',
                        'DANGER: Do not puncture lithium battery cell', // Erroneous hallucinated instruction
                        'Deposit in dry packaging collection'
                      ],
                      'circularityGuidance': {
                        'reuse': 'Eco-brick stuffing',
                        'recycle': 'Co-processing in cement kilns',
                        'safe_disposal': 'Keep dry'
                      }
                    })
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(responseJson), 200);
      });

      final service = GeminiVisionService(client: mockClient);
      final passport = await service.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'chips.jpg',
      );

      // Verify unconfirmed subType was enforced
      expect(passport.subType, equals('Likely multilayer or metallised packaging. Exact material composition not confirmed.'));
      expect(passport.materialComposition['Likely multilayer or metallised packaging. Exact material composition not confirmed'], equals(100));

      // Verify battery instruction was completely purged
      for (final step in passport.handlingInstructions) {
        expect(step.toLowerCase(), isNot(contains('battery')));
        expect(step.toLowerCase(), isNot(contains('lithium')));
      }
      expect(passport.isHazardous, isFalse);
    });

    test('Actual battery item retains essential lithium and terminal hazard precautions', () async {
      await AIConfig.setRuntimeApiKey('AIzaSyFakeTestKey_Battery09');

      final mockClient = MockClient((request) async {
        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'isIdentifiedWaste': true,
                      'itemName': 'Lithium-Ion Cylindrical Battery',
                      'primaryMaterial': 'Electronic Waste (E-Waste)',
                      'subType': 'Lithium-Ion Secondary Cell',
                      'confidenceScore': 0.95,
                      'visualEvidence': 'Cylindrical steel casing with raised positive terminal and 3.7V Li-ion label',
                      'recyclabilityGrade': 'E',
                      'degradationTime': 'Non-biodegradable',
                      'estimatedCarbonKg': '1.20 kg CO2e',
                      'materialComposition': {'Li-ion Cathode/Anode': 60, 'Steel Casing': 40},
                      'handlingInstructions': [
                        'Tape positive and negative terminals with non-conductive tape',
                        'Never puncture or incinerate lithium cell',
                        'Deliver to authorized hazardous e-waste dismantler'
                      ],
                      'circularityGuidance': {
                        'recycle': 'Authorized hydrometallurgical recovery only',
                        'safe_disposal': 'Store in fireproof container'
                      }
                    })
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(responseJson), 200);
      });

      final service = GeminiVisionService(client: mockClient);
      final passport = await service.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: '18650_battery.jpg',
      );

      expect(passport.isHazardous, isTrue);
      expect(passport.primaryMaterial, equals('Electronic Waste (E-Waste)'));
      // Verify battery instructions ARE preserved for genuine batteries
      expect(passport.handlingInstructions.any((s) => s.contains('terminals')), isTrue);
      expect(passport.handlingInstructions.any((s) => s.contains('lithium')), isTrue);
    });

    test('Medical & Sanitary waste produces hazardous classification and biomedical bin stream', () async {
      await AIConfig.setRuntimeApiKey('AIzaSyFakeTestKey_Medical10');

      final mockClient = MockClient((request) async {
        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'isIdentifiedWaste': true,
                      'itemName': 'Used Surgical Face Mask',
                      'primaryMaterial': 'Medical & Sanitary Waste',
                      'subType': 'Polypropylene Meltblown Non-Woven',
                      'confidenceScore': 0.92,
                      'visualEvidence': 'Pleated non-woven fabric with elastic ear loops and metal nose wire',
                      'recyclabilityGrade': 'E',
                      'degradationTime': '450 years',
                      'estimatedCarbonKg': '0.05 kg CO2e',
                      'materialComposition': {'Polypropylene Non-Woven': 95, 'Metal/Elastic': 5},
                      'handlingInstructions': [
                        'Cut ear loops to prevent wildlife entanglement',
                        'Wrap inside paper or leak-proof sanitary bag',
                        'Never place in paper recycling or compost bins'
                      ],
                      'circularityGuidance': {
                        'safe_disposal': 'Dispose in designated biomedical or sanitary waste bag'
                      }
                    })
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(responseJson), 200);
      });

      final service = GeminiVisionService(client: mockClient);
      final passport = await service.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'mask.jpg',
      );

      expect(passport.primaryMaterial, equals('Medical & Sanitary Waste'));
      expect(passport.isHazardous, isTrue);
      expect(passport.recommendedBinStream, contains('Biomedical & Sanitary'));
      expect(passport.simpleEnvironmentalRelevance, contains('biological or pharmaceutical hazards'));
    });
  });

  group('5. Recycler Matching & Facility Acceptance Rules Tests', () {
    final facilityProvider = FacilityProvider();

    test('BSWML accepts Multi-Layer Packaging and dry recyclables', () {
      final bswml = facilityProvider.allFacilities.firstWhere((f) => f.id == 'FAC-BLR-04');
      expect(bswml.acceptsMaterial('Multi-Layer / Composite Materials'), isTrue);
      expect(bswml.acceptsMaterial('Paper & Cardboard'), isTrue);
      expect(bswml.acceptsMaterial('Plastic'), isTrue);
    });

    test('BSWML strictly rejects Unsegregated Mixed Waste and Sanitary Waste', () {
      final bswml = facilityProvider.allFacilities.firstWhere((f) => f.id == 'FAC-BLR-04');
      expect(bswml.acceptsMaterial('Medical & Sanitary Waste'), isFalse);
      expect(bswml.acceptsMaterial('Sanitary Pads / Tissues'), isFalse);
    });

    test('General scrap platforms strictly reject Medical & Sanitary Waste', () {
      final kabadify = facilityProvider.allFacilities.firstWhere((f) => f.id == 'FAC-BLR-01');
      final kabadCart = facilityProvider.allFacilities.firstWhere((f) => f.id == 'FAC-BLR-02');

      expect(kabadify.acceptsMaterial('Medical & Sanitary Waste'), isFalse);
      expect(kabadCart.acceptsMaterial('Medical & Sanitary Waste'), isFalse);
      expect(kabadify.acceptsMaterial('Biomedical Waste'), isFalse);
    });

    test('Goonj accepts Furniture & Bulky Goods and Textiles', () {
      final goonj = facilityProvider.allFacilities.firstWhere((f) => f.id == 'FAC-BLR-08');
      expect(goonj.acceptsMaterial('Textiles & Fabrics'), isTrue);
      expect(goonj.acceptsMaterial('Furniture & Bulky Goods'), isTrue);
    });

    test('Enviro-Hub accepts Batteries and E-Waste but strictly rejects General Garbage and Medical Waste', () {
      final enviroHub = facilityProvider.allFacilities.firstWhere((f) => f.id == 'FAC-BLR-06');
      expect(enviroHub.acceptsMaterial('Electronic Waste (E-Waste)'), isTrue);
      expect(enviroHub.acceptsMaterial('Batteries'), isTrue);
      expect(enviroHub.acceptsMaterial('Medical & Sanitary Waste'), isFalse);
    });
  });

  group('6. Hybrid Dispatcher & Offline Simulation Labeling Tests', () {
    test('Offline simulation mode produces explicit demo labels and preserves visual evidence', () async {
      final mockService = MockAIClassificationService();
      final passport = await mockService.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'lays_chips_packet.jpg',
      );

      expect(passport.isSimulated, isTrue);
      expect(passport.simulationNotice, contains('Demonstration Record (Offline Simulation)'));
      expect(passport.simulationNotice, contains('Not classified by live AI'));
      expect(passport.visualEvidence, isNotNull);
      expect(passport.visualEvidence, contains('snack pouch'));
    });

    test('Hybrid dispatcher never silently falls back to offline simulation when API key is set', () async {
      await AIConfig.setRuntimeApiKey('AIzaSyFakeTestKey_Dispatcher11');

      final failingClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final dispatcher = HybridAIClassificationService(
        geminiService: GeminiVisionService(client: failingClient),
      );

      expect(
        () => dispatcher.classify(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'test.jpg',
          allowOfflineSimulation: true,
        ),
        throwsA(predicate((e) =>
            e.toString().contains('Live Gemini AI Vision failed') &&
            !e.toString().contains('simulation'))),
      );
    });
  });
}
