import '../domain/entities/Media.dart';
import '../domain/repositories/Media_Repository.dart';
import 'dtos/upload_media_dto.dart';

/// Use case frontend: sube bytes al storage, crea entidad Media local y la persiste.
class UploadMediaUseCase {
  final MediaRepository mediaRepository;

  UploadMediaUseCase({
    required this.mediaRepository,
  });

  /// Devuelve la entidad `Media` creada por el backend.
  Future<Media> run(UploadMediaDTO dto) async {
    // Upload multipart to backend and obtain created Media metadata
    final media = await mediaRepository.uploadFromBytes(dto.fileBytes, dto.fileName, dto.mimeType);
    return media;
  }
}