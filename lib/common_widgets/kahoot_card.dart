import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../features/kahoot/domain/entities/kahoot.dart';

class KahootCard extends StatelessWidget{
  final Kahoot kahoot;
  final VoidCallback onTap;

  KahootCard({required this.kahoot, required this.onTap});

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
            Container(
              height: base * 0.18, 
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(base * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kahoot.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: base * 0.04,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    '${kahoot.authorId} • ${kahoot.themes.length} preguntas',
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
