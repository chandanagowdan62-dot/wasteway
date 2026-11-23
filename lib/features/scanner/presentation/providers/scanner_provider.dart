import 'package:flutter/foundation.dart';
import '../../domain/services/image_processing_service.dart';
import '../../data/services/hybrid_ai_classification_service.dart';
import '../../data/services/mock_ai_classification_service.dart';
import '../../../passport/domain/models/waste_passport_model.dart';
import '../../../../core/config/ai_config.dart';

enum ScanStep {
  idle,
  capturing,
  preprocessing,
  classifying,
  completed,
  error,
}

class ScannerProvider extends ChangeNotifier {
  final ImageProcessingService _imageProcessingService;
  final HybridAIClassificationService _aiClassificationService;

  ScanStep _currentStep = ScanStep.idle;
  Uint8List? _rawImageBytes;
  Uint8List? _processedImageBytes;
  PreprocessingResult? _preprocessingResult;
  String? _imageFileName;
  String? _errorMessage;
  ClassificationExecutionResult? _lastResult;

  ScannerProvider({
    ImageProcessingService? imageProcessingService,
    HybridAIClassificationService? aiClassificationService,
  })  : _imageProcessingService = imageProcessingService ?? ImageProcessingService(),
        _aiClassificationService = aiClassificationService ?? HybridAIClassificationService();

  ScanStep get currentStep => _currentStep;
  Uint8List? get rawImageBytes => _rawImageBytes;
  Uint8List? get processedImageBytes => _processedImageBytes;
  PreprocessingResult? get preprocessingResult => _preprocessingResult;
  String? get imageFileName => _imageFileName;
  String? get errorMessage => _errorMessage;
  ClassificationExecutionResult? get lastResult => _lastResult;
  WastePassportModel? get generatedPassport => _lastResult?.passport;

  bool get isProcessing =>
      _currentStep == ScanStep.capturing ||
      _currentStep == ScanStep.preprocessing ||
      _currentStep == ScanStep.classifying;

  bool get isMockModeActive => AIConfig.isForceMockMode || !AIConfig.hasApiKey;
  bool get hasApiKey => AIConfig.hasApiKey;
  bool get isForceMockMode => AIConfig.isForceMockMode;
  bool get isLiveAIReady => AIConfig.hasApiKey && !AIConfig.isForceMockMode;

  String get aiEngineStatusLabel {
    if (isForceMockMode) return 'Offline Mode (Simulation Active)';
    if (!hasApiKey) return 'Live AI Vision (API Key Required)';
    return 'Live AI Classification (${AIConfig.modelDisplayName})';
  }

  /// Loads image from user selection and prepares for analysis
  void onImageSelected(Uint8List bytes, String fileName) {
    _rawImageBytes = bytes;
    _processedImageBytes = null;
    _preprocessingResult = null;
    _imageFileName = fileName;
    _currentStep = ScanStep.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Full pipeline: Validates -> Preprocesses (Compresses) -> AI Classifies -> Generates Passport
  Future<WastePassportModel?> processAndClassify() async {
    if (_rawImageBytes == null || _rawImageBytes!.isEmpty) {
      setError('Please select or capture an image of the waste item first.');
      return null;
    }

    try {
      // Step 1: Preprocessing & Compression (Module 2)
      _currentStep = ScanStep.preprocessing;
      _errorMessage = null;
      notifyListeners();

      _preprocessingResult = await _imageProcessingService.preprocessImage(
        rawBytes: _rawImageBytes!,
        maxDimension: 1024,
        quality: 80,
      );
      _processedImageBytes = _preprocessingResult!.processedBytes;

      // Step 2: AI Classification & Circularity Generation (Module 3)
      _currentStep = ScanStep.classifying;
      notifyListeners();

      // Explicitly prohibit silent offline simulation when running user classification
      _lastResult = await _aiClassificationService.classify(
        imageBytes: _processedImageBytes!,
        fileName: _imageFileName ?? 'waste_item.jpg',
        allowOfflineSimulation: false,
      );

      _currentStep = ScanStep.completed;
      notifyListeners();
      return _lastResult!.passport;
    } catch (e) {
      _lastResult = null;
      setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  /// Explicitly runs offline mock simulation for the current selected or captured image
  Future<WastePassportModel?> runOfflineSimulation() async {
    if (_rawImageBytes == null || _rawImageBytes!.isEmpty) {
      setError('Please select or capture an image of the waste item first.');
      return null;
    }

    try {
      _currentStep = ScanStep.classifying;
      _errorMessage = null;
      notifyListeners();

      final bytes = _processedImageBytes ?? _rawImageBytes!;
      final mockService = MockAIClassificationService();
      final passport = await mockService.classifyWasteImage(
        imageBytes: bytes,
        fileName: _imageFileName ?? 'waste_item.jpg',
      );

      _lastResult = ClassificationExecutionResult(
        passport: passport,
        providerUsed: mockService.providerName,
        isFallback: true,
        fallbackReason: 'User explicitly selected offline simulation mode.',
      );

      _currentStep = ScanStep.completed;
      notifyListeners();
      return passport;
    } catch (e) {
      setError(e.toString().replaceAll('Exception: ', ''));
      return null;
    }
  }

  void setError(String message) {
    _errorMessage = message;
    _currentStep = ScanStep.error;
    notifyListeners();
  }

  void clearImage() => reset();

  void reset() {
    _currentStep = ScanStep.idle;
    _rawImageBytes = null;
    _processedImageBytes = null;
    _preprocessingResult = null;
    _imageFileName = null;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();
  }
}
