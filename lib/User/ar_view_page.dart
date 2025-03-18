import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ARViewPage extends StatelessWidget {
  final String glbUrl;

  const ARViewPage({super.key, required this.glbUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View in AR',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade900, Colors.purple.shade700],
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: ModelViewer(
        backgroundColor: const Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
        src: glbUrl,
        ar: true,
        autoRotate: true,
        disableZoom: true,
      ),
    );
  }
}