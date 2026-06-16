import 'package:flutter/material.dart';

class UniversePage extends StatelessWidget {
  final String slug;
  const UniversePage({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Univers')),
      body: Center(
        child: Text('Univers: $slug', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
    );
  }
}