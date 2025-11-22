import 'dart:typed_data';

import '../entities/Media.dart';

abstract class MediaRepository {
  /// Uploads a file (multipart) to the backend and returns the created Media metadata.
  Future<Media> uploadFromBytes(Uint8List fileBytes, String fileName, String mimeType);

  /// Persist metadata-only object if needed (kept for compatibility).
  Future<Media> save(Media media);

  Future<Media?> findById(String id);
  Future<void> delete(String id);
}