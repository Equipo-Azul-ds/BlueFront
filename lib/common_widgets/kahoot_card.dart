import 'dart:typed_data';
import 'package:flutter/material.dart';
// colors import removed; card uses default colors to preserve visual layout
import '../features/kahoot/domain/entities/Quiz.dart';

class KahootCard extends StatelessWidget{
  final Quiz kahoot;
  final VoidCallback onTap;
  final Uint8List? coverBytes;
  final String? coverUrlOverride;
  final bool isLocalCopy;

  KahootCard({required this.kahoot, required this.onTap, this.coverBytes, this.coverUrlOverride, this.isLocalCopy = false});

  @override
  Widget build(BuildContext context){
    final screenWidth = MediaQuery.of(context).size.width;
    final base = screenWidth;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
        ),
        child: Column(
          children:[
            // Cover image (if available) or placeholder
            Container(
              height: base * 0.18,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.hardEdge,
              child: coverBytes != null
                ? Image.memory(
                    coverBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, color: Colors.grey[600]),
                    ),
                  )
                : (coverUrlOverride != null && coverUrlOverride!.startsWith('http')
                    ? Image.network(
                        coverUrlOverride!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.broken_image, color: Colors.grey[600]),
                        ),
                      )
                    : (kahoot.coverImageUrl != null && kahoot.coverImageUrl!.startsWith('http')
                        ? Image.network(
                            kahoot.coverImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.broken_image, color: Colors.grey[600]),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: Center(child: Icon(Icons.image, color: Colors.grey[600])),
                          ))),
            ),
            Padding(
              padding: EdgeInsets.all(base * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          kahoot.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: base * 0.04,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLocalCopy && kahoot.title.contains('(copia)')) ...[
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Copia', style: TextStyle(color: Colors.orange.shade800, fontSize: base * 0.025, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '${kahoot.authorId} • ${kahoot.questions.length} preguntas',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: base * 0.03,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
