import 'package:flutter/foundation.dart';
import 'gemini_vision_service.dart';
import 'mock_ai_classification_service.dart';
import '../../domain/services/ai_classification_service.dart';
import '../../../passport/domain/models/waste_passport_model.dart';
import '../../../../core/config/ai_config.dart';

/// Exception thrown when live AI is attempted without an API key
class MissingApiKeyException implements Exception {
  final String message;
  const MissingApiKeyException([
    this.message = 'No Gemini API key configured. Live AI classification requires an API key from Google AI Studio.',
  ]);

  @override
  String toString() => message;
}

/// Result of classification including which engine was used and whether fallback occurred
class ClassificationExecutionResult {
  final WastePassportModel passport;
  final String providerUsed;
  final bool isFallback;
  final String? fallbackReason;

  const ClassificationExecutionResult({
    required this.passport,
    required this.providerUsed,
    this.isFallback = false,
    this.fallbackReason,
  });
}

/// Hybrid dispatcher providing transparent switching between live Gemini Vision and offline mock simulation
class HybridAIClassificationService {
  final GeminiVisionService _geminiService;
  final MockAIClassificationService _mockService;

  HybridAIClassificationService({
    GeminiVisionService? geminiService,
    MockAIClassificationService? mockService,
  })  : _geminiService = geminiService ?? GeminiVisionService(),
        _mockService = mockService ?? MockAIClassificationService();

  Future<ClassificationExecutionResult> classify({
    required Uint8List imageBytes,
    required String fileName,
    bool allowOfflineSimulation = true,
  }) async {
    // 1. If user has explicitly forced offline mock mode in settings, use mock service
    if (AIConfig.isForceMockMode) {
      final passport = await _mockService.classifyWasteImage(
        imageBytes: imageBytes,
        fileName: fileName,
      );
      return ClassificationExecutionResult(
        passport: passport,
        providerUsed: _mockService.providerName,
        isFallback: false,
      );
    }

    // 2. If no Gemini API key is configured:
    // If allowOfflineSimulation is true (e.g. explicitly requested for demo), use mock service.
    // If allowOfflineSimulation is false (the default for user classification pipeline), throw MissingApiKeyException.
    // NEVER silently fall back to mock classification when live AI is expected.
    if (!AIConfig.hasApiKey) {
      if (allowOfflineSimulation) {
        final passport = await _mockService.classifyWasteImage(
          imageBytes: imageBytes,
          fileName: fileName,
        );
        return ClassificationExecutionResult(
          passport: passport,
          providerUsed: _mockService.providerName,
          isFallback: true,
          fallbackReason: 'No Gemini API key detected. Running in high-fidelity offline simulation mode.',
        );
      }
      throw const MissingApiKeyException(
        'Gemini API key is required for live AI vision classification. Please tap Settings or Set Key to enter your free key from Google AI Studio, or tap Run Offline Simulation.',
      );
    }

    // 3. Attempt Live Gemini Multimodal Classification
    // Note: When live AI is active, failures must NEVER be silently converted into mock results.
    // The exact failure is surfaced so the user can see the error, retry, update the key, or explicitly choose offline simulation.
    try {
      final passport = await _geminiService.classifyWasteImage(
        imageBytes: imageBytes,
        fileName: fileName,
      );
      return ClassificationExecutionResult(
        passport: passport,
        providerUsed: _geminiService.providerName,
        isFallback: false,
      );
    } catch (e) {
      if (e is UnrecognizedWasteException) {
        rethrow;
      }
      throw Exception(
        'Live Gemini AI Vision failed: ${e.toString().replaceAll("Exception: ", "")}',
      );
    }
  }
}
