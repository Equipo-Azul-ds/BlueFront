import 'dart:typed_data';

import '../entities/Media.dart';

abstract class MediaRepository {
  /// Sube un archivo (multipart) al backend y devuelve los metadatos del objeto Media creado.
  Future<Media> uploadFromBytes(Uint8List fileBytes, String fileName, String mimeType);

  /// Persiste un objeto solo con metadatos si es necesario (mantenido por compatibilidad).
  Future<Media> save(Media media);

  Future<Media?> findById(String id);
  Future<void> delete(String id);
}