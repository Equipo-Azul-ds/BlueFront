import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../domain/entities/kahoot.dart';

class KahootCard extends StatelessWidget{
  final Kahoot kahoot;
  final VoidCallback onTap;

  KahootCard({required this.kahoot, required this.onTap});

  @override
  Widget build(BuildContext context){
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)]),
            child: Column(children:[
              Container(
                height: constraints.maxWidth * 0.25, // Responsive height based on width
                decoration: BoxDecoration(color:Colors.grey, borderRadius: BorderRadius.vertical(top: Radius.circular(16)))
              ),
              Padding(
                padding: EdgeInsets.all(constraints.maxWidth * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kahoot.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: constraints.maxWidth * 0.04
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: constraints.maxHeight * 0.005),
                    Text(
                      '${kahoot.authorId} • ${kahoot.themes.length} preguntas',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: constraints.maxWidth * 0.03
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],),
          ),
        );
      },
    );
  }
}
