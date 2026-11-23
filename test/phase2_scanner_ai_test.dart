import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteway/core/config/ai_config.dart';
import 'package:wasteway/features/scanner/domain/services/image_processing_service.dart';
import 'package:wasteway/features/scanner/data/services/mock_ai_classification_service.dart';
import 'package:wasteway/features/scanner/data/services/hybrid_ai_classification_service.dart';
import 'package:wasteway/features/scanner/presentation/providers/scanner_provider.dart';
import 'package:wasteway/features/passport/domain/models/waste_passport_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });
  group('Phase 2: Image Preprocessing Service Unit Tests', () {
    late ImageProcessingService processingService;

    setUp(() {
      processingService = ImageProcessingService();
    });

    test('Preprocesses, resizes and compresses an image payload', () async {
      // Create a test synthetic image of 1200x800 px (larger than max 1024)
      final testImg = img.Image(width: 1200, height: 800);
      img.fill(testImg, color: img.ColorRgb8(30, 126, 52));
      final testBytes = img.encodeJpg(testImg, quality: 95);

      final result = await processingService.preprocessImage(
        rawBytes: testBytes,
        maxDimension: 1024,
        quality: 80,
      );

      expect(result.processedBytes.isNotEmpty, true);
      expect(result.width, lessThanOrEqualTo(1024));
      expect(result.height, lessThanOrEqualTo(1024));
      expect(result.processedSizeBytes, greaterThan(0));
      expect(result.originalSizeFormatted.contains('KB'), true);
      expect(result.processedSizeFormatted.contains('KB'), true);
    });

    test('Throws ArgumentError if raw bytes are empty', () async {
      expect(
        () => processingService.preprocessImage(rawBytes: Uint8List(0)),
        throwsArgumentError,
      );
    });
  });

  group('Phase 2: AI Classification & Circularity Engine Tests', () {
    late MockAIClassificationService mockService;
    late HybridAIClassificationService hybridService;

    setUp(() {
      mockService = MockAIClassificationService();
      hybridService = HybridAIClassificationService(mockService: mockService);
    });

    test('Mock service returns structured WastePassportModel for plastic bottle', () async {
      final passport = await mockService.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'water_bottle.jpg',
      );

      expect(passport.itemName, contains('Bottle'));
      expect(passport.primaryMaterial, 'Plastic');
      expect(passport.recyclabilityGrade, RecyclabilityGrade.A);
      expect(passport.degradationTime.isNotEmpty, true);
      expect(passport.materialComposition.isNotEmpty, true);
      expect(passport.handlingInstructions.isNotEmpty, true);

      // Verify all 7-Rs are present in circularity guidance
      final guidance = passport.circularityGuidance;
      expect(guidance.containsKey('reuse'), true);
      expect(guidance.containsKey('repair'), true);
      expect(guidance.containsKey('recycle'), true);
      expect(guidance.containsKey('donate'), true);
      expect(guidance.containsKey('return'), true);
      expect(guidance.containsKey('compost'), true);
      expect(guidance.containsKey('safe_disposal'), true);
    });

    test('Mock service accurately classifies hazardous E-Waste batteries', () async {
      final passport = await mockService.classifyWasteImage(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'lithium_battery.png',
      );

      expect(passport.primaryMaterial, contains('E-Waste'));
      expect(passport.recyclabilityGrade, RecyclabilityGrade.E);
      expect(passport.circularityGuidance['safe_disposal']!.isNotEmpty, true);
    });

    test('Hybrid dispatcher seamlessly routes to mock simulation when offline or no API key', () async {
      final result = await hybridService.classify(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'soda_can.jpg',
      );

      expect(result.providerUsed, contains('Simulation'));
      expect(result.passport.primaryMaterial, 'Metals');
      expect(result.passport.recyclabilityGrade, RecyclabilityGrade.A);
    });
  });

  group('Phase 2: ScannerProvider Pipeline State Tests', () {
    setUp(() async {
      await AIConfig.setForceMockMode(true);
    });

    tearDown(() async {
      await AIConfig.setForceMockMode(false);
    });

    test('ScannerProvider full lifecycle: select -> process -> classify -> complete', () async {
      final provider = ScannerProvider();

      expect(provider.currentStep, ScanStep.idle);
      expect(provider.rawImageBytes, isNull);

      // Create synthetic image bytes
      final testImg = img.Image(width: 200, height: 200);
      final testBytes = img.encodeJpg(testImg);

      provider.onImageSelected(testBytes, 'sample_box.jpg');
      expect(provider.rawImageBytes, isNotNull);
      expect(provider.imageFileName, 'sample_box.jpg');

      final passport = await provider.processAndClassify();

      expect(passport, isNotNull);
      expect(provider.currentStep, ScanStep.completed);
      expect(provider.preprocessingResult, isNotNull);
      expect(provider.generatedPassport, isNotNull);
    });
  });
}
