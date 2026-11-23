import 'package:flutter/foundation.dart';
import '../../../passport/domain/models/waste_passport_model.dart';

/// Common abstraction for WasteWay AI Classification engines
abstract class IAIClassificationService {
  /// Classifies a preprocessed waste image and generates a structured WastePassportModel
  Future<WastePassportModel> classifyWasteImage({
    required Uint8List imageBytes,
    required String fileName,
  });

  /// Name of the active provider (e.g. "Google Gemini Vision", "Offline Simulation Engine")
  String get providerName;

  /// Whether this service requires an active internet connection and API key
  bool get isOnlineService;
}

/// Thrown when an image does not depict recognizable recyclable or municipal waste,
/// or when classification confidence is below the minimum threshold.
class UnrecognizedWasteException implements Exception {
  final String message;
  final String? reason;

  const UnrecognizedWasteException(this.message, {this.reason});

  @override
  String toString() => message;
}
