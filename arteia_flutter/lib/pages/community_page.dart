import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Communauté', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
    );
  }
}