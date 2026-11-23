import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteway/core/config/ai_config.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';
import 'package:wasteway/features/scanner/data/services/gemini_vision_service.dart';
import 'package:wasteway/features/scanner/data/services/mock_ai_classification_service.dart';
import 'package:wasteway/features/scanner/domain/services/image_processing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List chipsPacketImageBytes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AIConfig.init();
    await AIConfig.clearRuntimeApiKey();
    await AIConfig.setModelName(AIConfig.defaultModel);
    await AIConfig.setForceMockMode(false);

    // Generate a test photo representing an ordinary potato chips wrapper
    final photo = img.Image(width: 640, height: 480);
    img.fill(photo, color: img.ColorRgb8(220, 60, 20)); // Red-orange packet
    for (int y = 140; y < 190; y++) {
      for (int x = 40; x < 600; x++) {
        photo.setPixel(x, y, img.ColorRgb8(230, 230, 235)); // Metallic sheen
      }
    }
    for (int y = 200; y < 320; y++) {
      for (int x = 60; x < 580; x++) {
        photo.setPixel(x, y, img.ColorRgb8(255, 200, 30));
      }
    }
    chipsPacketImageBytes = Uint8List.fromList(img.encodeJpg(photo, quality: 90));
  });

  group('Chips Packet AI Vision & Circularity Passport Tests', () {
    test('Image Preprocessing Service correctly normalizes and orients chips packet photo', () async {
      final preprocessor = ImageProcessingService();
      final result = await preprocessor.preprocessImage(
        rawBytes: chipsPacketImageBytes,
        maxDimension: 800,
        quality: 85,
      );

      expect(result.processedBytes, isNotEmpty);
      expect(result.width, equals(640));
      expect(result.height, equals(480));
      expect(result.processedSizeBytes, greaterThan(0));
    });

    test('Live GeminiVisionService generates accurate payload and prompt for chips packet photo', () async {
      await AIConfig.setRuntimeApiKey('AIzaSySyntheticChipsKey987654321');

      late Uri sentUrl;
      late Map<String, dynamic> sentBody;

      final mockResponse = {
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
                    'confidenceScore': 0.95,
                    'isAmbiguous': false,
                    'recyclabilityGrade': 'C',
                    'degradationTime': 'Estimated degradation time unavailable from photograph',
                    'estimatedCarbonKg': 'Embodied carbon estimate unavailable',
                    'materialComposition': {
                      'Likely multilayer or metallised packaging. Exact material composition not confirmed': 100,
                    },
                    'handlingInstructions': [
                      'Empty all food particles and wipe clean of oils',
                      'Fold and store dry; do not mix with wet organic waste',
                      'Route to Dry Waste Collection Centre (DWCC) or cement kiln coprocessing',
                      'Do NOT burn in open fires; burning releases toxic halogenated pollutants'
                    ],
                    'circularityGuidance': {
                      'reuse': 'Can be repurposed into eco-bricks for community landscaping',
                      'repair': 'Not applicable for single-use flexible food packaging',
                      'recycle': 'Non-recyclable in standard mechanical recycling; suitable for cement kiln co-processing',
                      'donate': 'Collect clean dry wrappers for school or municipal eco-brick drives',
                      'return': 'Deposit in manufacturer Extended Producer Responsibility (EPR) collection kiosks',
                      'compost': 'Strictly non-compostable; plastic and metal barrier does not biodegrade',
                      'safe_disposal': 'Store clean and dry in the dry-waste stream'
                    }
                  })
                }
              ]
            }
          }
        ]
      };

      final mockClient = MockClient((request) async {
        sentUrl = request.url;
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(mockResponse), 200, headers: {'content-type': 'application/json'});
      });

      final service = GeminiVisionService(client: mockClient);
      final passport = await service.classifyWasteImage(
        imageBytes: chipsPacketImageBytes,
        fileName: 'snack_chips_packet.jpg',
      );

      // Verify endpoint and configured active model (gemini-3.8-flash)
      expect(sentUrl.toString(), contains('models/gemini-3.8-flash:generateContent'));
      expect(sentUrl.queryParameters['key'], equals('AIzaSySyntheticChipsKey987654321'));

      // Verify inline base64 image data
      final parts = sentBody['contents'][0]['parts'] as List;
      final inlineData = parts[1]['inlineData'] as Map<String, dynamic>;
      expect(inlineData['mimeType'], equals('image/jpeg'));
      expect(inlineData['data'], equals(base64Encode(chipsPacketImageBytes)));

      // Verify structured JSON schema generationConfig
      final genConfig = sentBody['generationConfig'] as Map<String, dynamic>;
      expect(genConfig['responseMimeType'], equals('application/json'));
      expect(genConfig['temperature'], equals(0.2));

      // Verify Prompt rules for chips packets
      final prompt = parts[0]['text'] as String;
      expect(prompt, contains('CHIPS PACKETS & SNACK WRAPPERS'));
      expect(prompt, contains('Multi-Layer / Composite Materials'));
      expect(prompt, contains('Recyclability is Grade C'));
      expect(prompt, contains('NEVER classify an object as a battery'));

      // Verify returned Passport data
      expect(passport.itemName, equals('Multi-Layer Chips & Snack Wrapper'));
      expect(passport.primaryMaterial, equals('Multi-Layer / Composite Materials'));
      expect(passport.subType, equals('Likely multilayer or metallised packaging. Exact material composition not confirmed.'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.C));
      expect(passport.confidenceScore, equals(0.95));
      expect(passport.isSimulated, isFalse);
      expect(passport.isHazardous, isFalse);
      expect(passport.materialComposition['Likely multilayer or metallised packaging. Exact material composition not confirmed'], equals(100));
      expect(passport.circularityGuidance['reuse'], contains('eco-brick'));
      expect(passport.circularityGuidance['compost'], contains('non-compostable'));
    });

    test('Live API conditional test (runs when actual GEMINI_API_KEY environment variable is provided)', () async {
      final envKey = Platform.environment['GEMINI_API_KEY'];
      if (envKey == null || envKey.trim().isEmpty) {
        expect(AIConfig.hasApiKey, isFalse);
        return;
      }

      await AIConfig.setRuntimeApiKey(envKey);
      final liveService = GeminiVisionService();
      final passport = await liveService.classifyWasteImage(
        imageBytes: chipsPacketImageBytes,
        fileName: 'lays_chips_packet.jpg',
      );

      expect(passport.isSimulated, isFalse);
      expect(passport.itemName, isNotEmpty);
      expect(passport.primaryMaterial, isNotEmpty);
      expect(passport.confidenceScore, greaterThan(0.50));
      expect(passport.recyclabilityGrade, isNotNull);
    });

    test('Offline simulation mode accurately handles chips packet with explicit simulation labels', () async {
      final mockService = MockAIClassificationService();
      final passport = await mockService.classifyWasteImage(
        imageBytes: chipsPacketImageBytes,
        fileName: 'lays_chips_packet.jpg',
      );

      expect(passport.isSimulated, isTrue);
      expect(passport.simulationNotice, contains('Offline Simulation'));
      expect(passport.itemName, equals('Multi-Layer Chips & Snack Wrapper'));
      expect(passport.primaryMaterial, equals('Multi-Layer / Composite Materials'));
      expect(passport.subType, equals('Likely multilayer or metallised packaging. Exact material composition not confirmed.'));
      expect(passport.recyclabilityGrade, equals(RecyclabilityGrade.C));
      expect(passport.isHazardous, isFalse);
      expect(passport.materialComposition['Likely multilayer or metallised packaging. Exact material composition not confirmed'], equals(100));
    });
  });

  group('Google Models API Verification & Error Handling Tests', () {
    test('validateModelAccess returns valid when gemini-3.8-flash exists with generateContent', () async {
      final mockModelsResponse = {
        'models': [
          {
            'name': 'models/gemini-3.8-flash',
            'supportedGenerationMethods': ['generateContent', 'countTokens'],
          },
          {
            'name': 'models/gemini-3.5-flash-lite',
            'supportedGenerationMethods': ['generateContent'],
          }
        ]
      };

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('https://generativelanguage.googleapis.com/v1beta/models'));
        return http.Response(jsonEncode(mockModelsResponse), 200);
      });

      final service = GeminiVisionService();
      final result = await service.validateModelAccess(
        apiKey: 'AIzaSyTestKey123',
        targetModel: 'gemini-3.8-flash',
        testClient: mockClient,
      );

      expect(result.isValid, isTrue);
      expect(result.activeModel, equals('gemini-3.8-flash'));
      expect(result.supportedMethods, contains('generateContent'));
      expect(result.availableModels, contains('gemini-3.8-flash'));
    });

    test('validateModelAccess falls back to available supported model if requested model not listed', () async {
      final mockModelsResponse = {
        'models': [
          {
            'name': 'models/gemini-3.5-flash-lite',
            'supportedGenerationMethods': ['generateContent'],
          }
        ]
      };

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(mockModelsResponse), 200);
      });

      final service = GeminiVisionService();
      final result = await service.validateModelAccess(
        apiKey: 'AIzaSyTestKey123',
        targetModel: 'gemini-3.8-flash',
        testClient: mockClient,
      );

      expect(result.isValid, isTrue);
      expect(result.activeModel, equals('gemini-3.5-flash-lite'));
    });

    test('validateModelAccess reports HTTP 400 invalid API key', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": {"code": 400, "message": "API key not valid"}}', 400);
      });

      final service = GeminiVisionService();
      final result = await service.validateModelAccess(
        apiKey: 'AIzaSyInvalidKey',
        testClient: mockClient,
      );

      expect(result.isValid, isFalse);
      expect(result.httpStatusCode, equals(400));
      expect(result.errorMessage, contains('Invalid Gemini API key (HTTP 400)'));
    });

    test('validateModelAccess reports HTTP 403 permission denied', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": {"code": 403, "message": "Permission denied"}}', 403);
      });

      final service = GeminiVisionService();
      final result = await service.validateModelAccess(
        apiKey: 'AIzaSyBlockedKey',
        testClient: mockClient,
      );

      expect(result.isValid, isFalse);
      expect(result.httpStatusCode, equals(403));
      expect(result.errorMessage, contains('Permission denied (HTTP 403)'));
    });

    test('validateModelAccess reports HTTP 429 quota exceeded', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": {"code": 429, "message": "Resource exhausted"}}', 429);
      });

      final service = GeminiVisionService();
      final result = await service.validateModelAccess(
        apiKey: 'AIzaSyRateLimitedKey',
        testClient: mockClient,
      );

      expect(result.isValid, isFalse);
      expect(result.httpStatusCode, equals(429));
      expect(result.errorMessage, contains('quota exceeded (HTTP 429)'));
    });
  });
}
