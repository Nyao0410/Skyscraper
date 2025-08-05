import 'package:flutter/material.dart';

/// The profile screen of the application.
class ProfileScreen extends StatelessWidget {
  /// Creates a [ProfileScreen] widget.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Screen')),
    );
  }
}