import 'package:flutter/material.dart';
import '../../domain/entities/Media.dart';

/// Widget sencillo para mostrar miniaturas/previsualizaciones de una lista de Media.
/// Espera que `previewPath` o `path` sean URLs accesibles.
/// Si tu backend devuelve URLs firmadas mediante un endpoint, obtén esas URLs primero
/// y pásalas en el mapa `presignedUrls`.
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
