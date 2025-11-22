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
    final id = json['id'] ?? json['mediaId'];
    return Media(
      id: id,
      path: json['path'],
      mimeType: json['mimeType'],
      size: json['size'],
      originalName: json['originalName'],
      createdAt: DateTime.parse(json['createdAt']),
      previewPath: json['previewPath'],
      ownerId: json['ownerId'],
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