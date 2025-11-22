import 'package:flutter/material.dart';
import '../../domain/entities/Media.dart';

/// Simple widget to show thumbnails/previews for a list of Media.
/// It expects either `previewPath` or `path` to be an accessible URL.
/// If your backend returns presigned URLs via an endpoint, call that first
/// and pass the resulting URLs in the `urls` map.
class MediaListPreview extends StatelessWidget {
  final List<Media> medias;
  final void Function(Media) onTap;
  final Map<String, String>? presignedUrls; // optional map media.id -> url

  const MediaListPreview({Key? key, required this.medias, required this.onTap, this.presignedUrls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: medias.map((m) {
        final url = presignedUrls != null && presignedUrls!.containsKey(m.id)
            ? presignedUrls![m.id]
            : (m.previewPath ?? m.path);

        return GestureDetector(
          onTap: () => onTap(m),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: url != null
                  ? DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: url == null
                ? Center(
                    child: Text(
                      m.originalName,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
