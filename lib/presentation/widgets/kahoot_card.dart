import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../domain/entities/kahoot.dart';

class KahootCard extends StatelessWidget{
  final Kahoot kahoot;
  final VoidCallback onTap;

  KahootCard({required this.kahoot, required this.onTap});

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)]),
        child: Column(children:[
          Container(height: 100, decoration: BoxDecoration(color:Colors.grey, borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kahoot.title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${kahoot.authorId} • ${kahoot.themes.length} preguntas', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],),
      ),
    );
  }
}