import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class FullImageViewerScreen extends StatelessWidget {
  final String imagePath;

  const FullImageViewerScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Encrypted Document', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Center(
        child: FutureBuilder<Uint8List?>(
          future: StorageService.instance.getImageBytes(imagePath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(color: VaultTheme.primary);
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_rounded, size: 64, color: Colors.white38),
                  SizedBox(height: 12),
                  Text('Failed to load image', style: TextStyle(color: Colors.white70)),
                ],
              );
            }
            return InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}
