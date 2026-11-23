import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'i_cloud_storage_service.dart';

/// Local offline storage fallback service using Data URIs / Base64 encoding
class MockCloudStorageService implements ICloudStorageService {
  @override
  bool get isCloudConnected => false;

  @override
  Future<String?> uploadImage(Uint8List imageBytes, String destinationPath) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final base64String = base64Encode(imageBytes);
    // Returns accessible data URI
    final dataUri = 'data:image/jpeg;base64,$base64String';
    debugPrint('[MockCloudStorageService] Mock image stored for $destinationPath (${imageBytes.length} bytes)');
    return dataUri;
  }

  @override
  Future<void> deleteImage(String storageUrlOrPath) async {
    debugPrint('[MockCloudStorageService] Mock delete requested for $storageUrlOrPath');
  }
}
