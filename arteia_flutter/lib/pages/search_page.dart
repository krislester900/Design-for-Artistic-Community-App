import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Rechercher', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
    );
  }
}