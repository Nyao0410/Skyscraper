// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_screen_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

/// A Riverpod controller for managing the login screen's state and logic.
@ProviderFor(LoginScreenController)
const loginScreenControllerProvider = LoginScreenControllerProvider._();

/// A Riverpod controller for managing the login screen's state and logic.
final class LoginScreenControllerProvider
    extends $AsyncNotifierProvider<LoginScreenController, void> {
  /// A Riverpod controller for managing the login screen's state and logic.
  const LoginScreenControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginScreenControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginScreenControllerHash();

  @$internal
  @override
  LoginScreenController create() => LoginScreenController();
}

String _$loginScreenControllerHash() =>
    r'323e058919fd5b0093cb8052cd3c77f5bdf644c9';

abstract class _$LoginScreenController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
