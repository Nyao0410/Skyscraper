import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyscraper/providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handleController = TextEditingController();
    final passwordController = TextEditingController();

    ref.listen<AsyncValue>(
      authProvider,
      (_, state) {
        if (state is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.error}'),
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: handleController,
              decoration: const InputDecoration(
                labelText: 'Handle (e.g., example.bsky.social)',
              ),
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'App Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (handleController.text.isEmpty || passwordController.text.isEmpty) {
                  return;
                }
                ref.read(authProvider.notifier).login(
                      handleController.text,
                      passwordController.text,
                    );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}