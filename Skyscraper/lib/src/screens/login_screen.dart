import 'package:flutter/material.dart';

/// The login screen of the application.
class LoginScreen extends StatelessWidget {
  /// Creates a [LoginScreen] widget.
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(
        child: Text('Login Screen'),
      ),
    );
  }
}
