import '../entities/Media.dart';

abstract class MediaRepository {
  Future<void> save(Media media);
  Future<Media?> findById(String id);
  Future<void> delete(String id);
}