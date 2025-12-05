import 'dart:typed_data';

class UploadMediaDTO {
  final Uint8List fileBytes;
  final String fileName;
  final String mimeType;
  final int sizeInBytes;

  UploadMediaDTO({
    required this.fileBytes,
    required this.fileName,
    required this.mimeType,
    required this.sizeInBytes,
  });
}