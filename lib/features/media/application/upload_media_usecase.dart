import 'dart:math';
import 'dart:typed_data';

import '../domain/entities/Media.dart';
import '../domain/repositories/Media_Repository.dart';
import '../domain/repositories/Storage_Provider_Repository.dart';
import 'dtos/upload_media_dto.dart';

/// Use case frontend: sube bytes al storage, crea entidad Media local y la persiste.
class UploadMediaUseCase {
  final MediaRepository mediaRepository;
  final StorageProviderRepository storageProvider;

  UploadMediaUseCase({
    required this.mediaRepository,
    required this.storageProvider,
  });

  /// Devuelve la entidad `Media` construida en el cliente (contiene id generado localmente).
  Future<Media> run(UploadMediaDTO dto) async {
    // 1) Subir bytes al storage
    final storagePath = await storageProvider.upload(dto.fileBytes, dto.fileName, dto.mimeType);

    // 2) Generar un id cliente
    final generatedId = _generateId();

    // 3) Construir la entidad Media local
    final media = Media(
      mediaId: generatedId,
      path: storagePath,
      mimeType: dto.mimeType,
      size: dto.sizeInBytes,
      originalName: dto.fileName,
      createdAt: DateTime.now().toUtc(),
    );

    // 4) Persistir metadatos mediante repository (backend)
    await mediaRepository.save(media);

    // 5) Devolver la entidad construida
    return media;
  }

  String _generateId() {
    final rnd = Random();
    return '${DateTime.now().microsecondsSinceEpoch}${rnd.nextInt(1 << 32)}';
  }
}