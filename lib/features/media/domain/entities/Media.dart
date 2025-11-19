class Media {
  final String mediaId;
  final String path;
  final String mimeType;
  final int size; //en bytes
  final String originalName;
  final DateTime createdAt;

  Media({
    required this.mediaId,
    required this.path,
    required this.mimeType,
    required this.size,
    required this.originalName,
    required this.createdAt,
  });

  factory Media.fromJson(Map<String, dynamic> json){
    return Media(
      mediaId: json['mediaId'],
      path: json['path'],
      mimeType: json['mimeType'],
      size: json['size'],
      originalName: json['originalName'],
      createdAt: DateTime.parse(json['createdAt']), 
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'mediaId': mediaId,
      'path': path,
      'mimeType': mimeType,
      'size': size,
      'originalName': originalName,
      'createdAt': createdAt,
    };
  }

}