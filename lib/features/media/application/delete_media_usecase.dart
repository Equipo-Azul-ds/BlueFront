import '../domain/repositories/Media_Repository.dart';
import '../domain/repositories/Storage_Provider_Repository.dart';

class DeleteMediaUseCase {
  final MediaRepository mediaRepository;
  final StorageProviderRepository storageProvider;

  DeleteMediaUseCase({
    required this.mediaRepository,
    required this.storageProvider,
  });

  /// Elimina el archivo en storage y luego borra metadata en el repo.
  /// Idempotente: si la entidad no existe, retorna sin error.
  Future<void> run(String id) async {
    final media = await mediaRepository.findById(id);
    if (media == null) {
      // idempotencia: si no existe, no hacemos nada
      return;
    }

    // 1) Borrar archivo físico en storage (si existe)
    await storageProvider.delete(media.path);

    // 2) Borrar registro en repo/backend
    await mediaRepository.delete(id);
  }
}