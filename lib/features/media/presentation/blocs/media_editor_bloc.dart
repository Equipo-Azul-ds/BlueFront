import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/dtos/upload_media_dto.dart';
import '../../application/upload_media_usecase.dart';
import '../../application/get_media_usecase.dart';
import '../../application/delete_media_usecase.dart';
import '../../infrastructure/repositories/Media_Repository_Impl.dart';
import '../../infrastructure/repositories/Storage_Provider_Repository_Impl.dart';

/// Bloc responsable de operaciones de media (upload / get / delete).
/// Inyecta las implementaciones de repositorios (o sus interfaces).
class MediaEditorBloc extends ChangeNotifier {
  final UploadMediaUseCase uploadUseCase;
  final GetMediaUseCase getUseCase;
  final DeleteMediaUseCase deleteUseCase;

  bool isLoading = false;
  String? errorMessage;

  // Última media obtenida/creada (puedes exponer lista si necesitas más)
  dynamic lastMedia; 
  Uint8List? lastFileBytes;

  MediaEditorBloc({
    required this.uploadUseCase,
    required this.getUseCase,
    required this.deleteUseCase,
  });

  // Sube un archivo dado como UploadMediaDTO
  Future<dynamic> upload(UploadMediaDTO dto) async {
    _startLoading();
    try {
      final media = await uploadUseCase.run(dto);
      lastMedia = media;
      errorMessage = null;
      return media;
    } catch (e) {
      errorMessage = 'Error al subir media: $e';
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  // Helper: subir directamente desde un XFile (image_picker)
  Future<dynamic> uploadFromXFile(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    final dto = UploadMediaDTO(
      fileBytes: bytes,
      fileName: xfile.name,
      mimeType: _detectMimeType(xfile.path),
      sizeInBytes: bytes.length,
    );
    return await upload(dto);
  }

  // Obtener metadatos + bytes
  Future<GetMediaResponse> getMedia(String id) async {
    _startLoading();
    try {
      final response = await getUseCase.run(id);
      lastMedia = response.media;
      lastFileBytes = response.file;
      errorMessage = null;
      return response;
    } catch (e) {
      errorMessage = 'Error al obtener media: $e';
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  // Borrar media
  Future<void> deleteMedia(String id) async {
    _startLoading();
    try {
      await deleteUseCase.run(id);
      // limpiar si era el último
      if (lastMedia != null) {
        final mediaId = (lastMedia as dynamic).mediaId ?? (lastMedia as dynamic).id ?? null;
        if (mediaId == id) {
          lastMedia = null;
          lastFileBytes = null;
        }
      }
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Error al eliminar media: $e';
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  // Helpers privados
  void _startLoading() {
    isLoading = true;
    notifyListeners();
  }

  void _stopLoading() {
    isLoading = false;
    notifyListeners();
  }

  String _detectMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    // default
    return 'application/octet-stream';
  }
}