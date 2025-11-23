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
    // Backend may return 'id' or 'mediaId' depending on implementation.
    // Use safe fallbacks and convert to string to avoid runtime Null type errors.
    String? _safeStringOrNull(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      try {
        return v.toString();
      } catch (_) {
        return null;
      }
    }

    final id = _safeStringOrNull(json['id'] ?? json['mediaId']) ?? '';
    final path = _safeStringOrNull(json['path'] ?? json['url'] ?? json['pathUrl']) ?? '';
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