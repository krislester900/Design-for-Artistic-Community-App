import 'package:flutter/material.dart';

class CollaborationsPage extends StatelessWidget {
  const CollaborationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Collaborations',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: const Center(
        child: Text(
          'Page en construction',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
