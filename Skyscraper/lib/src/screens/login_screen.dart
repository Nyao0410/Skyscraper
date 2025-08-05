import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skyscraper/src/constants/sizes.dart';
import 'package:skyscraper/src/providers/auth/login_screen_controller.dart';
import 'package:skyscraper/src/widgets/common/loading_indicator.dart';

/// The login screen of the application.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates a [LoginScreen] widget.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// The state for the [LoginScreen] widget.
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _handleController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _handleController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Controllerのloginメソッドを呼び出す
    await ref
        .read(loginScreenControllerProvider.notifier)
        .login(_handleController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    // ログイン処理の状態を監視する
    ref.listen<AsyncValue<void>>(loginScreenControllerProvider, (_, state) {
      state.when(
        error: (error, stackTrace) {
          // エラーが発生したらSnackBarで通知
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
        loading: () {
          // ローディング中は特に何もしない（UI側でインジケータ表示）
        },
        data: (_) {
          // 成功したらホーム画面へ遷移
          context.go('/home');
        },
      );
    });
    
    // ローディング状態か否かを取得
    final loginState = ref.watch(loginScreenControllerProvider);
    final isLoading = loginState is AsyncLoading<void>;

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(p16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _handleController,
              decoration: const InputDecoration(
                labelText: 'Handle (e.g., yourname.bsky.social)',
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: p16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
              enabled: !isLoading,
            ),
            const SizedBox(height: p32),
            if (isLoading)
              const LoadingIndicator()
            else
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
          ],
        ),
      ),
    );
  }
}
