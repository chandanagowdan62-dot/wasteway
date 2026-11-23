import 'dart:typed_data';

/// Abstract contract for image storage in WasteWay
abstract class ICloudStorageService {
  bool get isCloudConnected;

  /// Uploads binary image data and returns the accessible download URL or data URI
  Future<String?> uploadImage(Uint8List imageBytes, String destinationPath);

  /// Deletes an image from storage
  Future<void> deleteImage(String storageUrlOrPath);
}
