import 'package:skyscraper/src/repositories/auth_repository.dart';

class FakeAuthRepository implements IAuthRepository {
  @override
  Future<void> login(String handle, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (handle == 'test' && password == 'password') {
      return;
    } else {
      throw Exception('Invalid credentials');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return;
  }

  @override
  Future<bool> isLoggedIn() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return false;
  }
}
