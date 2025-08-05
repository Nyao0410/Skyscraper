import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:skyscraper/src/repositories/auth_repository.dart';

part 'login_screen_controller.g.dart';

/// A Riverpod controller for managing the login screen's state and logic.
@riverpod
class LoginScreenController extends _$LoginScreenController {
  @override
  FutureOr<void> build() {
    // Nothing to do at the moment this provider is built.
  }

  /// Handles the login process.
  ///
  /// Sets the state to loading, calls the authentication repository,
  /// and updates the state based on the login result.
  Future<void> login(String handle, String password) async {
    state = const AsyncValue.loading();
    
    final authRepository = ref.read(authRepositoryProvider);
    
    state = await AsyncValue.guard(
      () => authRepository.login(handle, password),
    );
  }
}
