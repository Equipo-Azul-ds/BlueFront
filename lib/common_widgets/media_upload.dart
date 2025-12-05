import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MediaUpload extends StatelessWidget{
  final Function(XFile) onMediaSelected;
  final Uint8List? previewBytes;
  final String? previewUrl;

  const MediaUpload({super.key, required this.onMediaSelected, this.previewBytes, this.previewUrl});

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
        clipBehavior: Clip.hardEdge,
        child: previewBytes != null
          ? Image.memory(previewBytes!, fit: BoxFit.cover, width: double.infinity)
          : (previewUrl != null && previewUrl!.startsWith('http')
              ? Image.network(previewUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.broken_image)))
              : Center(child: Icon(Icons.image, size: base * 0.08))),
      ),
    );
  }
}
