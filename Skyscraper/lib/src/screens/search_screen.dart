import 'package:flutter/material.dart';

/// The search screen of the application.
class SearchScreen extends StatelessWidget {
  /// Creates a [SearchScreen] widget.
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: const Center(child: Text('Search Screen')),
    );
  }
}
