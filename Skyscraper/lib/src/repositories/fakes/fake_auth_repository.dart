import 'dart:developer'; // developerライブラリをインポート
import 'package:skyscraper/src/repositories/auth_repository.dart';

/// A fake implementation of [IAuthRepository] for testing and development.
class FakeAuthRepository implements IAuthRepository {
  @override
  Future<void> login(String handle, String password) async {
    // --- ここから追加 ---
    log('--- DEBUG: FakeAuthRepository.login ---');
    log('Received Handle: $handle');
    log('Received Password: "$password"'); // 受け取ったパスワードを""で囲んで明確に表示
    log('Condition (password == "password"): ${password == "password"}');
    log('------------------------------------');
    // --- ここまで追加 ---

    await Future<void>.delayed(const Duration(seconds: 1));
    if (password == 'password') {
      return; // 成功
    }
    throw Exception('Invalid password');
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return;
  }

  @override
  Future<bool> isLoggedIn() async {
    await Future<bool>.delayed(const Duration(milliseconds: 100));
    return false;
  }
}