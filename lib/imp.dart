import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Model Viewer')),
        body: const ModelViewer(
          backgroundColor: Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
          src: 'assets/chair.glb',
          ar: true,
          autoRotate: true,
          disableZoom: true,
        ),
      ),
    );
  }
}


