import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MediaUpload extends StatelessWidget{
  final Function(XFile) onMediaSelected;

  MediaUpload({required this.onMediaSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async{
        final picker = ImagePicker();
        final file = await picker.pickImage(source: ImageSource.gallery);
        if(file !=null) onMediaSelected(file);
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(color: Colors.grey[200],borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
        child: Center(child: Icon(Icons.image)),
      ),
    );
  }
}