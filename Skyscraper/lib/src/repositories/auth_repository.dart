import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:skyscraper/src/repositories/fakes/fake_auth_repository.dart';
part 'auth_repository.g.dart';

/// Abstract class for authentication repository.
abstract class IAuthRepository {
  /// Logs in a user with the given handle and password.
  Future<void> login(String handle, String password);

  /// Logs out the current user.
  Future<void> logout();

  /// Checks if a user is currently logged in.
  Future<bool> isLoggedIn();
}

/// Provides the authentication repository instance.
@Riverpod(keepAlive: true)
IAuthRepository authRepository(Ref ref) {
  return FakeAuthRepository();
}
