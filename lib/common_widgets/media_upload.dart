import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MediaUpload extends StatelessWidget{
  final Function(XFile) onMediaSelected;

  const MediaUpload({super.key, required this.onMediaSelected});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final base = screenWidth;
    return GestureDetector(
      onTap: () async{
        final picker = ImagePicker();
        final file = await picker.pickImage(source: ImageSource.gallery);
        if(file != null) onMediaSelected(file);
      },
      child: Container(
        height: base * 0.20, 
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey)
        ),
        child: Center(
          child: Icon(
            Icons.image,
            size: base * 0.08,
          ),
        ),
      ),
    );
  }
}
