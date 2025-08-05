import 'package:flutter/material.dart';

/// The notifications screen of the application.
class NotificationsScreen extends StatelessWidget {
  /// Creates a [NotificationsScreen] widget.
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Notifications Screen')),
    );
  }
}
