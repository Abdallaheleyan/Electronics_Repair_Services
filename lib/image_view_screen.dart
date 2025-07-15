import 'package:flutter/material.dart';

class ImageViewScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewScreen({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract just the file name from the URL

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Uri.decodeFull(imageUrl).split('/').last.split('?').first,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF39ef64),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
