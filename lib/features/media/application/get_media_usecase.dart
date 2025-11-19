import 'dart:typed_data';

import '../domain/entities/Media.dart';
import '../domain/repositories/Media_Repository.dart';
import '../domain/repositories/Storage_Provider_Repository.dart';

class GetMediaResponse {
  final Media media;
  final Uint8List? file; // null si no se encontró el binario

  GetMediaResponse({
    required this.media,
    required this.file,
  });
}

class GetMediaUseCase {
  final MediaRepository mediaRepository;
  final StorageProviderRepository storageProvider;

  GetMediaUseCase({
    required this.mediaRepository,
    required this.storageProvider,
  });

  /// Recupera metadatos y binario del storage.
  /// Lanza si la entidad no existe; retorna `file` como `null` si storage no tiene los bytes.
  Future<GetMediaResponse> run(String id) async {
    // 1) Buscar metadatos
    final media = await mediaRepository.findById(id);
    if (media == null) {
      throw Exception('Media with id <$id> not found');
    }

    // 2) Obtener binario desde storage usando el path
    final fileBytes = await storageProvider.get(media.path);

    return GetMediaResponse(media: media, file: fileBytes);
  }
}