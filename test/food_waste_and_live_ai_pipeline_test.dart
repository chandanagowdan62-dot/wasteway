import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wasteway/core/config/ai_config.dart';
import 'package:wasteway/features/scanner/data/services/gemini_vision_service.dart';
import 'package:wasteway/features/scanner/data/services/mock_ai_classification_service.dart';
import 'package:wasteway/features/scanner/data/services/hybrid_ai_classification_service.dart';
import 'package:wasteway/features/scanner/presentation/providers/scanner_provider.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Uint8List createTestJpegBytes() {
    final image = img.Image(width: 64, height: 64);
    img.fill(image, color: img.ColorRgb8(120, 180, 50)); // Green/organic tone
    return Uint8List.fromList(img.encodeJpg(image, quality: 80));
  }

  Uint8List createTestPngBytes() {
    final image = img.Image(width: 32, height: 32);
    img.fill(image, color: img.ColorRgb8(200, 100, 50));
    return Uint8List.fromList(img.encodePng(image));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AIConfig.init();
    await AIConfig.clearRuntimeApiKey();
    await AIConfig.setForceMockMode(false);
  });

  group('1. Live Request Payload & Image Attachment Verification', () {
    test('Selected image bytes are base64-encoded and attached in inlineData', () async {
      final testBytes = createTestJpegBytes();
      final expectedBase64 = base64Encode(testBytes);
      String? capturedRequestBody;

      final mockClient = MockClient((request) async {
        capturedRequestBody = request.body;
        final jsonResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'isIdentifiedWaste': true,
                      'itemName': 'Fresh Banana Peel & Produce Scrap',
                      'primaryMaterial': 'Biodegradable / Organic',
                      'subType': 'Raw Plant Biomass',
                      'confidenceScore': 0.95,
                      'recyclabilityGrade': 'A',
                      'degradationTime': '2 - 4 weeks',
                      'estimatedCarbonKg': '0.02 kg CO2e',
                      'materialComposition': {'Raw Banana Peel': 100},
                      'handlingInstructions': [
                        'Deposit directly in green wet-waste bin',
                        'Do not enclose in plastic bags'
                      ],
                      'circularityGuidance': {
                        'compost': '100% aerobic compost feedstock',
                        'recycle': 'Not for dry blue bin'
                      },
                      'visualEvidence': 'Yellow curved fruit peel with fibrous cellular tissue',
                      'isAmbiguous': false,
                    })
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(jsonResponse), 200);
      });

      await AIConfig.setRuntimeApiKey('AIzaSyTestApiKeyForPayloadCheck');
      final service = GeminiVisionService(client: mockClient);
      final passport = await service.classifyWasteImage(
        imageBytes: testBytes,
        fileName: 'image_picker_food_sample.jpg',
      );

      expect(capturedRequestBody, isNotNull);
      final decodedBody = jsonDecode(capturedRequestBody!) as Map<String, dynamic>;
      final contents = decodedBody['contents'] as List;
      final parts = contents[0]['parts'] as List;
      final inlineData = parts[1]['inlineData'] as Map<String, dynamic>;

      // Verify exact image attachment and MIME type
      expect(inlineData['mimeType'], equals('image/jpeg'));
      expect(inlineData['data'], equals(expectedBase64));

      // Verify returned passport is genuine live AI result, NOT mock
      expect(passport.isSimulated, isFalse);
      expect(passport.itemName, equals('Fresh Banana Peel & Produce Scrap'));
      expect(passport.primaryMaterial, equals('Biodegradable / Organic'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.A));
      expect(passport.visualEvidence, contains('Yellow curved fruit peel'));
    });

    test('PNG images have mimeType correctly detected as image/png', () async {
      final pngBytes = createTestPngBytes();
      String? capturedMimeType;

      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final parts = (body['contents'] as List)[0]['parts'] as List;
        capturedMimeType = parts[1]['inlineData']['mimeType'] as String;

        return http.Response(jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'isIdentifiedWaste': true,
                      'itemName': 'Vegetable Peel Trimmings',
                      'primaryMaterial': 'Biodegradable / Organic',
                      'subType': 'Raw Plant Biomass',
                      'confidenceScore': 0.90,
                      'recyclabilityGrade': 'A',
                      'materialComposition': {'Plant Fiber': 100},
                      'handlingInstructions': ['Green wet-waste bin'],
                      'circularityGuidance': {'compost': 'Compostable'},
                    })
                  }
                ]
              }
            }
          ]
        }), 200);
      });

      await AIConfig.setRuntimeApiKey('AIzaSyTestApiKeyForPngCheck');
      final service = GeminiVisionService(client: mockClient);
      await service.classifyWasteImage(
        imageBytes: pngBytes,
        fileName: 'upload.png',
      );

      expect(capturedMimeType, equals('image/png'));
    });
  });

  group('2. Food Waste Classification & Organic Taxonomy Tests', () {
    test('Cooked food leftovers parsed accurately into Biodegradable / Organic with Grade B', () async {
      final testBytes = createTestJpegBytes();
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'isIdentifiedWaste': true,
                      'itemName': 'Cooked Household Food Leftovers',
                      'primaryMaterial': 'Biodegradable / Organic',
                      'subType': 'Cooked Organic Food Waste',
                      'confidenceScore': 0.88,
                      'recyclabilityGrade': 'B',
                      'degradationTime': '1 - 2 weeks',
                      'estimatedCarbonKg': '0.05 kg CO2e',
                      'materialComposition': {'Cooked Rice & Lentils': 100},
                      'handlingInstructions': [
                        'Drain excess liquids before disposal',
                        'Deposit in municipal green wet-waste collector for biomethanation'
                      ],
                      'circularityGuidance': {
                        'compost': 'Suitable for municipal biomethanation or bokashi composting',
                        'safe_disposal': 'Keep separate from dry recyclables'
                      },
                      'visualEvidence': 'Cooked grains and curry sheen on ceramic plate',
                      'isAmbiguous': false,
                    })
                  }
                ]
              }
            }
          ]
        }), 200);
      });

      await AIConfig.setRuntimeApiKey('AIzaSyTestKey');
      final service = GeminiVisionService(client: mockClient);
      final passport = await service.classifyWasteImage(
        imageBytes: testBytes,
        fileName: 'cooked_leftovers.jpg',
      );

      expect(passport.itemName, equals('Cooked Household Food Leftovers'));
      expect(passport.primaryMaterial, equals('Biodegradable / Organic'));
      expect(passport.subType, equals('Cooked Organic Food Waste'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.B));
      expect(passport.isSimulated, isFalse);
    });

    test('Ambiguous food waste is marked with isAmbiguous and clear reason', () async {
      final testBytes = createTestJpegBytes();
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'isIdentifiedWaste': true,
                      'itemName': 'Mixed Kitchen Food Scraps',
                      'primaryMaterial': 'Biodegradable / Organic',
                      'subType': 'Uncertain Organic Biomass',
                      'confidenceScore': 0.62,
                      'recyclabilityGrade': 'A',
                      'isAmbiguous': true,
                      'ambiguityReason':
                          'Visual inspection confirms organic food waste, but exact ingredients cannot be distinguished from photograph.',
                      'alternativeMaterials': ['Raw Kitchen Produce Scraps', 'Cooked Household Leftovers'],
                      'materialComposition': {'Mixed Organic Scraps': 100},
                      'handlingInstructions': ['Green wet-waste bin'],
                      'circularityGuidance': {'compost': 'Compostable in wet waste stream'},
                      'visualEvidence': 'Moist organic composite scraps',
                    })
                  }
                ]
              }
            }
          ]
        }), 200);
      });

      await AIConfig.setRuntimeApiKey('AIzaSyTestKey');
      final service = GeminiVisionService(client: mockClient);
      final passport = await service.classifyWasteImage(
        imageBytes: testBytes,
        fileName: 'food_waste.jpg',
      );

      expect(passport.isAmbiguous, isTrue);
      expect(passport.ambiguityReason, contains('Visual inspection confirms organic food waste'));
      expect(passport.alternativeMaterials, contains('Cooked Household Leftovers'));
      expect(passport.primaryMaterial, equals('Biodegradable / Organic'));
    });
  });

  group('3. Silent Fallback Prevention & Error Transparency Tests', () {
    test('Hybrid service throws MissingApiKeyException when key is missing and allowOfflineSimulation is false', () async {
      final hybridService = HybridAIClassificationService();
      final testBytes = createTestJpegBytes();

      expect(
        () => hybridService.classify(
          imageBytes: testBytes,
          fileName: 'image_picker_12345.jpg',
          allowOfflineSimulation: false,
        ),
        throwsA(isA<MissingApiKeyException>().having(
          (e) => e.message,
          'message',
          contains('Gemini API key is required'),
        )),
      );
    });

    test('ScannerProvider.processAndClassify fails with error and NEVER produces mock passport when key missing', () async {
      final provider = ScannerProvider();
      final testBytes = createTestJpegBytes();

      provider.onImageSelected(testBytes, 'food_photo.jpg');
      final result = await provider.processAndClassify();

      expect(result, isNull);
      expect(provider.currentStep, equals(ScanStep.error));
      expect(provider.errorMessage, contains('Gemini API key is required'));
      expect(provider.generatedPassport, isNull);
      expect(provider.lastResult, isNull);
    });

    test('Live HTTP 404 or 403 error is propagated as error, never converted to mock dry packaging', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': {'code': 404, 'message': 'models/gemini-not-found is not found'}}),
          404,
        );
      });

      await AIConfig.setRuntimeApiKey('AIzaSyTestKey');
      final geminiService = GeminiVisionService(client: mockClient, modelName: 'non-existent-model');
      final hybridService = HybridAIClassificationService(geminiService: geminiService);
      final provider = ScannerProvider(aiClassificationService: hybridService);

      final testBytes = createTestJpegBytes();
      provider.onImageSelected(testBytes, 'food_photo.jpg');
      final result = await provider.processAndClassify();

      expect(result, isNull);
      expect(provider.currentStep, equals(ScanStep.error));
      expect(provider.errorMessage, contains('404'));
      expect(provider.generatedPassport, isNull);
    });
  });

  group('4. Google Models API Dynamic Model Validation Tests', () {
    test('validateModelAccess detects gemini-2.5-flash from Google Models API', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'models': [
              {
                'name': 'models/gemini-2.5-flash',
                'supportedGenerationMethods': ['generateContent', 'countTokens']
              },
              {
                'name': 'models/gemini-2.0-flash',
                'supportedGenerationMethods': ['generateContent']
              },
            ]
          }),
          200,
        );
      });

      final service = GeminiVisionService(client: mockClient);
      final validation = await service.validateModelAccess(
        apiKey: 'AIzaSyValidKey',
        targetModel: 'gemini-2.5-flash',
      );

      expect(validation.isValid, isTrue);
      expect(validation.activeModel, equals('gemini-2.5-flash'));
      expect(validation.availableModels, contains('gemini-2.5-flash'));
      expect(validation.errorMessage, isNull);
    });

    test('validateModelAccess automatically selects working Flash model when requested model is absent', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'models': [
              {
                'name': 'models/gemini-2.0-flash',
                'supportedGenerationMethods': ['generateContent']
              },
            ]
          }),
          200,
        );
      });

      final service = GeminiVisionService(client: mockClient);
      final validation = await service.validateModelAccess(
        apiKey: 'AIzaSyValidKey',
        targetModel: 'non-existent-model',
      );

      expect(validation.isValid, isTrue);
      expect(validation.activeModel, equals('gemini-2.0-flash'));
    });

    test('validateModelAccess reports HTTP 400 invalid key with clear message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': {'code': 400, 'message': 'API key not valid'}}),
          400,
        );
      });

      final service = GeminiVisionService(client: mockClient);
      final validation = await service.validateModelAccess(
        apiKey: 'AIzaSyBadKey',
      );

      expect(validation.isValid, isFalse);
      expect(validation.errorMessage, contains('Invalid Gemini API key (HTTP 400)'));
    });
  });

  group('5. Offline Simulation Engine Heuristics Tests', () {
    test('Offline simulation with organic color bytes returns Organic Food Waste template', () async {
      final mockService = MockAIClassificationService();
      final organicBytes = createTestJpegBytes(); // Green vegetal tone

      final passport = await mockService.classifyWasteImage(
        imageBytes: organicBytes,
        fileName: 'image_picker_6789.jpg', // Generic OS camera filename
      );

      expect(passport.isSimulated, isTrue);
      expect(passport.primaryMaterial, equals('Biodegradable / Organic'));
      expect(passport.itemName, contains('Food Waste'));
    });

    test('Offline simulation without keywords or organic tones returns Unconfirmed Item with food alternatives', () async {
      final mockService = MockAIClassificationService();
      // Neutral gray bytes
      final neutralImage = img.Image(width: 32, height: 32);
      img.fill(neutralImage, color: img.ColorRgb8(128, 128, 128));
      final neutralBytes = Uint8List.fromList(img.encodeJpg(neutralImage));

      final passport = await mockService.classifyWasteImage(
        imageBytes: neutralBytes,
        fileName: 'camera_capture_1001.jpg',
      );

      expect(passport.isSimulated, isTrue);
      expect(passport.itemName, equals('Unconfirmed Waste Item (Offline Simulation)'));
      expect(passport.isAmbiguous, isTrue);
      expect(passport.alternativeMaterials, contains('Fresh Fruit Scrap / Food Waste'));
    });
  });
}
