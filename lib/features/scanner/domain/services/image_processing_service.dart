import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Holds metadata and processed byte payload resulting from preprocessing
class PreprocessingResult {
  final Uint8List processedBytes;
  final int originalSizeBytes;
  final int processedSizeBytes;
  final int width;
  final int height;

  const PreprocessingResult({
    required this.processedBytes,
    required this.originalSizeBytes,
    required this.processedSizeBytes,
    required this.width,
    required this.height,
  });

  double get compressionRatioPercent {
    if (originalSizeBytes == 0) return 0.0;
    return ((originalSizeBytes - processedSizeBytes) / originalSizeBytes) * 100.0;
  }

  String get originalSizeFormatted => '${(originalSizeBytes / 1024).toStringAsFixed(1)} KB';
  String get processedSizeFormatted => '${(processedSizeBytes / 1024).toStringAsFixed(1)} KB';
}

/// Cross-platform image validation, resizing and compression service
class ImageProcessingService {
  static const int defaultMaxDimension = 1024;
  static const int defaultJpegQuality = 80;
  static const int maxInputSizeBytes = 25 * 1024 * 1024; // 25 MB limit

  /// Preprocesses image bytes: validates, downscales if larger than maxDimension,
  /// and applies quality compression to optimize network transmission.
  Future<PreprocessingResult> preprocessImage({
    required Uint8List rawBytes,
    int maxDimension = defaultMaxDimension,
    int quality = defaultJpegQuality,
  }) async {
    if (rawBytes.isEmpty) {
      throw ArgumentError('Input image bytes cannot be empty.');
    }

    if (rawBytes.lengthInBytes > maxInputSizeBytes) {
      throw ArgumentError(
        'Image file size (${(rawBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1)}MB) exceeds maximum allowed limit of 25MB.',
      );
    }

    // Run compute in a separate isolate on native platforms to prevent UI frame drops
    return await compute(
      _runImageOptimization,
      _OptimizationParams(
        bytes: rawBytes,
        maxDimension: maxDimension,
        quality: quality,
      ),
    );
  }
}

class _OptimizationParams {
  final Uint8List bytes;
  final int maxDimension;
  final int quality;

  _OptimizationParams({
    required this.bytes,
    required this.maxDimension,
    required this.quality,
  });
}

PreprocessingResult _runImageOptimization(_OptimizationParams params) {
  // Decode image from raw memory bytes
  final decodedImage = img.decodeImage(params.bytes);
  if (decodedImage == null) {
    throw Exception(
      'Failed to decode image. Unsupported or corrupted format. Please ensure the file is a valid JPEG, PNG, or WebP image.',
    );
  }

  // Normalize EXIF camera orientation to ensure image is upright for AI vision
  img.Image workingImage = img.bakeOrientation(decodedImage);

  // Check if image requires dimensional downscaling
  if (workingImage.width > params.maxDimension || workingImage.height > params.maxDimension) {
    if (workingImage.width >= workingImage.height) {
      workingImage = img.copyResize(
        workingImage,
        width: params.maxDimension,
        interpolation: img.Interpolation.linear,
      );
    } else {
      workingImage = img.copyResize(
        workingImage,
        height: params.maxDimension,
        interpolation: img.Interpolation.linear,
      );
    }
  }

  // Encode optimized image to standard JPEG format
  final optimizedJpegBytes = Uint8List.fromList(
    img.encodeJpg(workingImage, quality: params.quality),
  );

  return PreprocessingResult(
    processedBytes: optimizedJpegBytes,
    originalSizeBytes: params.bytes.lengthInBytes,
    processedSizeBytes: optimizedJpegBytes.lengthInBytes,
    width: workingImage.width,
    height: workingImage.height,
  );
}
