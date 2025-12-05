import 'dart:typed_data';

abstract class StorageProviderRepository {
  Future<String> upload(Uint8List fileBytes, String fileName, String mimeType);
  Future<Uint8List?> get(String path);
  Future<void> delete(String path);
}