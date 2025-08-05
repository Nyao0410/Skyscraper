import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:skyscraper/src/repositories/fakes/fake_auth_repository.dart';
part 'auth_repository.g.dart';

abstract class IAuthRepository {
  Future<void> login(String handle, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
}

@Riverpod(keepAlive: true)
IAuthRepository authRepository(Ref ref) {
  return FakeAuthRepository();
}
