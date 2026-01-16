class Media {
  final String id;
  final String path;
  final String mimeType;
  final int size; //en bytes
  final String originalName;
  final DateTime createdAt;
  final String? previewPath;
  final String? ownerId;

  Media({
    required this.id,
    required this.path,
    required this.mimeType,
    required this.size,
    required this.originalName,
    required this.createdAt,
    this.previewPath,
    this.ownerId,
  });

  factory Media.fromJson(Map<String, dynamic> json){
    // El backend puede devolver 'id' o 'mediaId' según la implementación.
    // Usamos claves alternativas y conversiones seguras a String para evitar
    // errores por valores nulos o por tipos distintos a String.
    String? _safeStringOrNull(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      try {
        return v.toString();
      } catch (_) {
        return null;
      }
    }

    // Modificación para soportar 'assetId' (camelCase) como muestra la respuesta real,
    // además de 'asset_id' y 'id'.
    final id = _safeStringOrNull(json['assetId'] ?? json['asset_id'] ?? json['id'] ?? json['mediaId']) ?? '';
    final path = _safeStringOrNull(json['path'] ?? json['url'] ?? json['pathUrl'] ?? json['secure_url']) ?? '';
    final mimeType = _safeStringOrNull(json['mimeType'] ?? json['contentType']) ?? '';
    final size = (json['size'] ?? json['fileSize'] ?? 0);
    final originalName = _safeStringOrNull(json['originalName'] ?? json['name']) ?? '';
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String());
    } catch (_) {
      createdAt = DateTime.now();
    }

    return Media(
      id: id,
      path: path,
      mimeType: mimeType,
      size: size is int ? size : int.tryParse(size.toString()) ?? 0,
      originalName: originalName,
      createdAt: createdAt,
      previewPath: _safeStringOrNull(json['previewPath'] ?? json['thumbnail']),
      ownerId: _safeStringOrNull(json['ownerId'] ?? json['owner_id']),
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'path': path,
      'mimeType': mimeType,
      'size': size,
      'originalName': originalName,
      'createdAt': createdAt.toIso8601String(),
      'previewPath': previewPath,
      'ownerId': ownerId,
    };
  }

}