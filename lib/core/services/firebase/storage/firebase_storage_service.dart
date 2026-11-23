import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'i_cloud_storage_service.dart';

/// Live Firebase Cloud Storage service implementation
class FirebaseCloudStorageService implements ICloudStorageService {
  final FirebaseStorage _storage;

  FirebaseCloudStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  bool get isCloudConnected => true;

  @override
  Future<String?> uploadImage(Uint8List imageBytes, String destinationPath) async {
    try {
      final ref = _storage.ref().child(destinationPath);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': 'WasteWay App'},
      );

      final uploadTask = await ref.putData(imageBytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('[FirebaseCloudStorageService] Uploaded image to: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[FirebaseCloudStorageService] Image upload failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteImage(String storageUrlOrPath) async {
    try {
      if (storageUrlOrPath.startsWith('http')) {
        await _storage.refFromURL(storageUrlOrPath).delete();
      } else {
        await _storage.ref().child(storageUrlOrPath).delete();
      }
    } catch (e) {
      debugPrint('[FirebaseCloudStorageService] Image delete failed: $e');
    }
  }
}
